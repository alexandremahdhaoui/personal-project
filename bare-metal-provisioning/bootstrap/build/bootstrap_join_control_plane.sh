#!/bin/bash

KUBEADM_JOIN_CMD="${1}"

set -xe

URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/node_init.sh"
curl -sfL "${URL}" | sh -xe -

${KUBEADM_JOIN_CMD} --control-plane