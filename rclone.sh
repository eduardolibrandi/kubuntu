#!/usr/bin/env bash
# ==============================================================================
# Script de Sincronização Automática do Google Drive via rclone
# ==============================================================================

REMOTE="Gdrive:"
DESTINO="/home/eduardo/Google Drive"
LOG_DIR="/home/eduardo/.logs"
LOG_FILE="$LOG_DIR/gdrive_sync.log"
LOCK_FILE="/tmp/gdrive_sync.lock"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Evitar que o script rode duas vezes simultaneamente
if [ -f "$LOCK_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Sincronização já em andamento. Saindo..." >> "$LOG_FILE"
    exit 0
fi

touch "$LOCK_FILE"

echo "==================================================" >> "$LOG_FILE"
echo "Iniciando sincronização: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"

# Executar o rclone copy (sem a flag inválida --use-mtime)
rclone copy "$REMOTE" "$DESTINO" \
    --update \
    --transfers 4 \
    --checkers 8 \
    --log-file="$LOG_FILE" \
    --log-level INFO

STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "Sincronização concluída com sucesso: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    notify-send "Google Drive" "Sincronização concluída com sucesso!" -i folder-gdrive 2>/dev/null
else
    echo "Erro durante a sincronização (Código: $STATUS): $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    notify-send "Google Drive" "Falha ao sincronizar o Google Drive." -i dialog-error 2>/dev/null
fi

# Remover o arquivo de trava
rm -f "$LOCK_FILE"
