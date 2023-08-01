#!/bin/bash

set -xe

RELEASE="main"
BASE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/${RELEASE}/bare-metal-provisioning/bootstrap/build"

# initialize node
URL="${BASE_URL}/node_init.sh"
curl -sfL "${URL}" | sh -xe -

# run kubeadm
kubeadm init
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | tee -a /etc/bashrc

# install a CNI network plugin
curl -sfL "${BASE_URL}/install_network_flannel.sh" | sh -xse - "172.16.0.0/16"

# install Multus
curl -sfL "${BASE_URL}/install_network_multus.sh" | sh -xe -

# install kubevirt
curl -sfL "${BASE_URL}/install_kubevirt.sh" | sh -xe -

# install metallb
curl -sfL "${BASE_URL}/install_metallb.sh" | sh -xe - "10.1.0.0-10.1.255.254" "10.0.0.2-10.0.0.4"

# install metalconf
curl -sfL "${BASE_URL}/install_metalconf.sh" | sh -xse - "10.0.0.3"
