#!/bin/bash

# DISCLAIMER: this operation is not automated and must be run

# https://ipxe.org/howto/chainloading
# https://ipxe.org/appnote/uefihttp



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
rm -rf "${WORKDIR}"
####
