#!/bin/bash

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

set -xe

POD_CIDR="172.16.0.0/16"
METALLB_POOL_PUBLIC="10.1.0.0-10.1.255.254"
METALLB_POOL_RESTRICTED="10.0.0.2-10.0.0.4"
METALCONF_IP="10.0.0.3"

RELEASE="main"
BASE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/${RELEASE}/bare-metal-provisioning/bootstrap/build"

# initialize node
URL="${BASE_URL}/node_init.sh"
curl -sfL "${URL}" | sh -xe -

# TODO: Remove - IPXE boot won't need these 2 lines of cleanup
kubeadm reset -f
rm -rf /etc/cni/net.d/*

# run kubeadm
kubeadm init --service-cidr="${POD_CIDR}"  --pod-network-cidr="${POD_CIDR}"

# export kubeconfig
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | tee -a /etc/bashrc

# untaint bootstrap-init node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
sleep 10

# install a CNI network plugin
curl -sfL "${BASE_URL}/install_network_calico.sh" | sh -xse - "${POD_CIDR}"
sleep 30

# install metallb
curl -sfL "${BASE_URL}/install_network_metallb.sh" | sh -xse - "${METALLB_POOL_PUBLIC}" "${METALLB_POOL_RESTRICTED}"
sleep 10

# install metalconf
curl -sfL "${BASE_URL}/install_metalconf.sh" | sh -xse - "${METALCONF_IP}"

# install kubevirt
curl -sfL "${BASE_URL}/install_kubevirt.sh" | sh -xe -

# install Multus
curl -sfL "${BASE_URL}/install_network_multus.sh" | sh -xe -
