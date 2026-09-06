#!/bin/bash

# Resetar configurações anteriores
sudo ufw --force reset

# Políticas Padrão: Bloqueia tudo (Entrada e Saída)
sudo ufw default deny incoming
sudo ufw default deny outgoing

# --------------------------------------------------
# 1. TRÁFEGO LOCAL E SYSTEM SERVICES
# --------------------------------------------------
# Loopback (Essencial para funcionamento interno do sistema)
sudo ufw allow in on lo comment 'Loopback Entrada Local'
sudo ufw allow out on lo comment 'Loopback Saida Local'

# DHCP (Necessário para a placa de rede pegar IP com o Roteador)
sudo ufw allow out 67:68/udp comment 'DHCP Client Outbound'

# --------------------------------------------------
# 2. CONEXÃO COM A REDE LOCAL (Saída)
# --------------------------------------------------
# Permite ao seu PC acessar impressoras, roteadores e serviços da LAN
sudo ufw allow out to 192.168.0.0/16 comment 'Rede Local Saida 192.168.x.x'
sudo ufw allow out to 10.0.0.0/8 comment 'Rede Local Saida 10.x.x.x'
sudo ufw allow out to 172.16.0.0/12 comment 'Rede Local Saida 172.16-31.x.x'

# --------------------------------------------------
# 3. RESOLUÇÃO DE NOMES (DNS) E NAVEGAÇÃO WEB
# --------------------------------------------------
# DNS (Necessário para resolver nomes de domínio)
sudo ufw allow out 53 comment 'DNS Outbound'

# HTTP / HTTPS (Navegação geral, Tribunais, Peticionamento, Estudos)
sudo ufw allow out 80/tcp comment 'HTTP Outbound'
sudo ufw allow out 443/tcp comment 'HTTPS Outbound'

# --------------------------------------------------
# 4. VPN PROTON & WIREGUARD
# --------------------------------------------------
# Portas para estabelecer conexão com servidores Proton
sudo ufw allow out 51820/udp comment 'Proton WireGuard'
sudo ufw allow out 1194/udp comment 'Proton OpenVPN UDP'
sudo ufw allow out 8443/tcp comment 'Proton Stealth / Alt TCP'

# Liberar todo o tráfego gerado DENTRO do túnel da VPN (Interfaces WireGuard / OpenVPN)
sudo ufw allow out on wg+ comment 'Trafego via interfaces WireGuard'
sudo ufw allow out on tun+ comment 'Trafego via interfaces OpenVPN/Proton'

# --------------------------------------------------
# 5. TELEFONIA VOIP (Se utilizado)
# --------------------------------------------------
sudo ufw allow out 5060/udp comment 'VoIP SIP Standard'
sudo ufw allow out 5061/tcp comment 'VoIP SIP TLS'
sudo ufw allow out 10000:20000/udp comment 'VoIP RTP Audio Streams'

# --------------------------------------------------
# 6. REDE I2P (Exposição do Roteador i2pd na Wi-Fi)
# --------------------------------------------------
# Libera entrada específica na interface Wi-Fi (wlp1s0) para o roteador I2P
sudo ufw allow in on wlp1s0 to any port 28242 proto udp comment 'i2pd Router Inbound UDP'
sudo ufw allow in on wlp1s0 to any port 28242 proto tcp comment 'i2pd Router Inbound TCP'

# --------------------------------------------------
# 7. ATIVAÇÃO DO FIREWALL
# --------------------------------------------------
sudo ufw --force enable
sudo ufw status verbose
