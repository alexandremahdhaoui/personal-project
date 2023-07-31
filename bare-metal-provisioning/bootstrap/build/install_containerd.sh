#!/bin/bash

# Global env
ARCH="amd64"

# Env
REPO="https://github.com/containerd/containerd.git"
RELEASE=$(git ls-remote "${REPO}" | grep "v1\.[0-9]*\.[0-9]*$" | sed 's/.*tags\///' | sort | tail -n 1)
URL="https://github.com/containerd/containerd/releases/download/${RELEASE}/containerd-${RELEASE//v}-linux-${ARCH}.tar.gz"
DOWNLOAD_DIR="/usr/local"
curl -sL "${URL}" | sudo tar -C "${DOWNLOAD_DIR}" -xz

## Post-install
CONTAINERD_SERVICE_DEST_PATH="/usr/lib/systemd/system/containerd.service"
CONTAINERD_SERVICE_URL="https://raw.githubusercontent.com/containerd/containerd/${RELEASE}/containerd.service"
# Install containerd service
curl -sLo "${CONTAINERD_SERVICE_DEST_PATH}" "${CONTAINERD_SERVICE_URL}"
# Enable & start containerd
systemctl daemon-reload
systemctl enable --now containerd
## Configure systemd cgroup driver
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
# generate
mkdir -p /etc/containerd
containerd config default \
  | yj -t \
  | jq '.plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options.SystemdCgroup = true' \
  | jq '.plugins."io.containerd.internal.v1.tracing".sampling_ratio = 1.0' \
  | yj -jt \
  | tee /etc/containerd/config.toml
# Restart containerd
systemctl restart containerd

