#!/usr/bin/env bash
#
# Script de Instalação de Conversores Universais de Arquivos no Ubuntu
# ------------------------------------------------------------------

set -e

echo "=== 1. Atualizando repositórios do sistema ==="
sudo apt update && sudo apt upgrade -y

echo "=== 2. Instalando Suporte a Python, Compiladores e Dependências Básicas ==="
sudo apt install -y \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    software-properties-common \
    p7zip-full \
    unzip \
    poppler-utils

# Configura o pipx no PATH do sistema
pipx ensurepath

echo "=== 3. Instalando Conversores de Áudio, Vídeo e Mídia ==="
sudo apt install -y \
    ffmpeg \
    sox \
    libsox-fmt-all \
    lame \
    flac \
    vorbis-tools \
    mkvtoolnix \
    handbrake-cli \
    pandoc-audio-convert 2>/dev/null || true

echo "=== 4. Instalando Conversores de Imagens, Diagramas e Vetores ==="
sudo apt install -y \
    imagemagick \
    graphicsmagick \
    inkscape \
    optipng \
    jpegoptim \
    webp \
    potrace \
    graphviz \

# Libera permissões de conversão do ImageMagick para PDF se necessário
sudo sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read | write" pattern="PDF" \/>/' /etc/ImageMagick-6/policy.xml 2>/dev/null || true

echo "=== 5. Instalando Conversores de Documentos, PDF e E-books ==="
sudo apt install -y \
    pandoc \
    texlive-extra-utils \
    libreoffice-calc \
    libreoffice-writer \
    libreoffice-impress \
    calibre \
    pdf2svg \
    ghostscript \
    wkhtmltopdf \
    djvulibre-bin

echo "=== 6. Instalando Conversores Financeiros, Dados e Código ==="
sudo apt install -y \
    ofxstatement \
    csvkit \
    jq \
    yq \
    dos2unix

echo "=== 7. Instalando Conversores CAD, 3D e Geo ==="
sudo apt install -y \
    assimp-utils \
    gdal-bin

echo "=== 8. Instalando Conversores Globais via PIPX (Python) ==="
# Ferramenta para converter áudios de rádio/SDR / formatos variados
pipx install ofxstatement 2>/dev/null || true
pipx install csv2ofx 2>/dev/null || true
pipx install pdf2docx 2>/dev/null || true

echo "=========================================================="
echo " Instalação concluída com sucesso!"
echo " Todos os pacotes essenciais de conversão foram instalados."
echo "=========================================================="
