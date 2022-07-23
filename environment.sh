#!/bin/bash

LOG_FILE="/usr/games/minecraft.log"

function minecraft_log() {
    echo "${*}" | tee -a "${LOG_FILE}" > /dev/null
}

minecraft_log "Initializing Bedrock server environment at $(date)"

# ---------------------------------------------------------------------------------------

INSTANCE_ID="$(curl "http://169.254.169.254/latest/meta-data/instance-id")"

minecraft_log "Fetching instance details"
STACK_NAME="$(aws ec2 describe-tags --filters \
    "Name=resource-id,Values=${INSTANCE_ID}" \
    "Name=key,Values=aws:cloudformation:stack-name" \
    "Name=resource-type,Values=instance" --query 'Tags[0].Value' --output text)"

minecraft_log "Reading configuration parameters"
PARAMETERS="$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" \
    --output text --query 'Stacks[0].Parameters')"

BEDROCK_ROOT_DIR="/usr/games/minecraft"

# ---------------------------------------------------------------------------------------

# Extracts the raw value for the single given parameter from the entire
# list of parameters configured for the current CloudFormation stack.
function get_parameter() {
    echo "${PARAMETERS}" | jq --raw-output '.[] | select(.ParameterKey=="'"${1}"'") | .ParameterValue'
}

minecraft_log "Environment initialization complete at $(date)"