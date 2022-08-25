#!/bin/bash

apt-get -y update && apt-get -y dist-upgrade
apt-get -y install awscli curl jq openssl screen unzip wget
snap install core20
snap install core22

mkdir -p /usr/games/minecraft /usr/games/minecraft-repository

OLD_PWD="$(pwd)"
cd /usr/games/minecraft-repository

git status &> /dev/null || git clone https://github.com/Finntaur/aws-cloudformation-minecraft.git .
./system-update.sh
./restore-worlds.sh

cd "${OLD_PWD}"

systemctl restart minecraft
systemctl enable minecraft
systemctl enable pre-shutdown
