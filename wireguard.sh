# 1. Instala o WireGuard e o gerenciador de DNS (resolvconf)
sudo apt update && sudo apt install -y wireguard resolvconf

# 2. Cria o diretório /etc/wireguard se ele ainda não existir
sudo mkdir -p /etc/wireguard

# 3. Copia o arquivo da pasta Downloads para /etc/wireguard
sudo cp /home/eduardo/Downloads/US17KJ24788.conf /etc/wireguard/US17KJ24788.conf

# 4. Ajusta as permissões de segurança do arquivo de configuração (somente root lê/escreve)
sudo chmod 600 /etc/wireguard/US17KJ24788.conf

# 5. Habilita o serviço wg-quick para iniciar automaticamente no boot do sistema
sudo systemctl enable wg-quick@US17KJ24788

# 6. Inicia a conexão WireGuard imediatamente
sudo systemctl start wg-quick@US17KJ24788
