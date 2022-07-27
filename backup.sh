#!/bin/bash

source /usr/games/minecraft-environment

function backup_minecraft_worlds() {
    local backup_filename="/tmp/worlds.tar.bz2"
    local bucket_name="minecraft-${STACK_UUID}"

    rm -f "${backup_filename}"
    tar -c -j -f "${backup_filename}" -C "${BEDROCK_ROOT_DIR}" worlds
    aws s3 cp "${backup_filename}" "s3://${bucket_name}/backups/" && rm -f "${backup_filename}"
}

# ---------------------------------------------------------------------------------------

minecraft_log "Backing up Minecraft worlds at $(date)"
backup_minecraft_worlds
minecraft_log "Backups completed at $(date)"