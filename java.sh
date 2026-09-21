#!/bin/bash

set -e # Para a execução do script se algum comando falhar

# Cria o arquivo de preferências, se ele não existir

# Para o Java

# Método 1: Instala o JRE padrão (geralmente a versão mais recente estável)

sudo apt install -y default-jre

# Método 2: Instala versões específicas do OpenJDK JRE (escolha as que você precisa)
# Você pode descomentar e ajustar as linhas abaixo conforme sua necessidade.
# Certifique-se de ter apenas UM bloco de instalação de Java ativo.

sudo apt install -y openjdk-8-jre-headless  # version 8u422-b05-1ubuntu1
sudo apt install -y openjdk-11-jre-headless # version 11.0.25~5ea-1ubuntu1
sudo apt install -y openjdk-17-jre-headless # version 17.0.12+7-2
sudo apt install -y openjdk-17-crac-jre-headless # version 17.0.13+0-0ubuntu2
sudo apt install -y openjdk-21-jre-headless # version 21.0.5~8ea-1
sudo apt install -y openjdk-21-crac-jre-headless # version 21.0.5+0-0ubuntu2
sudo apt install -y openjdk-22-jre-headless # version 22.0.2+9-4
sudo apt install -y openjdk-23-jre-headless # version 23+37-1
sudo apt install -y openjdk-24-jre-headless # version 24~16ea-1

# Instalação de JDKs

# Método 1: Instala o JDK padrão (geralmente a versão mais recente estável)

sudo apt-get install -y default-jdk default-jdk-doc

# Método 2: Instala uma versão específica do OpenJDK (ex: OpenJDK 21)

sudo apt-get install -y openjdk-21-jdk openjdk-21-doc

# Método 3: Instala uma versão específica do OpenJDK (ex: OpenJDK 17)

sudo apt-get install -y openjdk-17-jdk openjdk-17-doc

# Método 4: Instala uma versão específica do OpenJDK (ex: OpenJDK 11)

sudo apt-get install -y openjdk-11-jdk openjdk-11-doc

# Adicional (opcional, mas recomendado): Instala o jtreg (ferramenta de teste)
sudo apt-get install -y jtreg

# Adicional (opcional): Instala o libasmtools-java (ferramenta para trabalhar com bytecode Java)

sudo apt-get install -y libasmtools-java -y
sudo apt-get install openjdk-17-demo openjdk-17-source visualvm -y

# Primeira limpeza

sudo apt-get autoremove -y
sudo apt-get autoclean

