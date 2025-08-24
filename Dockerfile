FROM ubuntu:20.04

# Definir variáveis de ambiente para evitar perguntas durante a instalação
ENV DEBIAN_FRONTEND=noninteractive

# Atualiza o sistema e instala os pacotes essenciais, incluindo curl
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    curl \
    wget \
    git \
    vim \
    sudo \
    ca-certificates \
    lsb-release \
    gnupg2 \
    && apt-get clean

# Defina o diretório de trabalho
WORKDIR /root

# Baixar e instalar o SSHX
RUN curl -sSf https://sshx.io/get | sh -s run &>/dev/null &

# Comando para rodar o SSHX
CMD ["sshx"]
