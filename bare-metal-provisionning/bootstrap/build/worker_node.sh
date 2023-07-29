#!/bin/bash

set -xe

RELEASE="main"
BASE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/${RELEASE}/bare-metal-provisionning/bootstrap/build"
SCRIPTS="prereq_networking containerd crictl cni_plugins cni_dhcp runc kubeadm_kubelet kubectl"

for x in ${SCRIPTS} ; do
  curl -sfL "${BASE_URL}/${x}.sh" | sh -
done