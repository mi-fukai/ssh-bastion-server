FROM amazonlinux:2

# copy the public key file to the /tmp directory of the Docker image
COPY ./id_rsa.pub /tmp/

# install amazon-linux-extras
RUN amazon-linux-extras install -y epel

# yum update & install
RUN yum -y update && \
    yum -y install \
        shadow-utils \
        procps \
        systemd \
        net-tools \
        tar \
        unzip \
        sudo \
        git \
        which \
        wget \
        openssh-server \
        openssh-clients \
        openssl \
        openssl-libs \
        nginx && \
    yum clean all

RUN mkdir /var/run/sshd

# start sshd
RUN systemctl enable sshd.service && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# Self-signed certificate creation
RUN openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -subj /CN=localhost -keyout /etc/nginx/cert.key -out /etc/nginx/cert.crt

# start nginx
COPY ./default.conf /etc/nginx/conf.d/
RUN systemctl enable nginx.service

# create user
RUN useradd -m -d /home/ec2-user -s /bin/bash ec2-user && \
    echo "ec2-user ALL=NOPASSWD: ALL" >> /etc/sudoers && \
    sudo -u ec2-user mkdir -p /home/ec2-user/.ssh && \
    chmod 700 /home/ec2-user/.ssh && \
    mv /tmp/id_rsa.pub /home/ec2-user/.ssh/ && \
    cat /home/ec2-user/.ssh/id_rsa.pub >> /home/ec2-user/.ssh/authorized_keys && \
    chmod 600 /home/ec2-user/.ssh/authorized_keys && \
    chown ec2-user:ec2-user /home/ec2-user/.ssh/* && \
    echo "export LANG=en_US.UTF-8" >> /home/ec2-user/.bash_profile

# sshd_config
RUN sed -i "/^ChallengeResponseAuthentication/d" /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config && \
    echo "Match User ec2-user" >> /etc/ssh/sshd_config && \
    echo "   AuthenticationMethods publickey" >> /etc/ssh/sshd_config && \
    echo "   PubkeyAuthentication yes" >> /etc/ssh/sshd_config

WORKDIR /home/ec2-user

# install aws cli v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    sudo ln -s -f /usr/local/bin/aws /bin/aws

# exporse ports
EXPOSE 22
EXPOSE 80

# create host key
RUN ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t ecdsa -N "" -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key

# start services
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
CMD [ "/usr/bin/entrypoint.sh" ]
