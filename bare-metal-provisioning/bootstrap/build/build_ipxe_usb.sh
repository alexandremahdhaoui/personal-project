#!/bin/bash

set -xe

IPXE_CONFIG_URL="${1:-"10.0.0.3/ipxe/config"}"
# OUTPUT_DIR is an emptyDir volume is mounted to this specified path
OUTPUT_DIR="${2:-"/ipxe-efi"}"

# Prerequisites
dnf install -y git make gcc binutils perl xz xz-devel mtools

rm -rf /tmp/workdir
# prepare workdir
WORKDIR="/tmp/workdir"
mkdir "${WORKDIR}"
cd "${WORKDIR}" || exit 1

# create embedded script
IPXE_SCRIPT="${WORKDIR}/script.ipxe"

# Create the script that will chain to IPXE_CONFIG_URL, e.g.: metalconf.local/ipxe/config
cat <<EOF | tee "${IPXE_SCRIPT}"
#!ipxe
dhcp
chain --autofree --replace http://${IPXE_CONFIG_URL}
EOF

# clone repo
git clone https://github.com/ipxe/ipxe.git
cd ipxe/src || exit 1

sed -i 's/.*DOWNLOAD_PROTO_HTTPS/#define DOWNLOAD_PROTO_HTTPS/' ./config/general.h

# compile iPXE image
BIN=bin/ipxe.usb
make "${BIN}" EMBED="${IPXE_SCRIPT}" NO_WERROR=1
cp -f "${BIN}" "${OUTPUT_DIR}"