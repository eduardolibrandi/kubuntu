#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação de Ferramentas de Estudo em Cibersegurança / Hacking Ético
# Sistema: Ubuntu / Kubuntu
# ==============================================================================

echo "=== 1. Atualizando repositórios ==="
sudo apt update

echo "=== 2. Instalando Ferramentas de Redes e Reconhecimento (APT) ==="
FERRAMENTAS_REDE=(
    nmap            # Varredura de portas, redes e detecção de SO
    wireshark       # Analisador de tráfego de rede (GUI)
    tshark          # Analisador de tráfego via terminal
    net-tools       # Utilitários de rede tradicionais (ifconfig, netstat)
    dnsutils        # Ferramentas DNS (dig, nslookup)
    whois           # Consulta de registros de domínio
    traceroute      # Mapeamento de rotas de rede
    curl            # Requisições de rede
    wget            # Downloads via terminal
    tcpdump         # Captura de pacotes leve via CLI
)

sudo apt install -y "${FERRAMENTAS_REDE[@]}"

echo "=== 3. Instalando Ferramentas de Análise Web e Força Bruta (APT) ==="
FERRAMENTAS_WEB=(
    sqlmap          # Análise e exploração de SQL Injection
    gobuster        # Brute force de diretórios e subdomínios em servidores web
    hydra           # Brute force de credenciais em serviços de rede (SSH, FTP, etc)
    john            # John the Ripper - Quebra e auditoria de hashes de senhas
    hashcat         # Quebrador de hashes acelerado por hardware
)

sudo apt install -y "${FERRAMENTAS_WEB[@]}"

echo "=== 4. Instalando Frameworks e Utilitários Avançados (APT) ==="
FERRAMENTAS_AVANCADAS=(
    metasploit-framework # Framework de teste de exploração de vulnerabilidades
    zbar-tools           # Leitura e análise de QR codes via CLI
    exiftool             # Análise e extração de metadados em arquivos/imagens
)

# Nota: Se o metasploit-framework não estiver disponível nos repositórios padrão da sua versão,
# o comando abaixo continuará sem travar a execução das demais ferramentas.
sudo apt install -y "${FERRAMENTAS_AVANCADAS[@]}" || echo "Aviso: Alguns pacotes avançados podem não estar na base padrão."

echo "=== 5. Instalando Proxy Web (Burp Suite / OWASP ZAP) via Snap ==="

# Burp Suite Community Edition
sudo snap install burpsuite --community || true

# OWASP ZAP (Zed Attack Proxy)
sudo snap install zaproxy --classic || true

echo "=== 6. Ajustando Permissões do Wireshark ==="
# Permite capturar pacotes de rede sem precisar rodar a interface como root/sudo
sudo usermod -aG wireshark $USER

echo "=================================================================="
echo " Instalação concluída com sucesso!"
echo " NOTA: Para capturar pacotes com o Wireshark sem usar 'sudo',"
echo " faça logout e login novamente no sistema."
echo "=================================================================="
