#!/usr/bin/env bash
# ==============================================================================
# Script de Sincronização Multinuvem (OneDrive -> Local | Google Drive -> Local)
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# TRAVA DE HORÁRIO DE INÍCIO DA OPERAÇÃO (10/09/2026 00:00:00)
# ------------------------------------------------------------------------------
DATA_INICIO_PERMITIDA="2026-09-10 00:00:00"
TIMESTAMP_LIBERACAO=$(date -d "$DATA_INICIO_PERMITIDA" +%s)
TIMESTAMP_ATUAL=$(date +%s)

if [ "$TIMESTAMP_ATUAL" -lt "$TIMESTAMP_LIBERACAO" ]; then
    echo "=================================================="
    echo "Aviso: A Sincronização agendada ainda não atingiu o horário liberado."
    echo "Liberado a partir de: $DATA_INICIO_PERMITIDA"
    echo "Data/Hora Atual:      $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=================================================="
    
    # Notificação gráfica e encerramento seguro
    notify-send "Sincronização de Nuvens" "Aguardando data de liberação ($DATA_INICIO_PERMITIDA)" \
        -i dialog-information 2>/dev/null || true
    exit 0
fi

# ------------------------------------------------------------------------------
# CONFIGURAÇÕES E VARIÁVEIS DE AMBIENTE
# ------------------------------------------------------------------------------
GDRIVE_REMOTE="Gdrive:"
ODRIVE_REMOTE="Odrive:"

GDRIVE_LOCAL="/home/eduardo/Google Drive"
LOG_DIR="/home/eduardo/.var/rclone"
LOG_FILE="$LOG_DIR/rclone.txt"
LOCK_FILE="/tmp/cloud_sync.lock"
ICON_PATH="/home/eduardo/.local/share/icons/ExposeAir/apps/scalable/unity-scope-gdrive.svg"

# Garantir diretórios locais
mkdir -p "$LOG_DIR"
mkdir -p "$GDRIVE_LOCAL"
mkdir -p "$GDRIVE_LOCAL/Drª Zuely"
mkdir -p "/home/eduardo/Imagens"
mkdir -p "/home/eduardo/Modelos"
mkdir -p "/home/eduardo/Músicas"
mkdir -p "/home/eduardo/Vídeos"

# ------------------------------------------------------------------------------
# TRATAMENTO DE TRAVA (LOCK FILE DE EXECUÇÃO)
# ------------------------------------------------------------------------------
rm -f "$LOCK_FILE"
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Rotação de Log simples (se tiver mais de 24 horas, limpa)
if [ -f "$LOG_FILE" ]; then
    find "$LOG_DIR" -name "rclone.txt" -mtime +1 -exec rm -f {} \;
fi

HORA_INICIO=$(date '+%H:%M:%S')
echo "==================================================" | tee -a "$LOG_FILE"
echo "Iniciando sincronização geral: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"

# Notificação de início
notify-send "Sincronização de Nuvens" "Sincronização iniciada às ${HORA_INICIO} h" \
    -i "$ICON_PATH" 2>/dev/null || true

STATUS_ODRIVE=0
STATUS_GDRIVE_DOWNLOAD=0

# ------------------------------------------------------------------------------
# ETAPA 1: DOWNLOAD DO ONEDRIVE (Odrive: -> Pastas Locais)
# ------------------------------------------------------------------------------
echo -e "\n=== [FASE 1/2] Sincronizando OneDrive para a máquina local ===" | tee -a "$LOG_FILE"

sync_odrive_folder() {
    local src_folder="$1"
    local dest_folder="$2"
    echo "-> Baixando do OneDrive: $src_folder..."
    
    rclone copy "$ODRIVE_REMOTE/$src_folder" "$dest_folder/$src_folder" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s \
        2>&1 | tee -a "$LOG_FILE"
        
    return ${PIPESTATUS[0]}
}

# Documentos -> Drª Zuely
echo "-> Baixando: Documentos (Drª Zuely)..."
rclone copy "$ODRIVE_REMOTE/Documentos" "$GDRIVE_LOCAL/Drª Zuely/Documentos" \
    -P --update --transfers 4 --checkers 8 --stats 1s 2>&1 | tee -a "$LOG_FILE" || STATUS_ODRIVE=1

# Pastas do OneDrive para /home/eduardo/Google Drive
sync_odrive_folder "Anexos" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Banco de Dados" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Contatos" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "E-mails" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Fax" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Livros" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Pdf" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Scripts" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1

# Pastas do OneDrive para a HOME
sync_odrive_folder "Imagens" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Modelos" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Músicas" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Vídeos" "/home/eduardo" || STATUS_ODRIVE=1

# ------------------------------------------------------------------------------
# ETAPA 2: DOWNLOAD DO GOOGLE DRIVE (Gdrive: -> /home/eduardo/Google Drive)
# ------------------------------------------------------------------------------
if [ $STATUS_ODRIVE -eq 0 ]; then
    echo -e "\n=== [FASE 2/2] Baixando arquivos do Google Drive para a pasta local ===" | tee -a "$LOG_FILE"

    rclone copy "$GDRIVE_REMOTE" "$GDRIVE_LOCAL" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s \
        2>&1 | tee -a "$LOG_FILE" || STATUS_GDRIVE_DOWNLOAD=1
else
    echo "Falha no download do OneDrive. Ignorando download do Google Drive." | tee -a "$LOG_FILE"
    STATUS_GDRIVE_DOWNLOAD=1
fi

# ------------------------------------------------------------------------------
# NOTIFICAÇÃO FINAL
# ------------------------------------------------------------------------------
HORA_FIM=$(date '+%H:%M:%S')

if [ $STATUS_ODRIVE -eq 0 ] && [ $STATUS_GDRIVE_DOWNLOAD -eq 0 ]; then
    echo -e "\nSincronização concluída com sucesso: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
    notify-send "Sincronização de Nuvens" "Sincronização finalizada com sucesso às ${HORA_FIM} h" \
        -i "$ICON_PATH" 2>/dev/null || true
else
    echo -e "\nErro durante a sincronização (OneDrive: $STATUS_ODRIVE, Gdrive Down: $STATUS_GDRIVE_DOWNLOAD): $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
    notify-send "Sincronização de Nuvens" "Falha na sincronização das nuvens." \
        -i dialog-error 2>/dev/null || true
fi
