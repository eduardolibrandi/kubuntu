#!/bin/bash
# Limpeza de lixo digital + verificação ClamAV
# - Não-recursivo nas raízes das partições
# - Recursivo apenas em locais de alto contato com a internet
# - /home fica de fora (script separado)
# Sem shred. Com --dry-run

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}=== MODO DRY-RUN (não apaga nada e não executa clamscan de verdade) ===${NC}"
fi

run() {
    if $DRY_RUN; then
        echo "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

LOG_FILE="/tmp/clamav_scan_$(date +%Y%m%d_%H%M%S).log"
echo -e "${GREEN}Iniciando limpeza de lixo digital + verificação ClamAV...${NC}"
echo "Log do ClamAV será salvo em: $LOG_FILE"
echo

#######################################
# 0. Verificar se o ClamAV está instalado
#######################################
if ! command -v clamscan &>/dev/null; then
    echo -e "${RED}ClamAV não encontrado!${NC}"
    echo "Instale com:"
    echo "  Debian/Ubuntu: sudo apt install clamav clamav-daemon"
    echo "  Fedora/RHEL:   sudo dnf install clamav clamav-update"
    echo "  Arch:          sudo pacman -S clamav"
    exit 1
fi

#######################################
# 1. Atualizar base de vírus do ClamAV
#######################################
echo -e "${BLUE}>>> Atualizando base de vírus do ClamAV...${NC}"
if $DRY_RUN; then
    echo "[DRY-RUN] freshclam"
else
    systemctl stop clamav-freshclam 2>/dev/null || true
    freshclam --quiet || echo -e "${YELLOW}Aviso: não foi possível atualizar a base (pode precisar de sudo ou rede)${NC}"
    systemctl start clamav-freshclam 2>/dev/null || true
fi
echo

#######################################
# 2. Limpeza de lixo digital
#######################################

echo -e "${YELLOW}>>> Limpando /tmp${NC}"
run "find /tmp -type f -atime +7 -delete 2>/dev/null || true"
run "find /tmp -type d -empty -delete 2>/dev/null || true"
echo "  /tmp limpo."

echo -e "${YELLOW}>>> Limpando /var${NC}"
run "find /var/log -type f -name '*.gz' -delete 2>/dev/null || true"
run "find /var/log -type f -name '*.old' -delete 2>/dev/null || true"
run "find /var/log -type f -name '*.1' -delete 2>/dev/null || true"
run "find /var/log -type f -mtime +30 -exec truncate -s 0 {} \; 2>/dev/null || true"

if command -v apt-get &>/dev/null; then
    run "apt-get clean -y 2>/dev/null || true"
    run "apt-get autoclean -y 2>/dev/null || true"
fi
if command -v dnf &>/dev/null; then
    run "dnf clean all 2>/dev/null || true"
fi
if command -v yum &>/dev/null; then
    run "yum clean all 2>/dev/null || true"
fi
if command -v pacman &>/dev/null; then
    run "pacman -Sc --noconfirm 2>/dev/null || true"
fi

run "rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true"
run "rm -rf /var/tmp/* 2>/dev/null || true"
run "find /var/tmp -type f -atime +7 -delete 2>/dev/null || true"
echo "  /var limpo."

echo -e "${YELLOW}>>> Limpando /opt${NC}"
run "find /opt -type f -name '*.tmp' -delete 2>/dev/null || true"
run "find /opt -type f -name '*~' -delete 2>/dev/null || true"
run "find /opt -type d -name 'cache' -exec rm -rf {} + 2>/dev/null || true"
run "find /opt -type d -name 'tmp' -exec rm -rf {} + 2>/dev/null || true"
run "find /opt -type d -name '.cache' -exec rm -rf {} + 2>/dev/null || true"
echo "  /opt limpo."

echo -e "${YELLOW}>>> Limpando /usr/local${NC}"
run "find /usr/local -type f -name '*.tmp' -delete 2>/dev/null || true"
run "find /usr/local -type f -name '*~' -delete 2>/dev/null || true"
run "find /usr/local -type d -name 'cache' -exec rm -rf {} + 2>/dev/null || true"
run "find /usr/local -type d -name '.cache' -exec rm -rf {} + 2>/dev/null || true"
echo "  /usr/local limpo."

if [ -d /src ]; then
    echo -e "${YELLOW}>>> Limpando /src${NC}"
    run "find /src -type f -name '*.o' -delete 2>/dev/null || true"
    run "find /src -type f -name '*.tmp' -delete 2>/dev/null || true"
    run "find /src -type d -name 'build' -exec rm -rf {} + 2>/dev/null || true"
    run "find /src -type d -name '.cache' -exec rm -rf {} + 2>/dev/null || true"
    echo "  /src limpo."
fi

echo -e "${YELLOW}>>> Limpando /usr (conservador)${NC}"
run "find /usr -type f -name '*~' -delete 2>/dev/null || true"
run "find /usr -type f -name '*.tmp' -delete 2>/dev/null || true"
echo "  /usr limpo."

echo -e "${YELLOW}>>> Verificando /boot e /boot/efi${NC}"
echo "  Nenhuma limpeza agressiva (segurança)."

#######################################
# 3. Escaneamento ClamAV
#######################################
echo
echo -e "${BLUE}>>> Iniciando escaneamento ClamAV...${NC}"

# Função auxiliar
scan() {
    local path="$1"
    local mode="$2"   # "non-recursive" ou "recursive"
    local extra="${3:-}"

    if [ ! -e "$path" ]; then
        echo -e "  ${YELLOW}$path não existe, pulando.${NC}"
        return
    fi

    if [[ "$mode" == "recursive" ]]; then
        echo -e "  → Recursivo: $path"
        if $DRY_RUN; then
            echo "[DRY-RUN] clamscan -r --bell -i $extra \"$path\""
        else
            clamscan -r --bell -i $extra "$path" >> "$LOG_FILE" 2>&1 || true
        fi
    else
        echo -e "  → Não-recursivo: $path"
        if $DRY_RUN; then
            echo "[DRY-RUN] clamscan --bell -i $extra \"$path\""
        else
            clamscan --bell -i $extra "$path" >> "$LOG_FILE" 2>&1 || true
        fi
    fi
}

echo -e "${BLUE}--- Escaneamento NÃO-RECURSIVO nas raízes das partições ---${NC}"
scan "/"           "non-recursive" "--exclude-dir=home --exclude-dir=proc --exclude-dir=sys --exclude-dir=dev --exclude-dir=run --exclude-dir=tmp --exclude-dir=var --exclude-dir=opt --exclude-dir=usr --exclude-dir=boot --exclude-dir=src"
scan "/boot"       "non-recursive"
scan "/boot/efi"   "non-recursive"
scan "/usr"        "non-recursive"
scan "/var"        "non-recursive"
scan "/tmp"        "non-recursive"
scan "/opt"        "non-recursive"
scan "/usr/local"  "non-recursive"
scan "/src"        "non-recursive"

echo
echo -e "${BLUE}--- Escaneamento RECURSIVO nos locais de ALTO contato com a internet ---${NC}"

# Locais de maior exposição (caches, downloads, logs, serviços web, etc.)
scan "/var/cache"          "recursive"
scan "/var/tmp"            "recursive"
scan "/var/log"            "recursive"
scan "/var/www"            "recursive"   # se existir (servidor web)
scan "/var/spool"          "recursive"
scan "/tmp"                "recursive"   # agora recursivo (mais completo)
scan "/opt"                "recursive"
scan "/usr/local"          "recursive"
scan "/src"                "recursive"

# Caches comuns de programas que baixam da internet
scan "/var/cache/apt"      "recursive" 2>/dev/null || true
scan "/var/lib/apt"        "recursive" 2>/dev/null || true

echo
echo -e "${GREEN}Escaneamento ClamAV concluído.${NC}"
echo "Resultados salvos em: $LOG_FILE"
echo
echo "Para ver apenas os arquivos infectados (se houver):"
echo "  grep -E 'FOUND|Infected files' $LOG_FILE"

#######################################
# Resumo final
#######################################
echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Limpeza + Verificação concluídas${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo "Resumo do que foi feito:"
echo "  • Limpeza de lixo digital (sem shred)"
echo "  • Scan NÃO-recursivo nas raízes das partições"
echo "  • Scan RECURSIVO apenas nos diretórios de alto contato com a internet"
echo "  • /home foi ignorado (script separado)"
echo

if $DRY_RUN; then
    echo -e "${YELLOW}Foi apenas simulação. Rode sem --dry-run para aplicar.${NC}"
fi

echo
echo "Uso:"
echo "  sudo bash limpeza_lixo.sh          # executa de verdade"
echo "  sudo bash limpeza_lixo.sh --dry-run # só mostra o que faria"
