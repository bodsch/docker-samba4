#!/bin/bash

set -e

HADOLINT_VERSION='1.14.0'
HADOLINT_PATH='/usr/local/bin/hadolint'

if ! [[ -x "$(command -v hadolint)" ]]
then
  sudo curl \
    --silent \
    --location \
    --output "${HADOLINT_PATH}" \
    "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64"
  sudo chmod +x "${HADOLINT_PATH}"
fi

hadolint Dockerfile
# shellcheck rootfs/init/run.sh -x

