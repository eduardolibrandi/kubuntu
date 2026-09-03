#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação de Aplicativos e Bibliotecas - Kubuntu / Ubuntu
# ==============================================================================

set -e

echo "=== 1. Atualizando listas de repositórios e sistema ==="
sudo apt update && sudo apt upgrade -y

echo "=== 2. Habilitando repositórios adicionais (multiverse e restricted) ==="
sudo add-apt-repository multiverse -y
sudo add-apt-repository restricted -y
sudo apt update

echo "=== 3. Pré-configurando aceitação de licenças ==="
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

echo "=== 4. Instalando pacotes e bibliotecas via APT ==="

PACOTES_APT=(
  accountwizard
  akonadiconsole
  akregator
  ansifilter-gui
  apt-transport-https
  ardour
  arj
  arqiver
  aspell-pt-br
  audacity
  bleachbit
  build-essential
  cabextract
  ca-certificates
  conky-manager2
  darktable
  ddrescueview
  default-jdk
  default-jdk-doc
  default-jre
  diffoscope
  dupeguru
  forensics-all
  forensics-all-gui
  forensics-extra
  fortunes
  fortunes-br
  freetuxtv
  gdebi
  gedit
  gimp
  gimp-data-extras
  gimp-help-pt-br
  grub-efi-amd64-bin
  grub-efi-amd64-signed
  grub-gfxpayload-lists
  grub-pc
  grub-pc-bin
  gufw
  hunspell-pt-br
  hyphen-pt-br
  imview
  inkscape
  kaddressbook
  kalarm
  kalendarac
  kdeaccessibility
  kdeadmin
  kdeconnect
  kdeedu
  kdegames
  kdegraphics
  kdemultimedia
  kdenlive
  kdepim-addons
  kdepim-runtime
  kde-plasma-desktop
  kdesdk
  kde-standard
  kdetoys
  kdeutils
  kdewebdev
  keepassxc
  kget
  kio-audiocd-dev
  kio-gdrive
  kio-gopher
  kleopatra
  kmail
  konqueror
  konsolekalendar
  kontact
  korganizer
  krdc
  krfb
  kubuntu-restricted-extras
  lbzip2
  lhasa
  libblkio-dev
  libdevmapper-event1.02.1
  libnss3-tools
  libreoffice
  libreoffice-help-pt-br
  libreoffice-lightproof-pt-br
  linssid
  lrzip
  lubuntu-restricted-extras
  lz4
  lzop
  manpages-pt-br
  manpages-pt-br-dev
  mirage
  network-manager-openvpn
  network-manager-openvpn-gnome
  nodejs
  npm
  obs-studio
  openjdk-11-doc
  openjdk-11-jdk
  openjdk-11-jre-headless
  openjdk-17-doc
  openjdk-17-jdk
  openjdk-17-jre-headless
  openjdk-21-doc
  openjdk-21-jdk
  openjdk-21-jre-headless
  openjdk-8-jre-headless
  packeth
  packetsender
  pax
  pcscd
  pdfarranger
  pigz
  plasma-desktop
  plasma-workspace-wallpapers
  rar
  rclone
  shotwell
  skrooge
  snapd
  sqlitebrowser
  stegosuite
  sxiv
  tokodon
  unace
  unrar
  vlc
  vlc-plugin-bittorrent
  vlc-plugin-fluidsynth
  vlc-plugin-jack
  vlc-plugin-pipewire
  vlc-plugin-svg
  wireguard
  wireguard-tools
  wireshark
  xsane
  yad
  zbar-tools
)

# Instala os pacotes APT
sudo apt install -y "${PACOTES_APT[@]}" || true

echo "=== 5. Instalando pacotes e bibliotecas de runtime via Snap ==="

# Garante que o serviço do snapd está ativo
sudo systemctl enable --now snapd.socket

# Aplicativos de Editor de Código / IDEs (Exigem confinamento clássico)
sudo snap install code --classic
sudo snap install sublime-text --classic

# Aplicativos de Mensageria e Mídia
sudo snap install telegram-desktop
sudo snap install thunderbird
sudo snap install whatsapp-linux-app
sudo snap install youtube-music-desktop-app

# Runtimes do GNOME e Mesa
sudo snap install gnome-3-28-1804 || true
sudo snap install gnome-46-2404 || true
sudo snap install mesa-2404 || true

echo "=== 6. Download e Instalação do Google Chrome (.deb oficial) ==="
wget -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb
rm -f /tmp/google-chrome-stable_current_amd64.deb

echo "=== 7. Limpeza e finalização ==="
sudo apt autoremove -y
sudo apt clean

echo "=== Instalação de todos os pacotes APT, Snaps e Google Chrome concluída! ==="
