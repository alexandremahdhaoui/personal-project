#!/bin/ash

# DISCLAIMER: this operation is not automated and must be run

# https://ipxe.org/howto/chainloading
# https://ipxe.org/appnote/uefihttp

METALCONF_IPXE_EFI_URL="${1:-10.0.0.3}"

#### setup dnsmasq as a tftp server & make it pxe ready
# prepare tftp root dir
TFTP_ROOT="/var/lib/tftp"
IPXE_EFI_FILENAME="ipxe.efi"

# create tftp root folder
mkdir -p "${TFTP_ROOT}"

# download image
curl "http://${METALCONF_IPXE_EFI_URL}" -o "${TFTP_ROOT}/${IPXE_EFI_FILENAME}"

# update config
cp /etc/config/dhcp /etc/config/dhcp.bak
CONFIG="$(cat <<EOF | awk '{printf "\toption "$0"\\n"}'
dhcp-option '66,0.0.0.0'
enable_tftp '1'
tftp_root '${TFTP_ROOT}'
dhcp-boot '${IPXE_EFI_FILENAME}'
dhcp-match 'set:X86-64_EFI_HTTP,option:client-arch,16'
dhcp-userclass 'set:iPXE,iPXE'
dhcp-option 'lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:bootfile-name,http://${METALCONF_IPXE_EFI_URL}/ipxe/efi'
dhcp-option 'lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:vendor-class,HTTPClient'
EOF
)"
sed -i "/^config dnsmasq/a \ ${CONFIG}" /etc/config/dhcp


#CONFIG="$(cat <<EOF | awk '{printf "\toption "$0"\\n"}'
#enable_tftp '1'
#tftp_root '${TFTP_ROOT}'
#dhcp-boot '${IPXE_EFI_FILENAME}'
#dhcp-match 'set:X86-64_EFI_HTTP,option:client-arch,16'
#dhcp-userclass 'set:iPXE,iPXE'
#dhcp-option 'lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:bootfile-name,http://${METALCONF_IPXE_EFI_URL}/ipxe/efi'
#dhcp-option 'lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:vendor-class,HTTPClient'
#EOF
#)"
#sed -i "/^config dnsmasq/a \ ${CONFIG}" /etc/config/dhcp
