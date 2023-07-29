#!/bin/bash

set -xe

ARCH="amd64"
CRICTL_VERSION="v1.27.1"
DOWNLOAD_DIR="/usr/local/bin"
URL="https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"

curl -L "${URL}" | sudo tar -C "${DOWNLOAD_DIR}" -xz
