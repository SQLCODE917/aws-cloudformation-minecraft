#!/bin/bash

source /usr/games/minecraft-environment

function restore_minecraft_worlds() {
    # Always proceed when forced.
    if [[ "${1}" == "-f" || "${1}" == "--force" ]]; then
        local proceed="true"
    else
        # Otherwise proceed with restoration only when the level
        # doesn't exist.
        local level_name="$(get_server_property "level-name")"
        if [ -d "${BEDROCK_ROOT_DIR}/worlds/${level_name}" ]; then
            local proceed="false"
        else
            local proceed="true"
        fi
    fi

    if [ "${proceed}" == "true" ]; then
        minecraft_log "Restoring level: ${level_name}"

        local backup_filename="worlds.tar.bz2"
        local bucket_name="minecraft-${STACK_UUID}"
        
        rm -f "/tmp/${backup_filename}"
        aws s3 cp "s3://${bucket_name}/backups/${backup_filename}" "/tmp/${backup_filename}"
        tar -x -j -f "/tmp/${backup_filename}" -C "/tmp/"
        rm -f "/tmp/${backup_filename}"
        
        rm -Rf "${BEDROCK_ROOT_DIR}/worlds/${level_name}" && \
            mv "/tmp/worlds/${level_name}" "${BEDROCK_ROOT_DIR}/worlds/" && \
            rm -Rf "/tmp/worlds"
    else
        minecraft_log "Restoration skipped, level already exists."
    fi
}

# ---------------------------------------------------------------------------------------

minecraft_log "Restoring Minecraft worlds at $(date)"
restore_minecraft_worlds ${*}
minecraft_log "Restoration completed at $(date)"
