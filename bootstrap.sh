#!/bin/bash

source /usr/games/minecraft-environment

# Installs the Bedrock server software, downloads the distributable
# from its designated source if it's missing and unpacks it in the
# designated directory, adjusting ownerships to the correct user.
function install_bedrock_server() {
    local source="$(get_parameter ServerSourceURL)"
    local distributable="$(basename ${source})"
    local unversioned_filename="bedrock-server.zip"

    # Download the distributable from the source URL if it doesn't already exist locally.
    if [ ! -f "${BEDROCK_ROOT_DIR}/${distributable}" ]; then
        minecraft_log "Downloading server software"
        wget "${source}" -O "${BEDROCK_ROOT_DIR}/${distributable}" -q
        ln -sf "${distributable}" "${BEDROCK_ROOT_DIR}/${unversioned_filename}"
    fi

    # Install or re-install the configured version package.
    minecraft_log "Unpacking server software"
    unzip -oq "${BEDROCK_ROOT_DIR}/${unversioned_filename}" -d "${BEDROCK_ROOT_DIR}"
    chown -Rf games:games "${BEDROCK_ROOT_DIR}"
}

# Sets the Bedrock server user permissions and whitelist as per
# the stack configuration.
function adjust_bedrock_access() {
    local whitelist="$(get_parameter WhitelistJSON)"
    local whitelist_path="${BEDROCK_ROOT_DIR}/allowlist.json"
    local permissions="$(get_parameter PermissionsJSON)"
    local permissions_path="${BEDROCK_ROOT_DIR}/permissions.json"

    minecraft_log "Configuring server access"
    echo "${whitelist}" | tee "${whitelist_path}" > /dev/null
    echo "${permissions}" | tee "${permissions_path}" > /dev/null
    chown -f games:games "${whitelist_path}" "${permissions_path}"
    chmod 0664 "${whitelist_path}" "${permissions_path}"
}

# Constructs the server properties file from the stack configuration.
function adjust_bedrock_server_properties() {
    local properties_path="${BEDROCK_ROOT_DIR}/server.properties"

    minecraft_log "Configuring server properties"
    cat << END_OF_SERVER_PROPERTIES | tee "${properties_path}" > /dev/null
server-name=$(get_parameter ServerName)
gamemode=$(get_parameter GameMode)
force-gamemode=$(get_parameter ForceGameMode)
difficulty=$(get_parameter Difficulty)
allow-cheats=$(get_parameter AllowCheats)
max-players=$(get_parameter MaximumPlayers)
online-mode=$(get_parameter OnlineMode)
allow-list=$(get_parameter WhitelistOnly)
server-port=$(get_parameter ServerPort)
server-portv6=$(get_parameter ServerPortIPv6)
view-distance=$(get_parameter ViewDistance)
tick-distance=$(get_parameter TickDistance)
player-idle-timeout=$(get_parameter PlayerIdleTimeout)
max-threads=$(get_parameter MaxThreads)
level-name=$(get_parameter LevelName)
level-seed=$(get_parameter LevelSeed)
default-player-permission-level=$(get_parameter DefaultPlayerPermissionLevel)
texturepack-required=$(get_parameter TexturepackRequired)
content-log-file-enabled=$(get_parameter ContentLogFileEnabled)
compression-threshold=$(get_parameter CompressionThreshold)
server-authoritative-movement=$(get_parameter ServerAuthoritativeMovement)
player-movement-score-threshold=$(get_parameter PlayerMovementScoreThreshold)
player-movement-action-direction-threshold=$(get_parameter PlayerMovementActionDirectionThreshold)
player-movement-distance-threshold=$(get_parameter PlayerMovementDistanceThreshold)
player-movement-duration-threshold-in-ms=$(get_parameter PlayerMovementDurationThreshold)
correct-player-movement=$(get_parameter CorrectPlayerMovement)
server-authoritative-block-breaking=$(get_parameter ServerAuthoritativeBlockBreaking)
END_OF_SERVER_PROPERTIES

    chown -f games:games "${properties_path}"
    chmod 0664 "${properties_path}"
}

# Executes the custom startup script from a remote source, if it has been configured.
function execute_custom_startup_script() {
    local custom_startup_script_url="$(get_parameter CustomStartupScriptURL)"
    local old_pwd="$(pwd)"

    if [[ "${custom_startup_script_url}" =~ https?://.+ ]]; then
        minecraft_log "Executing custom startup script"
        cd "${BEDROCK_ROOT_DIR}"
        bash -c "$(curl -fsSL "${custom_startup_script_url}")"
        cd "${old_pwd}"
    fi
}

# ---------------------------------------------------------------------------------------

minecraft_log "Bootstrapping Bedrock server at $(date)"
install_bedrock_server
adjust_bedrock_access
adjust_bedrock_server_properties
execute_custom_startup_script
minecraft_log "Bootstrapping complete at $(date)"