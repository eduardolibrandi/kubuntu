#!/bin/bash

DIR_QR="/home/eduardo/Bluetooth"

# 1. Verifica se a dependência zbarimg está instalada; se não estiver, instala
if ! command -v zbarimg &>/dev/null; then
    echo "Instalando zbar-tools para leitura de QR Code..."
    sudo apt update && sudo apt install -y zbar-tools
fi

if [ ! -d "$DIR_QR" ]; then
    echo "Diretório $DIR_QR não encontrado!"
    exit 1
fi

echo "Iniciando varredura de QR Codes em $DIR_QR..."

# Habilita suporte a padrões sem correspondência não gerarem erros
shopt -s nullglob

# Itera sobre arquivos de imagem
for img in "$DIR_QR"/*.{png,jpg,jpeg,PNG,JPG,JPEG}; do
    [ -e "$img" ] || continue
    
    # Decodifica o conteúdo do QR Code
    RAW_DATA=$(zbarimg --raw -q "$img" 2>/dev/null)
    
    if [[ "$RAW_DATA" =~ WIFI: ]]; then
        # Extrai o SSID e a Senha da string do QR Code
        SSID=$(echo "$RAW_DATA" | sed -n 's/.*S:\([^;]*\);.*/\1/p')
        PASSWORD=$(echo "$RAW_DATA" | sed -n 's/.*P:\([^;]*\);.*/\1/p')
        
        if [ -n "$SSID" ]; then
            # Checa se o SSID já existe tratando a busca como texto literal (-F)
            EXISTING=$(nmcli -g NAME connection show | grep -xF "$SSID")
            
            if [ -n "$EXISTING" ]; then
                echo "[IGNORADO] A rede '$SSID' já está cadastrada no sistema."
            else
                echo "[ADICIONANDO] Importando a rede Wi-Fi '$SSID'..."
                if [ -n "$PASSWORD" ]; then
                    nmcli dev wifi connect "$SSID" password "$PASSWORD" --no-ask 2>/dev/null || \
                    nmcli connection add type wifi con-name "$SSID" ssid "$SSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PASSWORD"
                else
                    nmcli connection add type wifi con-name "$SSID" ssid "$SSID"
                fi
            fi
        fi
    fi
done

# Restaura o comportamento padrão
shopt -u nullglob

echo "Processamento concluído!"
