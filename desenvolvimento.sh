#!/bin/bash

# Interrompe a execução em caso de erro crítico
set -e

echo "=== 1. Atualizando repositórios e pacotes do Kubuntu ==="
sudo apt update && sudo apt upgrade -y

echo "=== 2. Instalando utilitários essenciais e chaves GPG ==="
sudo apt install -y build-essential curl wget git unzip software-properties-common apt-transport-https ca-certificates gpg

# --------------------------------------------------
# CONFIGURAÇÃO DOS REPOSITÓRIOS OFICIAIS (.DEB)
# --------------------------------------------------

echo "=== 3. Configurando Repositório do VS Code ==="
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -D -o root -g root -m 644 microsoft.gpg /etc/apt/keyrings/microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm microsoft.gpg

echo "=== 4. Configurando Repositório do Sublime Text ==="
wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > sublime.gpg
sudo install -D -o root -g root -m 644 sublime.gpg /etc/apt/keyrings/sublime.gpg
echo "deb [signed-by=/etc/apt/keyrings/sublime.gpg] https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
rm sublime.gpg

echo "=== 5. Configurando Repositório Oficial do Docker ==="
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# --------------------------------------------------
# INSTALAÇÃO DOS SOFTWARES
# --------------------------------------------------

echo "=== 6. Atualizando listas com os novos repositórios ==="
sudo apt update

echo "=== 7. Instalando VS Code, Sublime Text, Docker e Docker Compose ==="
sudo apt install -y code sublime-text docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== 8. Ativando e ajustando permissões do Docker ==="
sudo systemctl enable docker
sudo systemctl start docker
# Adiciona o usuário atual ao grupo docker para não precisar usar 'sudo docker'
sudo usermod -aG docker $USER

echo "=== 9. Instalando Node.js e NPM (Ambiente Full Stack) ==="
sudo apt install -y nodejs npm
sudo npm install -g npm@latest

echo "=== 10. Instalando PHP, Apache e Composer ==="
sudo apt install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath apache2 libapache2-mod-php
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

echo "=== 11. Instalando Banco de Dados MariaDB ==="
sudo apt install -y mariadb-server mariadb-client
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "=== 12. Instalando Python 3 e Java OpenJDK ==="
sudo apt install -y python3 python3-pip python3-venv default-jdk

echo "=================================================="
echo "      INSTALAÇÃO CONCLUÍDA COM SUCESSO!           "
echo "=================================================="
echo "AVISO: Reinicie o sistema ou encerre a sessão para que as permissões do Docker entrem em vigor."
