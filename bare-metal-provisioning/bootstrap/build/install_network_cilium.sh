#!/bin/bash

set -xe

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}"
sha256sum --check "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum"
sudo tar xzvfC "cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin"
rm -f "cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}"

CILIUM_VERSION=$(curl -sL https://raw.githubusercontent.com/cilium/cilium/main/stable.txt)
cilium install --version "${CILIUM_VERSION}"
