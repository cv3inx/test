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

# Install SSHX sekali saat build
RUN curl -sSf https://sshx.io/get | sh

# Jalankan SSHX saat container start
CMD ["/usr/local/bin/sshx"]
