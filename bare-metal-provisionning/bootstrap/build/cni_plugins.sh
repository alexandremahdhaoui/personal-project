#!/bin/bash

set -xe

CNI_PLUGINS_VERSION="v1.3.0"
ARCH="amd64"
DEST="/opt/cni/bin"
URL="https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz"

sudo mkdir -p "${DEST}"
curl -L "${URL}" | sudo tar -C "${DEST}" -xz
