#!/bin/bash


KUBEADM_JOIN_CMD="${1}"

set -xe

URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/node_init.sh"
curl -sfL "${URL}" | sh -xe -

# TODO: REMOVE - The idea was to make use of some NodePorts & disabling firewall in a first place.
# Better enable firewall & use a proper set of rules.
# disable firewalld for worker nodes
systemctl disable firewalld --now

${KUBEADM_JOIN_CMD}