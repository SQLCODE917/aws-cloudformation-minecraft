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
    local config_parameter_name="minecraft-server-$(get_parameter UUID)-config"
    echo "$(get_ssm_parameter "${config_parameter_name}")" | tee "${properties_path}" > /dev/null

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