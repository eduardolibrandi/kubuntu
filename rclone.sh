#!/usr/bin/env bash
# ==============================================================================
# Script de Sincronização Multinuvem (Corrigido)
# ==============================================================================

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

# Se o arquivo de trava existir, remove se tiver mais de 1 hora (evita travamento eterno)
if [ -f "$LOCK_FILE" ]; then
    find "$LOCK_FILE" -mmin +60 -exec rm -f {} \;
fi

if [ -f "$LOCK_FILE" ]; then
    echo "Uma sincronização já está em andamento. Caso não esteja, rode: rm -f /tmp/cloud_sync.lock"
    exit 0
fi

# Cria o arquivo de trava e garante sua remoção ao encerrar o script
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Rotação de Log simples (Se o arquivo tiver mais de 24 horas / 1 dia, é limpo)
if [ -f "$LOG_FILE" ]; then
    find "$LOG_DIR" -name "rclone.txt" -mtime +1 -exec rm -f {} \;
fi

HORA_INICIO=$(date '+%H:%M:%S')
echo "==================================================" | tee -a "$LOG_FILE"
echo "Iniciando sincronização geral: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"

notify-send "Sincronização de Nuvens" "Sincronização iniciada às ${HORA_INICIO} h" \
    -i "$ICON_PATH" 2>/dev/null

STATUS_ODRIVE=0

# ------------------------------------------------------------------------------
# ETAPA 1: DOWNLOAD DO ONEDRIVE (Odrive: -> Pastas Locais)
# ------------------------------------------------------------------------------
echo -e "\n=== [FASE 1/3] Sincronizando OneDrive para a máquina local ===" | tee -a "$LOG_FILE"

sync_odrive_folder() {
    local src_folder="$1"
    local dest_folder="$2"
    echo "-> Baixando: $src_folder..."
    
    rclone copy "$ODRIVE_REMOTE/$src_folder" "$dest_folder/$src_folder" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s
        
    return $?
}

# Documentos -> Drª Zuely
echo "-> Baixando: Documentos (Drª Zuely)..."
rclone copy "$ODRIVE_REMOTE/Documentos" "$GDRIVE_LOCAL/Drª Zuely/Documentos" \
    -P --update --transfers 4 --checkers 8 --stats 1s || STATUS_ODRIVE=1

# Pastas para /home/eduardo/Google Drive
sync_odrive_folder "Anexos" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Banco de Dados" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Contatos" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "E-mails" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Fax" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Livros" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Pdf" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Scripts" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1

# Pastas para a HOME
sync_odrive_folder "Imagens" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Modelos" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Músicas" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Vídeos" "/home/eduardo" || STATUS_ODRIVE=1

# ------------------------------------------------------------------------------
# ETAPA 2: UPLOAD PARA GOOGLE DRIVE (Local -> Gdrive:)
# ------------------------------------------------------------------------------
if [ $STATUS_ODRIVE -eq 0 ]; then
    echo -e "\n=== [FASE 2/3] Enviando arquivos locais para o Google Drive ===" | tee -a "$LOG_FILE"

    rclone copy "$GDRIVE_LOCAL" "$GDRIVE_REMOTE" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s

    STATUS_GDRIVE_UPLOAD=$?
else
    echo "Falha no download do OneDrive. Ignorando etapas do Google Drive." | tee -a "$LOG_FILE"
    STATUS_GDRIVE_UPLOAD=1
fi

# ------------------------------------------------------------------------------
# ETAPA 3: DOWNLOAD DO GOOGLE DRIVE (Gdrive: -> Local)
# ------------------------------------------------------------------------------
if [ $STATUS_GDRIVE_UPLOAD -eq 0 ]; then
    echo -e "\n=== [FASE 3/3] Baixando novidades do Google Drive ===" | tee -a "$LOG_FILE"

    rclone copy "$GDRIVE_REMOTE" "$GDRIVE_LOCAL" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s

    STATUS_GDRIVE_DOWNLOAD=$?
else
    STATUS_GDRIVE_DOWNLOAD=1
fi

# ------------------------------------------------------------------------------
# NOTIFICAÇÃO FINAL
# ------------------------------------------------------------------------------
HORA_FIM=$(date '+%H:%M:%S')

if [ $STATUS_ODRIVE -eq 0 ] && [ $STATUS_GDRIVE_UPLOAD -eq 0 ] && [ $STATUS_GDRIVE_DOWNLOAD -eq 0 ]; then
    echo -e "\nSincronização concluída com sucesso: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
    notify-send "Sincronização de Nuvens" "Sincronização finalizada às ${HORA_FIM} h" \
        -i "$ICON_PATH" 2>/dev/null
else
    echo -e "\nErro durante a sincronização (Odrive: $STATUS_ODRIVE, Gdrive Up: $STATUS_GDRIVE_UPLOAD, Gdrive Down: $STATUS_GDRIVE_DOWNLOAD): $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
    notify-send "Sincronização de Nuvens" "Falha na sincronização das nuvens." \
        -i dialog-error 2>/dev/null
fi
