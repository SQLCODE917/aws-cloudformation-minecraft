#!/bin/bash

systemctl is-system-running &> /dev/null
if [ ${?} -eq 0 ]; then
    pidof bedrock_server &> /dev/null || systemctl restart minecraft
fi
