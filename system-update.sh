#!/bin/bash

OLD_PWD="$(pwd)"
REPO_DIR="/usr/games/minecraft-repository"
GAMES_DIR="/usr/games"
BEDROCK_ROOT_DIR="/usr/games/minecraft"

# By default we'll just pull the latest scripts from the repository and run the
# second pass with the fresh version.
if [[ "${1}" != "second-pass" ]]; then

    cd "${REPO_DIR}" || exit 1
    git checkout main
    git pull
    ./system-update.sh "second-pass"

elif [[  ${#} -eq 1 && "${1}" == "second-pass" ]]; then

    install -C -o root -g root -m 0755 environment.sh "${GAMES_DIR}/minecraft-environment"
    install -C -o root -g root -m 0755 bootstrap.sh "${GAMES_DIR}/minecraft-bootstrap"
    install -C -o root -g root -m 0755 backup.sh "${GAMES_DIR}/minecraft-backup"
    install -C -o root -g root -m 0755 start.sh "${GAMES_DIR}/minecraft-start"
    install -C -o root -g root -m 0755 stop.sh "${GAMES_DIR}/minecraft-stop"
    install -C -o root -g root -m 0755 restore-worlds.sh "${GAMES_DIR}/minecraft-restore"

    install -C -o root -g root -m 0644 -D logrotate.conf /etc/logrotate.d/minecraft
    install -C -o root -g root -m 0644 -D minecraft.service /etc/systemd/system/minecraft.service
    install -C -o root -g root -m 0644 -D pre-shutdown.service /etc/systemd/system/pre-shutdown.service

    install -C -o root -g root -m 0755 -D keepalive-cron.sh /etc/cron.custom/minecraft-keepalive
    install -C -o root -g root -m 0644 -D crontab /etc/cron.d/minecraft

    grep -qP '^\s*LD_LIBRARY_PATH=.' /etc/environment || \
        echo "LD_LIBRARY_PATH=.:/snap/core22/current/lib/x86_64-linux-gnu/:/snap/core20/current/lib/x86_64-linux-gnu/" >> /etc/environment

else

    echo "unsupported arguments: ${*}"
    exit 2

fi

cd "${OLD_PWD}"
