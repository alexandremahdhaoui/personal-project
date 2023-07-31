#!/bin/sh

set -xe

# DISCLAIMER: This script is intended to run inside an init-container, therefore cleanup's are skipped

METAL_CONF_IP="${1}"

# OUTPUT_DIR already exist: an emptyDir volume is mounted to that path
OUTPUT_DIR="/build"

# Prerequisites
dnf install -y git make gcc binutils perl xz mtools

#### build iPXE binary w/ embedded script
# Run:
#   k run fedora --image fedora:latest --command -- sleep 3600
#   k exec -it fedora -- bash
# prepare workdir
WORKDIR="/tmp/workdir"
mkdir "${WORKDIR}"
cd "${WORKDIR}" || exit 1
# create embedded script
SCRIPT_PATH="${WORKDIR}/script.ipxe"
cat <<EOF | tee "${SCRIPT_PATH}"
#!ipxe
dhcp
chain http://${METAL_CONF_IP}
EOF
# clone repo
git clone https://github.com/ipxe/ipxe.git
cd ipxe/src || exit 1
# compile iPXE image
BIN=bin-x86_64-efi/ipxe.efi
make "${BIN}" EMBED="${SCRIPT_PATH}" NO_WERROR=1
cp -f "${BIN}" "${OUTPUT_DIR}"
####
