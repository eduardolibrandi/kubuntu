#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Erro: Execute como root (sudo).${NC}"
   exit 1
fi

echo -e "${GREEN}=== INICIANDO LIMPEZA DEFINITIVA DO SISTEMA ===${NC}\n"
df -h / /boot 2>/dev/null | awk 'NR==1 || NR==2 || /boot/'
echo

# 1. Removendo kernels antigos e dependências órfãs
echo -e "${BLUE}[1/4] Removendo kernels antigos e pacotes órfãos em /boot...${NC}"
if command -v apt-get &>/dev/null; then
    apt-get autoremove --purge -v -y
fi

# 2. Limpeza de cache do APT
echo -e "\n${BLUE}[2/4] Limpando cache do APT...${NC}"
if command -v apt-get &>/dev/null; then
    apt-get autoclean -y
    apt-get clean -y
fi

# 3. Limpeza de temporários com visualização de arquivos
echo -e "\n${BLUE}[3/4] Removendo temporários (/tmp, /var/tmp, /var/cache)...${NC}"
find /tmp -mindepth 1 -atime +3 -print -delete 2>/dev/null || true
find /var/tmp -mindepth 1 -atime +3 -print -delete 2>/dev/null || true
find /var/cache -type f \( -name '*.bin' -o -name '*.gz' \) -print -delete 2>/dev/null || true

# 4. Limpeza de logs
echo -e "\n${BLUE}[4/4] Limpando registros de logs antigos...${NC}"
if command -v journalctl &>/dev/null; then
    journalctl --vacuum-size=100M
fi
find /var/log -type f \( -name '*.gz' -o -name '*.old' -o -name '*.1' \) -print -delete 2>/dev/null || true

echo -e "\n${GREEN}=== LIMPEZA CONCLUÍDA ===${NC}\n"
df -h / /boot 2>/dev/null | awk 'NR==1 || NR==2 || /boot/'
