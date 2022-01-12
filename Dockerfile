FROM amazonlinux:2

# copy the public key file to the /tmp directory of the Docker image
COPY ./id_rsa.pub /tmp/

# install amazon-linux-extras
RUN amazon-linux-extras install -y epel

# yum update & install
RUN yum -y update && \
    yum -y install \
        systemd \
        tar \
        unzip \
        sudo \
        git \
        which \
        wget \
        openssh-server \
        openssh-clients  \
        nginx && \
    yum clean all

# install aws cli v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install

# start sshd
RUN systemctl enable sshd.service && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

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

# install Google Authenticator
RUN yum -y install \
        google-authenticator \
        qrencode-libs

# sshd_config
RUN sed -i "/^ChallengeResponseAuthentication/d" /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config && \
    echo "Match User ec2-user" >> /etc/ssh/sshd_config && \
    echo "   AuthenticationMethods publickey" >> /etc/ssh/sshd_config && \
    echo "   PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# create /etc/pam.d/google-auth
RUN echo "#%PAM-1.0" > /etc/pam.d/google-auth && \
    echo "auth        required      pam_env.so" >> /etc/pam.d/google-auth && \
    echo "auth        sufficient    pam_google_authenticator.so nullok" >> /etc/pam.d/google-auth && \
    echo "auth        requisite     pam_succeed_if.so uid >= 500 quiet" >> /etc/pam.d/google-auth && \
    echo "auth        required      pam_deny.so" >> /etc/pam.d/google-auth && \
    chmod 644 /etc/pam.d/google-auth

# mod /etc/pam.d/sshd
RUN sed -i "s/.*substack/#&/g" /etc/pam.d/sshd && \
    sed -i "/substack/a auth       substack     google-auth" /etc/pam.d/sshd

# copy bash profile file
COPY ./google-authenticator.sh /etc/profile.d/
RUN chmod 644 /etc/profile.d/google-authenticator.sh

# restart sshd
CMD systemctl restart sshd.service
