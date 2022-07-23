#!/bin/bash

LOG_FILE="/usr/games/minecraft.log"

function bootstrap_log() {
    echo "${*}" | tee -a "${LOG_FILE}" > /dev/null
}

bootstrap_log "Bootstrapping Bedrock server at $(date)"

# ---------------------------------------------------------------------------------------

INSTANCE_ID="$(curl "http://169.254.169.254/latest/meta-data/instance-id")"

bootstrap_log "Fetching instance details"
STACK_NAME="$(aws ec2 describe-tags --filters \
    "Name=resource-id,Values=${INSTANCE_ID}" \
    "Name=key,Values=aws:cloudformation:stack-name" \
    "Name=resource-type,Values=instance" --query 'Tags[0].Value' --output text)"

bootstrap_log "Reading configuration parameters"
PARAMETERS="$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" \
    --output text --query 'Stacks[0].Parameters')"

BEDROCK_ROOT_DIR="/usr/games/minecraft"

# ---------------------------------------------------------------------------------------

# Extracts the raw value for the single given parameter from the entire
# list of parameters configured for the current CloudFormation stack.
function get_parameter() {
    echo "${PARAMETERS}" | jq --raw-output '.[] | select(.ParameterKey=="'"${1}"'") | .ParameterValue'
}

# Installs the Bedrock server software, downloads the distributable
# from its designated source if it's missing and unpacks it in the
# designated directory, adjusting ownerships to the correct user.
function install_bedrock_server() {
    local source="$(get_parameter ServerSourceURL)"
    local distributable="$(basename ${source})"
    local unversioned_filename="bedrock-server.zip"

    # Download the distributable from the source URL if it doesn't already exist locally.
    if [ ! -f "${BEDROCK_ROOT_DIR}/${distributable}" ]; then
        bootstrap_log "Downloading server software"
        wget "${source}" -O "${BEDROCK_ROOT_DIR}/${distributable}" -q
        ln -sf "${distributable}" "${BEDROCK_ROOT_DIR}/${unversioned_filename}"
    fi

    # Install or re-install the configured version package.
    bootstrap_log "Unpacking server software"
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

    bootstrap_log "Configuring server access"
    echo "${whitelist}" | tee "${whitelist_path}" > /dev/null
    echo "${permissions}" | tee "${permissions_path}" > /dev/null
    chown -f games:games "${whitelist_path}" "${permissions_path}"
}

# Constructs the server properties file from the stack configuration.
function adjust_bedrock_server_properties() {
    local properties_path="${BEDROCK_ROOT_DIR}/server.properties"

    bootstrap_log "Configuring server properties"
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
}

# ---------------------------------------------------------------------------------------

install_bedrock_server
adjust_bedrock_access
adjust_bedrock_server_properties
bootstrap_log "Bootstrapping complete at $(date)"