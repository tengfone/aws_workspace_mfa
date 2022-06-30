#!/bin/bash

# install SSM agent
sudo yum install -y https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# For packer SSH
PubkeyAcceptedKeyTypes=+ssh-rsa >>/etc/ssh/sshd_config
service ssh reload
