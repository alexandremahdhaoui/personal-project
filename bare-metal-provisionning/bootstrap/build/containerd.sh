#!/bin/bash

# Global env
ARCH="amd64"

# Env
REPO="https://github.com/containerd/containerd.git"
RELEASE=$(git ls-remote "${REPO}" | grep "v1\.[0-9]*\.[0-9]*$" | sed 's/.*tags\///' | sort | tail -n 1)
URL="https://github.com/containerd/containerd/releases/download/${RELEASE}/containerd-${RELEASE//v}-linux-${ARCH}.tar.gz"
DOWNLOAD_DIR="/usr/local"
curl -L "${URL}" | sudo tar -Cxvzf "${DOWNLOAD_DIR}"

## Post-install
CONTAINERD_SERVICE_DEST_PATH="/usr/lib/systemd/system/containerd.service"
CONTAINERD_SERVICE_URL="https://raw.githubusercontent.com/containerd/containerd/${RELEASE}/containerd.service"
# Install containerd service
curl -sLo "${CONTAINERD_SERVICE_DEST_PATH}" "${CONTAINERD_SERVICE_URL}"
# Enable & start containerd
systemctl daemon-reload
systemctl enable --now containerd
# Configure systemd cgroup driver
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
systemctl restart containerd

