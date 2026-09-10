#!/usr/bin/env bash
# ==============================================================================
# Script de Sincronização Multinuvem (OneDrive -> Local | Google Drive -> Local)
# Usando Rclone Sync com Mapeamento Específico de Pastas
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
mkdir -p "$GDRIVE_LOCAL/Drª. Zuely/Documentos"
mkdir -p "/home/eduardo/Fax"
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

STATUS_ODRIVE=0
STATUS_GDRIVE=0

# ------------------------------------------------------------------------------
# ETAPA 1: SINCRONIZAÇÃO DO ONEDRIVE (Odrive: -> Pastas Locais Especificadas)
# ------------------------------------------------------------------------------
echo -e "\n=== [FASE 1/2] Sincronizando OneDrive para as pastas locais ===" | tee -a "$LOG_FILE"
notify-send "Sincronização OneDrive" "Iniciando sincronização do OneDrive às ${HORA_INICIO} h" \
    -i "$ICON_PATH" 2>/dev/null || true

# Função genérica para mapeamentos diretos
sync_odrive_item() {
    local src="$1"
    local dest="$2"
    echo "-> Sincronizando OneDrive: $src -> $dest..."
    
    rclone sync "$ODRIVE_REMOTE/$src" "$dest" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s \
        2>&1 | tee -a "$LOG_FILE"
        
    return ${PIPESTATUS[0]}
}

# Mapeamentos do OneDrive conforme especificação
sync_odrive_item "Documentos" "$GDRIVE_LOCAL/Drª. Zuely/Documentos" || STATUS_ODRIVE=1
sync_odrive_item "Fax" "/home/eduardo/Fax" || STATUS_ODRIVE=1
sync_odrive_item "Imagens" "/home/eduardo/Imagens" || STATUS_ODRIVE=1
sync_odrive_item "Modelos" "/home/eduardo/Modelos" || STATUS_ODRIVE=1
sync_odrive_item "Músicas" "/home/eduardo/Músicas" || STATUS_ODRIVE=1
sync_odrive_item "Vídeos" "/home/eduardo/Vídeos" || STATUS_ODRIVE=1

HORA_FIM_ODRIVE=$(date '+%H:%M:%S')
if [ $STATUS_ODRIVE -eq 0 ]; then
    notify-send "Sincronização OneDrive" "OneDrive concluído com sucesso às ${HORA_FIM_ODRIVE} h" \
        -i "$ICON_PATH" 2>/dev/null || true
else
    notify-send "Sincronização OneDrive" "Falha durante a sincronização do OneDrive." \
        -i dialog-error 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# ETAPA 2: SINCRONIZAÇÃO DO GOOGLE DRIVE (Gdrive: -> /home/eduardo/Google Drive)
# ------------------------------------------------------------------------------
if [ $STATUS_ODRIVE -eq 0 ]; then
    echo -e "\n=== [FASE 2/2] Sincronizando Google Drive para /home/eduardo/Google Drive ===" | tee -a "$LOG_FILE"
    HORA_INICIO_GDRIVE=$(date '+%H:%M:%S')
    notify-send "Sincronização Google Drive" "Iniciando sincronização do Google Drive às ${HORA_INICIO_GDRIVE} h" \
        -i "$ICON_PATH" 2>/dev/null || true

    # A trava --exclude protege a subpasta Documentos que veio do OneDrive
    rclone sync "$GDRIVE_REMOTE" "$GDRIVE_LOCAL" \
        --exclude "Drª. Zuely/Documentos/**" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s \
        2>&1 | tee -a "$LOG_FILE" || STATUS_GDRIVE=1

    HORA_FIM_GDRIVE=$(date '+%H:%M:%S')
    if [ $STATUS_GDRIVE -eq 0 ]; then
        notify-send "Sincronização Google Drive" "Google Drive concluído com sucesso às ${HORA_FIM_GDRIVE} h" \
            -i "$ICON_PATH" 2>/dev/null || true
    else
        notify-send "Sincronização Google Drive" "Falha durante a sincronização do Google Drive." \
            -i dialog-error 2>/dev/null || true
    fi
else
    echo "Falha na etapa do OneDrive. Sincronização do Google Drive abortada." | tee -a "$LOG_FILE"
    STATUS_GDRIVE=1
fi

# ------------------------------------------------------------------------------
# REGISTRO EM LOG
# ------------------------------------------------------------------------------
if [ $STATUS_ODRIVE -eq 0 ] && [ $STATUS_GDRIVE -eq 0 ]; then
    echo -e "\nSincronização geral concluída com sucesso: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
else
    echo -e "\nErro na sincronização (OneDrive: $STATUS_ODRIVE, Gdrive: $STATUS_GDRIVE): $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
fi
