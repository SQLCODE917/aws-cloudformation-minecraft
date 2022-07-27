#!/bin/bash

apt-get -y update && apt-get -y upgrade
apt-get -y install awscli curl jq openssl screen unzip wget
mkdir -p /usr/games/minecraft /usr/games/minecraft-repository

OLD_PWD="$(pwd)"
cd /usr/games/minecraft-repository

git status &> /dev/null || git clone https://github.com/Finntaur/aws-cloudformation-minecraft.git .
./system-update.sh

cd "${OLD_PWD}"

systemctl restart minecraft
systemctl enable minecraft
systemctl enable pre-shutdown
