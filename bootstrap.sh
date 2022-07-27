#!/bin/bash

source /usr/games/minecraft-environment

# Installs the Bedrock server software, downloads the distributable
# from its designated source if it's missing and unpacks it in the
# designated directory, adjusting ownerships to the correct user.
function install_bedrock_server() {
    local source_parameter_name="/minecraft-server/${STACK_UUID}/source"
    local source="$(get_ssm_parameter "${source_parameter_name}")"
    local distributable="$(basename "${source}")"
    local unversioned_filename="bedrock-server.zip"

    # Download the distributable from the source URL if it doesn't already exist locally.
    if [ -z "${source}" ]; then
        minecraft_log "Failed to determine distributable source URL"
        return 1
    fi
    if [ ! -f "${BEDROCK_ROOT_DIR}/${distributable}" ]; then
        minecraft_log "Downloading server software"
        wget "${source}" -O "${BEDROCK_ROOT_DIR}/${distributable}" -q && \
            ln -sf "${distributable}" "${BEDROCK_ROOT_DIR}/${unversioned_filename}"

        [ ${?} -eq 0 ] || return 2
    fi

    # Install or re-install the configured version package.
    minecraft_log "Unpacking server software"
    unzip -oq "${BEDROCK_ROOT_DIR}/${unversioned_filename}" -d "${BEDROCK_ROOT_DIR}" && \
        chown -Rf games:games "${BEDROCK_ROOT_DIR}"
}

# Sets the Bedrock server user permissions and whitelist as per
# the stack configuration.
function adjust_bedrock_access() {
    local whitelist_path="${BEDROCK_ROOT_DIR}/allowlist.json"
    local permissions_path="${BEDROCK_ROOT_DIR}/permissions.json"

    minecraft_log "Configuring server access"
    local whitelist_secret_name="/minecraft-server/${STACK_UUID}/whitelist"
    local permissions_secret_name="/minecraft-server/${STACK_UUID}/permissions"
    get_secret_value "${whitelist_secret_name}" | tee "${whitelist_path}" > /dev/null && \
        get_secret_value "${permissions_secret_name}" | tee "${permissions_path}" > /dev/null && \
        chown -f games:games "${whitelist_path}" "${permissions_path}" && \
        chmod 0664 "${whitelist_path}" "${permissions_path}"
}

# Constructs the server properties file from the stack configuration.
function adjust_bedrock_server_properties() {
    local properties_path="${BEDROCK_ROOT_DIR}/server.properties"

    minecraft_log "Configuring server properties"
    local config_parameter_name="/minecraft-server/${STACK_UUID}/properties"
    get_ssm_parameter "${config_parameter_name}" | tee "${properties_path}" > /dev/null && \
        chown -f games:games "${properties_path}" && \
        chmod 0664 "${properties_path}"
}

# Executes the custom startup script from a remote source, if it has been configured.
function execute_custom_startup_script() {
    local custom_script_secret_name="/minecraft-server/${STACK_UUID}/custom-script"
    local custom_startup_script_url="$(get_secret_value "${custom_script_secret_name}" | \
        sed -e 's/^"//' -e 's/"$//')"
    local old_pwd="$(pwd)"

    if [[ "${custom_startup_script_url}" =~ https?://.+ ]]; then
        minecraft_log "Executing custom startup script"
        cd "${BEDROCK_ROOT_DIR}"
        bash -c "$(curl -fsSL "${custom_startup_script_url}")"

        local success=${?}
        cd "${old_pwd}"

        if [ ${success} -ne 0 ]; then
            minecraft_log "Failed to execute custom startup script"
            return 5
        fi
    fi
}

# ---------------------------------------------------------------------------------------

minecraft_log "Bootstrapping Bedrock server at $(date)"
install_bedrock_server && \
    adjust_bedrock_access && \
    adjust_bedrock_server_properties && \
    execute_custom_startup_script && \
    minecraft_log "Bootstrapping complete at $(date)"

if [ ${?} -ne 0 ]; then
    minecraft_log "Bootstrapping failed at $(date)"
    exit 1
fi