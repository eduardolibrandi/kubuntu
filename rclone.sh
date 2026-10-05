#!/usr/bin/env bash

# ==============================================================================
# MAPA DE CÓPIA COMPLETO (Nuvem -> Local /home/eduardo/...) COM CLAMAV
# ==============================================================================
#
# --- ETAPA 1: Google Drive (Gdrive:) ---
# Gdrive:Banco de Dados ----------> /home/eduardo/Banco de Dados
# Gdrive:Biblioteca do calibre ---> /home/eduardo/Biblioteca do calibre
# Gdrive:Bluetooth ---------------> /home/eduardo/Bluetooth
# Gdrive:Documentos --------------> /home/eduardo/Documentos
# Gdrive:Favoritos ---------------> /home/eduardo/Favoritos
# Gdrive:Imagens -----------------> /home/eduardo/Imagens
# Gdrive:Modelos -----------------> /home/eduardo/Modelos
# Gdrive:Músicas -----------------> /home/eduardo/Músicas
# Gdrive:Vídeos ------------------> /home/eduardo/Vídeos
#
# --- ETAPA 2: OneDrive (Odrive:) ---
# Odrive:Banco de Dados ----------> /home/eduardo/Banco de Dados
# Odrive:Documentos --------------> /home/eduardo/Documentos/Drª. Zuely
# Odrive:Fax ---------------------> /home/eduardo/Fax
# Odrive:Imagens -----------------> /home/eduardo/Imagens
# Odrive:Modelos -----------------> /home/eduardo/Modelos
# Odrive:Músicas -----------------> /home/eduardo/Músicas
# Odrive:Vídeos ------------------> /home/eduardo/Vídeos
#
# Cada pasta é escaneada pelo ClamAV imediatamente após ser copiada.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# CONFIGURAÇÕES E VARIÁVEIS DE AMBIENTE
# ------------------------------------------------------------------------------
BASE_DESTINO="/home/eduardo"
LOG_DIR="$BASE_DESTINO/.var/rclone"
LOG_FILE="$LOG_DIR/rclone_cloud_download.txt"
LOCK_FILE="/tmp/cloud_download.lock"
ICON_PATH="$BASE_DESTINO/.local/share/icons/ExposeAir/apps/scalable/unity-scope-gdrive.svg"

# Garantir existência do diretório de log
mkdir -p "$LOG_DIR"

# ------------------------------------------------------------------------------
# TRATAMENTO DE TRAVA DE EXECUÇÃO (LOCK FILE)
# ------------------------------------------------------------------------------
if [ -f "$LOCK_FILE" ]; then
    echo "Erro: Outra instância da cópia das nuvens já está em execução." | tee -a "$LOG_FILE"
    exit 1
fi

touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Limpeza simples de logs antigos (mais de 24h)
if [ -f "$LOG_FILE" ]; then
    find "$LOG_DIR" -name "rclone_cloud_download.txt" -mtime +1 -exec rm -f {} \;
fi

HORA_INICIO=$(date '+%H:%M:%S')
echo "==================================================" | tee -a "$LOG_FILE"
echo "Iniciando sincronização Cloud -> Local com ClamAV: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"

notify-send "Cópia das Nuvens (Gdrive & Odrive)" "Iniciando download e vistoria antivírus às ${HORA_INICIO} h" \
    -i "$ICON_PATH" 2>/dev/null || true

# Verificar se o daemon do ClamAV está em execução
if ! systemctl is-active --quiet clamav-daemon; then
    echo "⚠️  Aviso: O serviço clamav-daemon não está rodando. Tentando iniciar..." | tee -a "$LOG_FILE"
    sudo systemctl start clamav-daemon || true
fi

STATUS_GERAL=0
TOTAL_AMEACAS=0

# ------------------------------------------------------------------------------
# FUNÇÃO REUTILIZÁVEL PARA COPIAR PASTA E EXECUTAR VISTORIA CLAMAV
# USO: copy_and_scan_folder "REMOTO:" "NOME_PASTA_REMOTA" "CAMINHO_LOCAL"
# ------------------------------------------------------------------------------
copy_and_scan_folder() {
    local remote="$1"
    local remote_folder="$2"
    local local_path="$3"
    local remote_path="${remote}${remote_folder}"

    echo -e "\n--------------------------------------------------" | tee -a "$LOG_FILE"
    echo "-> [1/2] Sincronizando: $remote_path -> $local_path" | tee -a "$LOG_FILE"

    # Criar pasta local caso não exista (inclui subdiretórios)
    if [ ! -d "$local_path" ]; then
        echo "   Criando diretório local: $local_path" | tee -a "$LOG_FILE"
        mkdir -p "$local_path"
    fi

    # 1. Executar a cópia via Rclone
    rclone copy "$remote_path" "$local_path" \
        -P \
        --update \
        --transfers 4 \
        --checkers 8 \
        --stats 1s \
        2>&1 | tee -a "$LOG_FILE"

    local rclone_status=${PIPESTATUS[0]}
    if [ $rclone_status -ne 0 ]; then
        echo "   ❌ Erro ao copiar $remote_path (Código: $rclone_status)" | tee -a "$LOG_FILE"
        STATUS_GERAL=1
    else
        echo "   ✅ $remote_path copiado com sucesso." | tee -a "$LOG_FILE"
    fi

    # 2. Executar a vistoria do ClamAV na pasta sincronizada
    echo "-> [2/2] Vistoriando com ClamAV (clamdscan): $local_path" | tee -a "$LOG_FILE"
    
    START_SCAN=$(date +%s)
    
    if nice -n 19 ionice -c 3 clamdscan --multiscan --fdpass "$local_path" 2>&1 | tee -a "$LOG_FILE"; then
        END_SCAN=$(date +%s)
        echo "   🛡️ $local_path verificado sem ameaças ($((END_SCAN - START_SCAN))s)." | tee -a "$LOG_FILE"
    else
        local clam_status=${PIPESTATUS[0]}
        END_SCAN=$(date +%s)
        if [ $clam_status -eq 1 ]; then
            echo "   🚨 AMEAÇA ENCONTRADA em $local_path!" | tee -a "$LOG_FILE"
            TOTAL_AMEACAS=$((TOTAL_AMEACAS + 1))
            STATUS_GERAL=1
            notify-send "🚨 ClamAV Alerta" "Ameaça encontrada em: $local_path" -u critical 2>/dev/null || true
        else
            echo "   ⚠️️ Aviso/Erro na vistoria de $local_path (Código: $clam_status)" | tee -a "$LOG_FILE"
        fi
    fi

    return 0
}

# ------------------------------------------------------------------------------
# ETAPA 1: CÓPIAS DO GOOGLE DRIVE (Gdrive:) E VISTORIA
# ------------------------------------------------------------------------------
echo -e "\n==================================================" | tee -a "$LOG_FILE"
echo "--- INICIANDO CÓPIA E VISTORIA: GOOGLE DRIVE (Gdrive:) ---" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

copy_and_scan_folder "Gdrive:" "Banco de Dados"        "$BASE_DESTINO/Banco de Dados"
copy_and_scan_folder "Gdrive:" "Biblioteca do calibre" "$BASE_DESTINO/Biblioteca do calibre"
copy_and_scan_folder "Gdrive:" "Bluetooth"             "$BASE_DESTINO/Bluetooth"
copy_and_scan_folder "Gdrive:" "Documentos"            "$BASE_DESTINO/Documentos"
copy_and_scan_folder "Gdrive:" "Favoritos"             "$BASE_DESTINO/Favoritos"
copy_and_scan_folder "Gdrive:" "Imagens"               "$BASE_DESTINO/Imagens"
copy_and_scan_folder "Gdrive:" "Modelos"               "$BASE_DESTINO/Modelos"
copy_and_scan_folder "Gdrive:" "Músicas"               "$BASE_DESTINO/Músicas"
copy_and_scan_folder "Gdrive:" "Vídeos"                "$BASE_DESTINO/Vídeos"

# ------------------------------------------------------------------------------
# ETAPA 2: CÓPIAS DO ONEDRIVE (Odrive:) E VISTORIA
# ------------------------------------------------------------------------------
echo -e "\n==================================================" | tee -a "$LOG_FILE"
echo "--- INICIANDO CÓPIA E VISTORIA: ONEDRIVE (Odrive:) ---" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

copy_and_scan_folder "Odrive:" "Banco de Dados"        "$BASE_DESTINO/Banco de Dados"
copy_and_scan_folder "Odrive:" "Documentos"            "$BASE_DESTINO/Documentos/Drª. Zuely"
copy_and_scan_folder "Odrive:" "Fax"                   "$BASE_DESTINO/Fax"
copy_and_scan_folder "Odrive:" "Imagens"               "$BASE_DESTINO/Imagens"
copy_and_scan_folder "Odrive:" "Modelos"               "$BASE_DESTINO/Modelos"
copy_and_scan_folder "Odrive:" "Músicas"               "$BASE_DESTINO/Músicas"
copy_and_scan_folder "Odrive:" "Vídeos"                "$BASE_DESTINO/Vídeos"

# ------------------------------------------------------------------------------
# NOTIFICAÇÕES E CONCLUSÃO
# ------------------------------------------------------------------------------
HORA_FIM=$(date '+%H:%M:%S')

echo -e "\n==================================================" | tee -a "$LOG_FILE"
echo "RESUMO DA OPERAÇÃO:" | tee -a "$LOG_FILE"
echo "Finalizado às: ${HORA_FIM} em $(date '+%Y-%m-%d')" | tee -a "$LOG_FILE"
echo "Total de ameaças encontradas: $TOTAL_AMEACAS" | tee -a "$LOG_FILE"

if [ $STATUS_GERAL -eq 0 ] && [ $TOTAL_AMEACAS -eq 0 ]; then
    echo "Status Final: SUCESSO COMPLETO" | tee -a "$LOG_FILE"
    echo "==================================================" | tee -a "$LOG_FILE"
    notify-send "Cópia e Antivírus" "Sincronização e varredura concluídas com SUCESSO às ${HORA_FIM} h!" \
        -i "$ICON_PATH" 2>/dev/null || true
else
    echo "Status Final: CONCLUÍDO COM ALERTAS/ERROS" | tee -a "$LOG_FILE"
    echo "==================================================" | tee -a "$LOG_FILE"
    notify-send "Cópia e Antivírus" "Concluído com alertas/erros ($TOTAL_AMEACAS ameaça(s)). Verifique $LOG_FILE" \
        -i dialog-error 2>/dev/null || true
fi
