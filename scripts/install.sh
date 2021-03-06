#!/bin/bash
set -x

TERRAFORM_VERSION="0.9.5"
PACKER_VERSION="1.1.0"
# create new ssh key
[[ ! -f /home/ubuntu/.ssh/mykey ]] \
&& mkdir -p /home/ubuntu/.ssh \
&& ssh-keygen -f /home/ubuntu/.ssh/mykey -N '' \
&& chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# install docker
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
apt-get update
apt-get install -y docker-engine
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# install packages
apt-get -y install git unzip jq make

# Prevent clock skew when working with AWS.
# https://stackoverflow.com/questions/4770635/
#   s3-error-the-difference-between-the-request-time-and-the-current-time-is-too-la
apt-get install -y ntp
sed -i 's/pool 0.ubuntu/server 0.amazon/g' /etc/ntp.conf
sed -i 's/pool 1.ubuntu/server 1.amazon/g' /etc/ntp.conf
sed -i 's/pool 2.ubuntu/server 2.amazon/g' /etc/ntp.conf
sed -i 's/pool 3.ubuntu/server 3.amazon/g' /etc/ntp.conf

# Docker compose
curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Python 3.
apt-get install -y python3 python3-dev python3-pip
pip3 install --upgrade pip
pip3 install --upgrade virtualenv

# install awscli and ebcli
pip install -U awscli
pip install -U awsebcli

#terraform
T_VERSION=$(terraform -v | head -1 | cut -d ' ' -f 2 | tail -c +2)
T_RETVAL=${PIPESTATUS[0]}

[[ $T_VERSION != $TERRAFORM_VERSION ]] || [[ $T_RETVAL != 0 ]] \
&& wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# packer
P_VERSION=$(packer -v)
P_RETVAL=$?

[[ $P_VERSION != $PACKER_VERSION ]] || [[ $P_RETVAL != 1 ]] \
&& wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
&& unzip -o packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm packer_${PACKER_VERSION}_linux_amd64.zip

# clean up
apt-get clean
