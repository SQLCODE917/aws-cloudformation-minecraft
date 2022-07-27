#!/bin/bash

echo "Server shutdown at $(date)" >> /usr/games/minecraft.log

function server_is_up {
    pidof "bedrock_server" &> /dev/null || return 1
    return 0
}

sudo -u games -g games -- screen -S minecraft -p 0 -X stuff "stop^M"

for (( i = 0 ; i < 300 ; i++ )); do
    server_is_up || break
    sleep 0.1
done

SERVER_PID=$(pidof "bedrock_server")
if [[ ${SERVER_PID} -gt 1 ]]; then
    kill -9 ${SERVER_PID}
fi

/usr/games/minecraft-backup