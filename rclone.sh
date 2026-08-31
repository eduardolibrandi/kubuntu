#!/usr/bin/env bash
# ==============================================================================
# Script de Sincronização Multinuvem (OneDrive -> Local -> Google Drive)
# ==============================================================================

GDRIVE_REMOTE="Gdrive:"
ODRIVE_REMOTE="Odrive:"

GDRIVE_LOCAL="/home/eduardo/Google Drive"
LOG_DIR="/home/eduardo/.var/rclone"
LOG_FILE="$LOG_DIR/rclone.txt"
LOCK_FILE="/tmp/cloud_sync.lock"
ICON_PATH="/home/eduardo/.local/share/icons/ExposeAir/apps/scalable/unity-scope-gdrive.svg"

# Garantir que todos os diretórios de destino locais existam
mkdir -p "$LOG_DIR"
mkdir -p "$GDRIVE_LOCAL"
mkdir -p "$GDRIVE_LOCAL/Drª Zuely"
mkdir -p "/home/eduardo/Imagens"
mkdir -p "/home/eduardo/Modelos"
mkdir -p "/home/eduardo/Músicas"
mkdir -p "/home/eduardo/Vídeos"

# Evitar execução simultânea (Lock Mechanism)
if [ -f "$LOCK_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Sincronização já em andamento. Saindo..." >> "$LOG_FILE"
    exit 0
fi

touch "$LOCK_FILE"

# ------------------------------------------------------------------------------
# ROTAÇÃO DE LOGS (Mantém apenas os registros das últimas 24 horas)
# ------------------------------------------------------------------------------
if [ -f "$LOG_FILE" ]; then
    CUTOFF_SEC=$(date -d "24 hours ago" +%s 2>/dev/null || date -v-1d +%s)
    awk -v cutoff="$CUTOFF_SEC" '
    {
        if (match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
            log_date = substr($0, RSTART, RLENGTH)
            "date -d \"" log_date "\" +%s 2>/dev/null" | getline log_sec
            close("date -d \"" log_date "\" +%s 2>/dev/null")
            if (log_sec >= cutoff) print $0
        } else {
            print $0
        }
    }' "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# Notificação e Log de Início
HORA_INICIO=$(date '+%H:%M:%S')
echo "==================================================" >> "$LOG_FILE"
echo "Iniciando sincronização geral: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"

notify-send "Sincronização de Nuvens" "Sincronização iniciada às ${HORA_INICIO} h" \
    -i "$ICON_PATH" 2>/dev/null

STATUS_ODRIVE=0

# ------------------------------------------------------------------------------
# ETAPA 1: DOWNLOAD DO ONEDRIVE (Odrive: -> Pastas Locais Correspondentes)
# ------------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') - [FASE 1/3] Sincronizando pastas do OneDrive para a máquina local..." >> "$LOG_FILE"

# Função auxiliar para copiar cada pasta do Odrive
sync_odrive_folder() {
    local src_folder="$1"
    local dest_folder="$2"
    
    rclone copy "$ODRIVE_REMOTE/$src_folder" "$dest_folder/$src_folder" \
        --update \
        --transfers 4 \
        --checkers 8 \
        --log-file="$LOG_FILE" \
        --log-level INFO
        
    return $?
}

# Caso especial: Documentos vai para a pasta da Drª Zuely dentro do Google Drive
rclone copy "$ODRIVE_REMOTE/Documentos" "$GDRIVE_LOCAL/Drª Zuely/Documentos" \
    --update --transfers 4 --checkers 8 --log-file="$LOG_FILE" --log-level INFO || STATUS_ODRIVE=1

# Pastas direcionadas para /home/eduardo/Google Drive
sync_odrive_folder "Anexos" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Banco de Dados" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Contatos" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "E-mails" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Fax" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Livros" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Pdf" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1
sync_odrive_folder "Scripts" "$GDRIVE_LOCAL" || STATUS_ODRIVE=1

# Pastas direcionadas para a HOME do usuário
sync_odrive_folder "Imagens" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Modelos" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Músicas" "/home/eduardo" || STATUS_ODRIVE=1
sync_odrive_folder "Vídeos" "/home/eduardo" || STATUS_ODRIVE=1

# ------------------------------------------------------------------------------
# ETAPA 2: UPLOAD PARA GOOGLE DRIVE (Local -> Gdrive:)
# ------------------------------------------------------------------------------
if [ $STATUS_ODRIVE -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [FASE 2/3] Enviando arquivos locais para o Google Drive..." >> "$LOG_FILE"

    rclone copy "$GDRIVE_LOCAL" "$GDRIVE_REMOTE" \
        --update \
        --transfers 4 \
        --checkers 8 \
        --log-file="$LOG_FILE" \
        --log-level INFO

    STATUS_GDRIVE_UPLOAD=$?
else
    echo "Falha no download do OneDrive. Ignorando etapas do Google Drive." >> "$LOG_FILE"
    STATUS_GDRIVE_UPLOAD=1
fi

# ------------------------------------------------------------------------------
# ETAPA 3: DOWNLOAD DO GOOGLE DRIVE (Gdrive: -> Local)
# ------------------------------------------------------------------------------
if [ $STATUS_GDRIVE_UPLOAD -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [FASE 3/3] Baixando novidades do Google Drive..." >> "$LOG_FILE"

    rclone copy "$GDRIVE_REMOTE" "$GDRIVE_LOCAL" \
        --update \
        --transfers 4 \
        --checkers 8 \
        --log-file="$LOG_FILE" \
        --log-level INFO

    STATUS_GDRIVE_DOWNLOAD=$?
else
    STATUS_GDRIVE_DOWNLOAD=1
fi

# ------------------------------------------------------------------------------
# NOTIFICAÇÃO FINAL E LIMPEZA
# ------------------------------------------------------------------------------
HORA_FIM=$(date '+%H:%M:%S')

if [ $STATUS_ODRIVE -eq 0 ] && [ $STATUS_GDRIVE_UPLOAD -eq 0 ] && [ $STATUS_GDRIVE_DOWNLOAD -eq 0 ]; then
    echo "Sincronização concluída com sucesso: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    notify-send "Sincronização de Nuvens" "Sincronização finalizada às ${HORA_FIM} h" \
        -i "$ICON_PATH" 2>/dev/null
else
    echo "Erro durante a sincronização (Odrive: $STATUS_ODRIVE, Gdrive Up: $STATUS_GDRIVE_UPLOAD, Gdrive Down: $STATUS_GDRIVE_DOWNLOAD): $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    notify-send "Sincronização de Nuvens" "Falha na sincronização das nuvens." \
        -i dialog-error 2>/dev/null
fi

# Remover arquivo de trava
rm -f "$LOCK_FILE"
