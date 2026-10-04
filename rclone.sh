#!/usr/bin/env bash

# ==============================================================================
# Mapa do sincronismo - Duas contas, sendo Odrive e Gdrive
# ==============================================================================

# -1 2025-03-23 09:52:43      1085 Documentos --------------> /home/eduardo/'Google Drive'/'Drª. Zuely'
# -1 2025-04-13 17:22:10         2 Fax        --------------> /home/eduardo/Fax
# -1 2025-03-07 13:04:05        44 Imagens    --------------> /home/eduardo/Imagens
# -1 2025-04-13 17:22:10         5 Modelos    --------------> /home/eduardo/Modelos
# -1 2025-04-20 20:56:52        61 Músicas    --------------> /home/eduardo/Músicas
# -1 2025-03-07 13:05:03         6 Vídeos     --------------> /home/eduardo/Vídeos
          
# -1 2026-09-07 17:52:43        -1 Banco de Dados ----------|
# -1 2026-09-07 17:57:14        -1 Dr. Eduardo -------------|
# -1 2026-09-07 20:30:33        -1 Dr. Leandro -------------|
# -1 2026-08-17 12:54:28        -1 Dr. Luis Pedro ----------|
# -1 2026-09-09 12:45:37        -1 Drª. Michele ------------|
# -1 2026-09-09 12:45:28        -1 Drª. Zuely --------------|---> /home/eduardo/'Google Drive'
# -1 2026-08-18 12:27:50        -1 Fazenda -----------------|
# -1 2026-08-18 13:08:44        -1 Geórgia -----------------|
# -1 2026-08-18 13:31:07        -1 Petições ----------------|
# -1 2026-08-18 13:54:04        -1 Sítio -------------------|
# -1 2026-08-31 17:29:57        -1 WalletOfSatoshi_Backup --|

# /home/eduardo/'Google Drive' ----------------------------->      Gdrive:
# /home/eduardo/Bluetooth ---------------------------------->      Gdrive:
# /home/eduardo/Fax ----------------------------------------|
# /home/eduardo/Imagens ------------------------------------|
# /home/eduardo/Modelos ------------------------------------| ---> Odrive:
# /home/eduardo/Músicas ------------------------------------|
# /home/eduardo/Vídeos -------------------------------------|

# ==============================================================================
# Script de Sincronização Multinuvem (OneDrive <-> Local -> Google Drive Remote)
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
BLUETOOTH_LOCAL="/home/eduardo/Bluetooth"
LOG_DIR="/home/eduardo/.var/rclone"
LOG_FILE="$LOG_DIR/rclone.txt"
LOCK_FILE="/tmp/cloud_sync.lock"
ICON_PATH="/home/eduardo/.local/share/icons/ExposeAir/apps/scalable/unity-scope-gdrive.svg"

# Garantir existência de todos os diretórios locais necessários
mkdir -p "$LOG_DIR"
mkdir -p "$GDRIVE_LOCAL/Drª. Zuely/Documentos"
mkdir -p "$BLUETOOTH_LOCAL"
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
# ETAPA 1: SINCRONIZAÇÃO DO ONEDRIVE (Odrive: <-> Pastas Locais)
# ------------------------------------------------------------------------------
echo -e "\n=== [FASE 1/2] Sincronizando OneDrive com as pastas locais ===" | tee -a "$LOG_FILE"
notify-send "Sincronização OneDrive" "Iniciando sincronização do OneDrive às ${HORA_INICIO} h" \
    -i "$ICON_PATH" 2>/dev/null || true

# Funções auxiliares para legibilidade
sync_from_odrive() {
    local src="$1"
    local dest="$2"
    echo "-> Baixando do OneDrive: $ODRIVE_REMOTE/$src -> $dest..."
    rclone sync "$ODRIVE_REMOTE/$src" "$dest" \
        -P --update --transfers 4 --checkers 8 --stats 1s 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

sync_to_odrive() {
    local local_dir="$1"
    local remote_dir="$2"
    echo "-> Enviando para o OneDrive: $local_dir -> $ODRIVE_REMOTE/$remote_dir..."
    rclone sync "$local_dir" "$ODRIVE_REMOTE/$remote_dir" \
        -P --update --transfers 4 --checkers 8 --stats 1s 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# 1. Download de "Documentos" do OneDrive para a estrutura do Google Drive local
sync_from_odrive "Documentos" "$GDRIVE_LOCAL/Drª. Zuely/Documentos" || STATUS_ODRIVE=1

# 2. Upload de pastas locais especificadas para o OneDrive
sync_to_odrive "/home/eduardo/Fax" "Fax" || STATUS_ODRIVE=1
sync_to_odrive "/home/eduardo/Imagens" "Imagens" || STATUS_ODRIVE=1
sync_to_odrive "/home/eduardo/Modelos" "Modelos" || STATUS_ODRIVE=1
sync_to_odrive "/home/eduardo/Músicas" "Músicas" || STATUS_ODRIVE=1
sync_to_odrive "/home/eduardo/Vídeos" "Vídeos" || STATUS_ODRIVE=1

HORA_FIM_ODRIVE=$(date '+%H:%M:%S')
if [ $STATUS_ODRIVE -eq 0 ]; then
    notify-send "Sincronização OneDrive" "OneDrive concluído com sucesso às ${HORA_FIM_ODRIVE} h" \
        -i "$ICON_PATH" 2>/dev/null || true
else
    notify-send "Sincronização OneDrive" "Falha durante a sincronização do OneDrive." \
        -i dialog-error 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# ETAPA 2: SINCRONIZAÇÃO DO GOOGLE DRIVE (Pastas Locais -> Gdrive:)
# ------------------------------------------------------------------------------
if [ $STATUS_ODRIVE -eq 0 ]; then
    echo -e "\n=== [FASE 2/2] Sincronizando Pastas Locais para a nuvem Gdrive: ===" | tee -a "$LOG_FILE"
    HORA_INICIO_GDRIVE=$(date '+%H:%M:%S')
    notify-send "Sincronização Google Drive" "Iniciando upload para o Google Drive às ${HORA_INICIO_GDRIVE} h" \
        -i "$ICON_PATH" 2>/dev/null || true

    # 1. Upload do Google Drive local -> Gdrive:
    echo "-> Sincronizando: $GDRIVE_LOCAL -> $GDRIVE_REMOTE..."
    rclone sync "$GDRIVE_LOCAL" "$GDRIVE_REMOTE" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s \
        2>&1 | tee -a "$LOG_FILE" || STATUS_GDRIVE=1

    # 2. Upload do Bluetooth local -> Gdrive: (raiz do remoto)
    echo "-> Sincronizando: $BLUETOOTH_LOCAL -> $GDRIVE_REMOTE..."
    rclone sync "$BLUETOOTH_LOCAL" "$GDRIVE_REMOTE" \
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
    echo "Falha na etapa do OneDrive. Sincronização do Google Drive abortada para segurança." | tee -a "$LOG_FILE"
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
