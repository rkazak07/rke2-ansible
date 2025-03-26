# file: Dockerfile-systemd-debian
FROM debian:bookworm

ENV container docker
ENV DEBIAN_FRONTEND noninteractive

# Systemd kurmak için gerekli paketler:
RUN apt-get update && apt-get install -y systemd systemd-sysv dbus python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# SSH server da ekleyelim
RUN apt-get update && apt-get install -y openssh-server \
    && mkdir /var/run/sshd

# Root parolasını test amaçlı ayarla
RUN echo 'root:123' | chpasswd
RUN sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# systemd ile container başlatmak için
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
