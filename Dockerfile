# Gunakan image dasar Ubuntu 20.04
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update dan instalasi paket dasar
RUN apt-get update && apt-get install -y \
    openssh-server curl wget sudo gnupg ca-certificates apt-transport-https \
    && mkdir /var/run/sshd \
    && echo 'root:zyyafk' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/Port 22/Port 22/' /etc/ssh/sshd_config \
    && echo "AllowUsers root" >> /etc/ssh/sshd_config \
    && mkdir /root/.ssh

# Tambahkan repo Playit dan install
RUN curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/playit.gpg \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" > /etc/apt/sources.list.d/playit-cloud.list \
    && apt-get update \
    && apt-get install -y playit

# Tambahkan ulang repo Playit (jika warning muncul)
RUN apt-key del '16AC CC32 BD41 5DCC 6F00  D548 DA6C D75E C283 9680' || true \
    && rm -f /etc/apt/sources.list.d/playit-cloud.list \
    && apt-get update \
    && curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/playit.gpg \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" > /etc/apt/sources.list.d/playit-cloud.list \
    && apt-get update

# Bersihkan cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Ekspos port SSH
EXPOSE 22

# Jalankan SSH daemon
CMD ["/usr/sbin/sshd", "-D"]
