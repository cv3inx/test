FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

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

WORKDIR /root

# Jalankan SSHX via shell
CMD ["sh", "-c", "curl -sSf https://sshx.io/get | sh"]
