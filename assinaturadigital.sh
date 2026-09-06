#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação do Certificado Digital OAB / SafeSign - Kubuntu 26.04
# ==============================================================================

set -e

# Obter o usuário real (mesmo se executado com sudo)
USUARIO_REAL="${SUDO_USER:-$USER}"
DIRETORIO_DOWNLOADS="/home/${USUARIO_REAL}/Downloads"

echo "=== 1. Criando grupo scard e adicionando o usuário ==="
sudo groupadd -f scard
sudo usermod -aG scard "$USUARIO_REAL"

echo "=== 2. Instalando serviços de leitora e middleware nativos via APT ==="
sudo apt update
sudo apt install -y \
  libengine-pkcs11-openssl \
  libp11-3 \
  libpcsc-perl \
  libccid \
  pcsc-tools \
  opensc \
  openssl \
  libnss3-tools \
  pcscd \
  libc6 \
  libgcc-s1 \
  libgdbm-compat4 \
  libglib2.0-0 \
  libpcsclite1 \
  libssl3 \
  libstdc++6 \
  unzip \
  wget

echo "=== 3. Habilitando e iniciando o serviço de leitora de cartão ==="
sudo systemctl enable pcscd
sudo systemctl enable --now pcscd.socket pcscd.service

echo "=== 4. Download, Instalação e Limpeza do SafeSign 4.7.0.0 (ub2604) ==="

# Navega até a pasta Downloads
cd "$DIRETORIO_DOWNLOADS"

# URL e Nomes de Arquivo
URL_SAFESIGN="https://safesign.gdamericadosul.com.br/content/SafeSign%20IC%20Standard%20Linux%20ub2604%204.7.0.0-AET.000.zip"
ARQUIVO_ZIP="SafeSign_ub2604.zip"
PASTA_EXTRAIDA="safesign_temp"

# Download do arquivo compactado
echo "Baixando o SafeSign para Ubuntu 26.04..."
wget -O "$ARQUIVO_ZIP" "$URL_SAFESIGN"

# Descompactação
echo "Descompactando o instalador..."
unzip -q "$ARQUIVO_ZIP" -d "$PASTA_EXTRAIDA"

# Entra no diretório extraído e instala os pacotes .deb encontrados
cd "$PASTA_EXTRAIDA"
echo "Instalando o pacote SafeSign..."
sudo dpkg -i *.deb || sudo apt-get install -f -y

# Retorna ao diretório de Downloads
cd "$DIRETORIO_DOWNLOADS"

# Limpeza: remove arquivo ZIP e a pasta temporária
echo "Limpando arquivos temporários de instalação..."
rm -rf "$ARQUIVO_ZIP" "$PASTA_EXTRAIDA"

echo "=== 5. Registrando módulo PKCS#11 no Chrome, Chromium e Firefox ==="

MODULO_SAFESIGN="/usr/lib/libaetpkss.so"

if [ -f "$MODULO_SAFESIGN" ]; then

    # 1. Registro para Google Chrome / Chromium via NSS DB local do usuário
    HOME_REAL="/home/${USUARIO_REAL}"
    NSS_DB="${HOME_REAL}/.pki/nssdb"

    # Se a pasta .pki/nssdb não existir, cria e inicializa o banco de certificados
    if [ ! -d "$NSS_DB" ]; then
        mkdir -p "$NSS_DB"
        certutil -d sql:"$NSS_DB" -N --empty-password
        chown -R "${USUARIO_REAL}:${USUARIO_REAL}" "${HOME_REAL}/.pki"
    fi

    echo "Adicionando módulo SafeSign ao banco NSS do Chrome..."
    sudo -u "$USUARIO_REAL" modutil -dbdir sql:"$NSS_DB" -add "SafeSign PKCS11" -libfile "$MODULO_SAFESIGN" -force || true

    # 2. Configuração de Política Global do PKCS#11 para navegadores Chromium
    POLICY_DIR="/etc/chromium/policies/managed"
    PKCS11_CONF="/etc/pkcs11/modules/safesign.module"

    sudo mkdir -p /etc/pkcs11/modules
    echo "module: $MODULO_SAFESIGN" | sudo tee "$PKCS11_CONF" > /dev/null

fi

echo "=================================================================="
echo " Instalação do SafeSign OAB concluída com sucesso!"
echo " "
echo " IMPORTANTE PARA O GOOGLE CHROME:"
echo " O módulo foi vinculado em: $MODULO_SAFESIGN"
echo " "
echo " NOTA: Faça logout e login novamente para que o grupo 'scard'"
echo " e o serviço de leitora fiquem ativos no seu perfil."
echo "=================================================================="
