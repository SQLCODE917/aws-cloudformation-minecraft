#!/bin/bash

OLD_PWD="$(pwd)"
REPO_DIR="/usr/games/minecraft-repository"
GAMES_DIR="/usr/games"
BEDROCK_ROOT_DIR="/usr/games/minecraft"

cd "${REPO_DIR}" || exit 1
git checkout main
git pull

install -C -o root -g root -m 0755 environment.sh "${GAMES_DIR}/minecraft-environment"
install -C -o root -g root -m 0755 bootstrap.sh "${GAMES_DIR}/minecraft-bootstrap"
install -C -o root -g root -m 0755 backup.sh "${GAMES_DIR}/minecraft-backup"
install -C -o root -g root -m 0755 start.sh "${GAMES_DIR}/minecraft-start"
install -C -o root -g root -m 0755 stop.sh "${GAMES_DIR}/minecraft-stop"

install -C -o root -g root -m 0644 -D logrotate.conf /etc/logrotate.d/minecraft
install -C -o root -g root -m 0644 -D minecraft.service /etc/systemd/system/minecraft.service
install -C -o root -g root -m 0644 -D pre-shutdown.service /etc/systemd/system/pre-shutdown.service

grep -qP '^\s*LD_LIBRARY_PATH=.' /etc/environment || echo "LD_LIBRARY_PATH=." >> /etc/environment

cd "${OLD_PWD}"