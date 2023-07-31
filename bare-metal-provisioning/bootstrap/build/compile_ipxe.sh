#!/bin/sh

set -xe

# DISCLAIMER: This script is intended to run inside an init-container, therefore cleanup's are skipped

# ip addr of the MetalConf server
METALCONF_IPXE_CONFIG_URL="${1}"
# OUTPUT_DIR is an emptyDir volume is mounted to this specified path
OUTPUT_DIR="${2}"

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
IPXE_SCRIPT="${WORKDIR}/script.ipxe"

# Create the script that will chain to METALCONF_IPXE_CONFIG_URL="metalconf.local/ipxe/config"
cat <<EOF | tee "${IPXE_SCRIPT}"
#!ipxe
dhcp
chain http://${METALCONF_IPXE_CONFIG_URL}
EOF

# clone repo
git clone https://github.com/ipxe/ipxe.git
cd ipxe/src || exit 1

# compile iPXE image
BIN=bin-x86_64-efi/ipxe.efi
make "${BIN}" EMBED="${IPXE_SCRIPT}" NO_WERROR=1
cp -f "${BIN}" "${OUTPUT_DIR}"

####
