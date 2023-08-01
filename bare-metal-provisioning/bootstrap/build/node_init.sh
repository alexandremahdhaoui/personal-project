#!/bin/bash

set -xe

ARCH="amd64"

# upgrade packages
dnf upgrade -y --refresh

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# disable swap
systemctl disable "systemd-zram-setup@zram0.service"
systemctl mask "systemd-zram-setup@zram0.service"
swapoff -a

# open firewall
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=10250/tcp

# check virtualization requirements
grep -Eq '(vmx|svm)' /proc/cpuinfo
lsmod | grep -iq kvm

# install dependencies
dnf install -y socat iproute-tc conntrack

# install tools
dnf install -y jq tar git
curl -sLo /usr/local/bin/yj "https://github.com/sclevine/yj/releases/download/v5.1.0/yj-linux-${ARCH}"
chmod 755 /usr/local/bin/yj
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

## install binaries
# - cni-plugins
# - containerd
# - crictl
# - kubectl
# - kubelet
# - runc
RELEASE="main"
BASE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/${RELEASE}/bare-metal-provisioning/bootstrap/build"
SCRIPTS="network_prereq containerd crictl cni_plugins cni_dhcp runc kubeadm_kubelet kubectl"
for x in ${SCRIPTS} ; do
  curl -sfL "${BASE_URL}/install_${x}.sh" | sh -xe -
done
