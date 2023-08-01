#!/bin/bash

set -xe

DOWNLOAD_DIR="/usr/local/bin"
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"

curl -sfL --remote-name-all "https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet}" -o "${DOWNLOAD_DIR}"
chmod 755 "${DOWNLOAD_DIR}/"{kubeadm,kubelet}

RELEASE_VERSION="v0.15.1"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service"\
  | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" \
  | tee /etc/systemd/system/kubelet.service

mkdir -p "/etc/systemd/system/kubelet.service.d"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" \
  | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" \
  | tee "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"

systemctl enable --now kubelet