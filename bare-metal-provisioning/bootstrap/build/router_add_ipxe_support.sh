#!/bin/ash

# DISCLAIMER: this operation is not automated and must be run

# https://ipxe.org/howto/chainloading
# https://ipxe.org/appnote/uefihttp

METALCONF_IPXE_EFI_URL="${1:-10.0.0.3}"

#### setup dnsmasq as a tftp server & make it pxe ready
# prepare tftp root dir
TFTP_ROOT="/var/lib/tftp"
IPXE_EFI_FILENAME="ipxe.efi"
CONFIG="\ \toption enable_tftp \'1\'\n\toption tftp_root '${METALCONF_IPXE_EFI_URL}'\n\toption dhcp-boot '${IPXE_EFI_FILENAME}'"

# create tftp root folder
mkdir -p "/var/lib/${TFTP_ROOT}"
# download image
curl "http://${METALCONF_IPXE_EFI_URL}" -o "${TFTP_ROOT}/${IPXE_EFI_FILENAME}"
# update config
sed "/^config dnsmasq/a ${CONFIG}" /etc/config/dhcp

sudo service dnsmasq restart

# cat <<EOF | tee -a /etc/dnsmasq.conf
# #dhcp-option-force=66,0.0.0.0
# #dhcp-option-force=67,ipxe.efi
# enable-tftp
# tftp-root=${TFTP_ROOT}
# dhcp-boot=${IPXE_EFI_FILENAME}
# EOF
# restart dnsmasq
