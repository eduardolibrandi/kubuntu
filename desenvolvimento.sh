cat << 'EOF' > ~/instalar_ambiente_dev.sh
#!/usr/bin/env bash

set -e

echo "=== 1. ATUALIZANDO O SISTEMA ==="
sudo apt update && sudo apt upgrade -y

echo "=== 2. INSTALANDO DEPENDÊNCIAS ESSENCIAIS E SUPORTE A FLATPAK/SNAP ==="
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    flatpak \
    snapd

# Adiciona repositório Flathub
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "=== 3. INSTALANDO INTERFACE KDE PLASMA COMPLETA ==="
sudo apt install -y kde-full

echo "=== 4. INSTALANDO LINGUAGENS E FERRAMENTAS DE DESENVOLVIMENTO ==="
# Python 3, pip e venv (Ciência da Computação / Dados / Backend)
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Node.js (LTS) e npm (Full Stack / Frontend / Backend)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== 5. INSTALANDO DOCKER ENGINE ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Adiciona o usuário ao grupo docker para rodar sem 'sudo'
sudo usermod -aG docker $USER

echo "=== 6. INSTALANDO EDITORES E BANCOS DE DADOS (IDE / TOOLS) ==="
# Visual Studio Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f /tmp/packages.microsoft.gpg
sudo apt update
sudo apt install -y code

# DBeaver CE (Gerenciador Universal de Bancos de Dados via Flatpak)
flatpak install flathub org.dbeaver.DBeaverCommunity -y

# Postman (Testes de APIs Rest/GraphQL via Snap)
sudo snap install postman

echo "=== 7. APLICANDO LIMPEZA E CONFIGURAÇÕES FINAIS ==="
sudo systemctl enable sddm
sudo systemctl enable docker
sudo apt autoremove -y
sudo apt clean

echo "================================================================="
echo " Instalação concluída com sucesso!"
echo " RECOMENDAÇÃO: Reinicie o sistema para carregar o KDE Plasma e "
echo " aplicar as permissões do grupo Docker no seu usuário."
echo "================================================================="
EOF

# Concede permissão de execução e inicia o script
chmod +x ~/instalar_ambiente_dev.sh
./instalar_ambiente_dev.sh
