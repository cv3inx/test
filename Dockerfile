# Gunakan image dasar Ubuntu 20.04
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update dan instalasi paket yang diperlukan
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo && \
    mkdir /var/run/sshd && \
    echo 'root:password123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/Port 22/Port 22/' /etc/ssh/sshd_config && \
    echo "AllowUsers root" >> /etc/ssh/sshd_config && \
    mkdir /root/.ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Ekspos port SSH 22
EXPOSE 22

# Jalankan SSH daemon
CMD ["/usr/sbin/sshd", "-D"]
