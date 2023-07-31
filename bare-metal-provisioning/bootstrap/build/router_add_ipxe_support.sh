#!/bin/bash

# https://ipxe.org/howto/chainloading
# https://ipxe.org/appnote/uefihttp


#### build iPXE binary w/ embedded script
# prepare workdir
WORKDIR="/tmp/workdir"
mkdir "${WORKDIR}"
cd "${WORKDIR}" || exit 1
# install dependencies
opkg install git
# create embedded script
SCRIPT_PATH="${WORKDIR}/script.ipxe"
cat <<EOF | tee "${SCRIPT_PATH}"
#!ipxe
dhcp
chain http://ipxe.local
EOF
# clone repo
git clone https://github.com/ipxe/ipxe.git
cd ipxe/src || exit 1
# compile iPXE image
make bin-x86_64-efi/ipxe.efi EMBED="${SCRIPT_PATH}"
####

#### setup dnsmasq as a tftp server & make it pxe ready
# prepare tftp root dir
TFTP_ROOT="/var/lib/tftp"
# create tftp root folder
mkdir -p "/var/lib/${TFTP_ROOT}"
# download image
curl http://boot.ipxe.org/ipxe.efi -o "${TFTP_ROOT}/ipxe.efi"
# update config
cat <<EOF | tee /etc/dnsmasq.conf
dhcp-option-force=66,0.0.0.0
dhcp-option-force=67,ipxe.efi
enable-tftp
tftp-root=${TFTP_ROOT}
dhcp-boot=ipxe.efi
EOF
# restart dnsmasq
service dnsmasq restart
####

####
# Cleanup
opkg remove git
rm -rf "${WORKDIR}"
####
