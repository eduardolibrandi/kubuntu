#!/bin/bash

sudo ufw --force reset

# Políticas padrão: Bloqueia tudo na entrada e na saída
sudo ufw default deny incoming
sudo ufw default deny outgoing

# --------------------------------------------------
# TRÁFEGO LOCAL E LOOPBACK
# --------------------------------------------------
sudo ufw allow in on lo comment 'Loopback Entrada Local'
sudo ufw allow out on lo comment 'Loopback Saida Local'

# Permite tráfego com a rede local (Roteador, VoIP, TV, Impressoras)
sudo ufw allow in from 192.168.0.0/16 comment 'Rede Local IPv4'
sudo ufw allow in from 10.0.0.0/8 comment 'Rede Local IPv4'
sudo ufw allow in from 172.16.0.0/12 comment 'Rede Local IPv4'

sudo ufw allow out to 192.168.0.0/16 comment 'Rede Local Saida IPv4'
sudo ufw allow out to 10.0.0.0/8 comment 'Rede Local Saida IPv4'
sudo ufw allow out to 172.16.0.0/12 comment 'Rede Local Saida IPv4'

# --------------------------------------------------
# ESTABELECIMENTO DE VPN E REDE EXTERNA
# --------------------------------------------------
# DNS (Necessário para resolver nomes de domínio antes da VPN conectar)
sudo ufw allow out 53 comment 'DNS Outbound'

# Web Padrão (HTTP / HTTPS para sites, nuvens, tribunais e peticionamento)
sudo ufw allow out 80/tcp comment 'HTTP Outbound'
sudo ufw allow allow out 443/tcp comment 'HTTPS / Cloud / Tribunais'

# Proton VPN (WireGuard e OpenVPN)
sudo ufw allow out 51820/udp comment 'Proton WireGuard'
sudo ufw allow out 1194/udp comment 'Proton OpenVPN UDP'
sudo ufw allow out 8443/tcp comment 'Proton Stealth'

# --------------------------------------------------
# INTERFACE DO WIREGUARD (Liberar tráfego dentro da VPN)
# --------------------------------------------------
# Permite qualquer saída através da interface túnel da VPN (ex: wg+ ou US17KJ24788)
sudo ufw allow out on US17KJ24788 comment 'Trafego seguro via WireGuard'
sudo ufw allow out on wg+ comment 'Trafego seguro via interfaces WireGuard'

# --------------------------------------------------
# TELEFONIA VOIP (Sinalização e Voz)
# --------------------------------------------------
sudo ufw allow out 5060/udp comment 'VoIP SIP Standard'
sudo ufw allow out 5061/tcp comment 'VoIP SIP TLS'
sudo ufw allow out 10000:20000/udp comment 'VoIP RTP Audio Streams'

# --------------------------------------------------
# BANCOS (Warsaw Core Services)
# --------------------------------------------------
sudo ufw allow out 2080/tcp comment 'Warsaw Direct Core'
sudo ufw allow out 2095/tcp comment 'Warsaw Direct Sec'
sudo ufw allow out 20858/tcp comment 'Warsaw Core Service'
sudo ufw allow out 20958/tcp comment 'Warsaw Core Service Alt'

# --------------------------------------------------
# REDE I2P (Rede Privada)
# --------------------------------------------------
sudo ufw allow in on wlp1s0 to any port 28242 proto udp comment 'i2pd Router Inbound UDP'
sudo ufw allow in on wlp1s0 to any port 28242 proto tcp comment 'i2pd Router Inbound TCP'

# Ativa o UFW
sudo ufw --force enable
sudo ufw status verbose
