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
mkdir -p "/var/lib/${TFTP_ROOT}"

# download image
curl "http://${METALCONF_IPXE_EFI_URL}" -o "${TFTP_ROOT}/${IPXE_EFI_FILENAME}"

# update config
CONFIG="$(cat <<EOF | awk '{printf "\toption "$0"\\n"}'
enable_tftp '1'
tftp_root '0.0.0.0'
dhcp-boot '${IPXE_EFI_FILENAME}'
dhcp-match 'set:X86-64_EFI_HTTP,option:client-arch,16'
dhcp-userclass 'set:iPXE,iPXE'
dhcp-option 'lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:bootfile-name,http://${METALCONF_IPXE_EFI_URL}/ipxe/efi'
dhcp-option 'lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:vendor-class,HTTPClient'
EOF
)"
# TODO: remove the `head -n 10` and add `-i` parameter to sed
sed -i "/^config dnsmasq/a \ ${CONFIG}" /etc/config/dhcp



#sudo service dnsmasq restart
# cat <<EOF | tee -a /etc/dnsmasq.conf
# enable-tftp
# tftp-root=${TFTP_ROOT}
# dhcp-boot=${IPXE_EFI_FILENAME}
# dhcp-match=set:X86-64_EFI_HTTP,option:client-arch,16
# dhcp-userclass=set:iPXE,iPXE
# dhcp-option=lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:bootfile-name,<http url pointing to (bin-x86_64-efi/)ipxe.efi binary>
# dhcp-option=lan,tag:X86-64_EFI_HTTP,tag:!iPXE,option:vendor-class,HTTPClient
# EOF
# restart dnsmasq
