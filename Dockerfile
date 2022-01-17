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
        openssh-clients && \
    yum clean all

# install nginx
RUN amazon-linux-extras install nginx1

# automatic start
ENTRYPOINT /usr/sbin/nginx -g "daemon off;"

# install aws cli v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install

# start sshd
RUN systemctl enable sshd.service && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# create user
RUN useradd -m -d /home/fukai-test -s /bin/bash fukai-test && \
    echo "fukai-test ALL=NOPASSWD: ALL" >> /etc/sudoers && \
    sudo -u fukai-test mkdir -p /home/fukai-test/.ssh && \
    chmod 700 /home/fukai-test/.ssh && \
    mv /tmp/id_rsa.pub /home/fukai-test/.ssh/ && \
    cat /home/fukai-test/.ssh/id_rsa.pub >> /home/fukai-test/.ssh/authorized_keys && \
    chmod 600 /home/fukai-test/.ssh/authorized_keys && \
    chown fukai-test:fukai-test /home/fukai-test/.ssh/* && \ 
    echo "export LANG=en_US.UTF-8" >> /home/fukai-test/.bash_profile

# sshd_config
RUN sed -i "/^ChallengeResponseAuthentication/d" /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config && \
    echo "Match User fukai-test" >> /etc/ssh/sshd_config && \
    echo "   AuthenticationMethods publickey" >> /etc/ssh/sshd_config && \
    echo "   PubkeyAuthentication yes" >> /etc/ssh/sshd_config

CMD ["/sbin/init"]
