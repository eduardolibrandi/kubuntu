#!/usr/bin/env bash
# ==============================================================================
# Script de Pós-Instalação Resistente a Erros - Kubuntu
# ==============================================================================

# NOTA: Removemos 'set -e' para evitar o encerramento prematuro do script.

echo "=== 1. Atualizando listas de repositórios e sistema ==="
sudo apt update && sudo apt upgrade -y

echo "=== 2. Habilitando repositórios oficiais adicionais ==="
sudo add-apt-repository multiverse -y
sudo add-apt-repository restricted -y

# PPA Conky Manager (Executa com '|| true' para não travar se o PPA não suportar a versão)
echo "=== 3. Adicionando PPAs ==="
sudo add-apt-repository ppa:ubuntuhandbook1/conkymanager2 -y || echo "Aviso: Falha ao adicionar PPA do Conky Manager."

sudo apt update

echo "=== 4. Pré-configurando aceitação de licenças (Fonts Microsoft) ==="
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

echo "=== 5. Instalando pacotes e bibliotecas via APT ==="

PACOTES_APT=(
  # Base KDE / Kubuntu Completa
  kubuntu-desktop
  kubuntu-restricted-extras
  kio-gdrive
  
  # Ferramentas do Sistema e Compactadores
  build-essential
  apt-transport-https
  ca-certificates
  gdebi
  bleachbit
  rclone
  snapd
  gufw
  wireguard
  wireguard-tools
  
  # Arquivos e Compressão
  arj
  cabextract
  lbzip2
  lhasa
  lrzip
  lz4
  lzop
  pax
  pigz
  rar
  unace
  unrar
  
  # Desenvolvimento / Programação
  default-jdk
  openjdk-17-jdk
  nodejs
  npm
  sqlitebrowser
  diffoscope
  
  # Utilidades, Segurança e Redes
  keepassxc
  pdfarranger
  yad
  zbar-tools
  pcscd
  libnss3-tools
  network-manager-openvpn
  wireshark
  forensics-all
  forensics-all-gui
  stegosuite
  linssid
  packeth
  packetsender
  ddrescueview
  
  # Multimídia, Áudio e Vídeo
  audacity
  ardour
  gimp
  gimp-data-extras
  gimp-help-pt-br
  inkscape
  kdenlive
  obs-studio
  shotwell
  vlc
  vlc-plugin-pipewire
  vlc-plugin-fluidsynth
  vlc-plugin-jack
  
  # Produtividade e Suíte de Escritório
  libreoffice
  libreoffice-help-pt-br
  libreoffice-lightproof-pt-br
  skrooge
  hunspell-pt-br
  aspell-pt-br
  hyphen-pt-br
  manpages-pt-br
  
  # Utilitários Diversos
  ansifilter-gui
  conky-manager2
  dupeguru
  fortunes
  fortunes-br
  freetuxtv
  gedit
)

# Instala a lista de pacotes APT (|| true garante a continuidade mesmo se um pacote falhar)
sudo apt install -y "${PACOTES_APT[@]}" || echo "Aviso: Alguns pacotes APT podem ter falhado na instalação."

echo "=== 6. Instalando aplicativos via Snap ==="

sudo systemctl enable --now snapd.socket

sudo snap install code --classic || true
sudo snap install sublime-text --classic || true
sudo snap install telegram-desktop || true
sudo snap install whatsapp-linux-app || true
sudo snap install youtube-music-desktop-app || true
sudo snap install shortwave || true

# Conectando permissões de áudio para o Shortwave
sudo snap connect shortwave:audio-record || true
sudo snap connect shortwave:audio-playback || true

echo "=== 7. Download e Instalação do Google Chrome (.deb oficial) ==="
wget -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb || true
rm -f /tmp/google-chrome-stable_current_amd64.deb

echo "=== 8. Limpeza e finalização ==="
sudo apt autoremove -y
sudo apt clean

echo "================================================="
echo " Processo de pós-instalação concluído!"
echo "================================================="
