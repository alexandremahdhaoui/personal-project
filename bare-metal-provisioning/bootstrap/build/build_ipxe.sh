#!/bin/sh

set -xe

# DISCLAIMER: This script is intended to run inside an init-container, therefore cleanup's are skipped
# test: kubectl run fedora --image fedora:latest --command -- sleep 3600 && kubectl exec -it fedora -- bash

# url to webserver hosting the iPXE script
IPXE_CONFIG_URL="${1:-"10.0.0.3/ipxe/config"}"
# OUTPUT_DIR is an emptyDir volume is mounted to this specified path
OUTPUT_DIR="${2}"

# Prerequisites
dnf install -y git make gcc binutils perl xz mtools xz-devel

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

sed -i 's/#undef  DOWNLOAD_PROTO_HTTPS/#define DOWNLOAD_PROTO_HTTPS' ./config/general.h

# compile iPXE image
BIN=bin-x86_64-efi/ipxe.efi
make "${BIN}" EMBED="${IPXE_SCRIPT}" NO_WERROR=1
cp -f "${BIN}" "${OUTPUT_DIR}"
