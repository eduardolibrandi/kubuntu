#!/usr/bin/env bash
# ==============================================================================
# Script de Sincronização Bidirecional do Google Drive via rclone
# ==============================================================================

REMOTE="Gdrive:"
LOCAL_DIR="/home/eduardo/Google Drive"
LOG_DIR="/home/eduardo/.var/rclone"
LOG_FILE="$LOG_DIR/rclone.txt"
LOCK_FILE="/tmp/gdrive_sync.lock"
ICON_PATH="/home/eduardo/.local/share/icons/ExposeAir/apps/scalable/unity-scope-gdrive.svg"

# Garantir que os diretórios necessários existam localmente
mkdir -p "$LOG_DIR"
mkdir -p "$LOCAL_DIR"

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
    # Filtra as linhas contendo datas (formato YYYY-MM-DD) das últimas 24 horas
    CUTOFF_SEC=$(date -d "24 hours ago" +%s 2>/dev/null || date -v-1d +%s)
    
    # Processa o arquivo mantendo apenas entradas recentes
    awk -v cutoff="$CUTOFF_SEC" '
    {
        # Tenta extrair a data/hora do início do log do rclone ou do echo
        if (match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
            log_date = substr($0, RSTART, RLENGTH)
            "date -d \"" log_date "\" +%s 2>/dev/null" | getline log_sec
            close("date -d \"" log_date "\" +%s 2>/dev/null")
            if (log_sec >= cutoff) print $0
        } else {
            # Se a linha não tem data (continuação de erro/log), mantém se estiver dentro do fluxo
            print $0
        }
    }' "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# Notificação e Log de Início
HORA_INICIO=$(date '+%H:%M:%S')
echo "==================================================" >> "$LOG_FILE"
echo "Iniciando sincronização: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"

notify-send "Google Drive" "Sincronização iniciada às ${HORA_INICIO} h" \
    -i "$ICON_PATH" 2>/dev/null

# ------------------------------------------------------------------------------
# ETAPA 1: UPLOAD (Envia alterações locais para a nuvem primeiro)
# ------------------------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') - [FASE 1/2] Enviando arquivos locais para a nuvem..." >> "$LOG_FILE"

rclone copy "$LOCAL_DIR" "$REMOTE" \
    --update \
    --transfers 4 \
    --checkers 8 \
    --log-file="$LOG_FILE" \
    --log-level INFO

STATUS_UPLOAD=$?

# ------------------------------------------------------------------------------
# ETAPA 2: DOWNLOAD (Traz modificações da nuvem e compartilhamentos da sua mãe)
# ------------------------------------------------------------------------------
if [ $STATUS_UPLOAD -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [FASE 2/2] Baixando novidades da nuvem..." >> "$LOG_FILE"

    rclone copy "$REMOTE" "$LOCAL_DIR" \
        --update \
        --transfers 4 \
        --checkers 8 \
        --log-file="$LOG_FILE" \
        --log-level INFO

    STATUS_DOWNLOAD=$?
else
    STATUS_DOWNLOAD=$STATUS_UPLOAD
fi

# ------------------------------------------------------------------------------
# NOTIFICAÇÃO FINAL E LIMPEZA
# ------------------------------------------------------------------------------
HORA_FIM=$(date '+%H:%M:%S')

if [ $STATUS_UPLOAD -eq 0 ] && [ $STATUS_DOWNLOAD -eq 0 ]; then
    echo "Sincronização concluída com sucesso: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    notify-send "Google Drive" "Sincronização finalizada às ${HORA_FIM} h" \
        -i "$ICON_PATH" 2>/dev/null
else
    echo "Erro durante a sincronização (Upload: $STATUS_UPLOAD, Download: $STATUS_DOWNLOAD): $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    notify-send "Google Drive" "Falha ao sincronizar o Google Drive." \
        -i dialog-error 2>/dev/null
fi

# Remover arquivo de trava
rm -f "$LOCK_FILE"
