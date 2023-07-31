#!/bin/bash

TOKEN="${1}"

CONTROL_PLANE_HOST="${2}"
CONTROL_PLANE_PORT="${3}"

DISCOVERY_TOKEN_CA_CERT_HASH="${4}"

set -xe

URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/node_init.sh"
curl -sfL "${URL}" | sh -xe -

kubeadm join \
  --token "${TOKEN}" \
  "${CONTROL_PLANE_HOST}:${CONTROL_PLANE_PORT}" \
  --discovery-token-ca-cert-hash "sha256:${DISCOVERY_TOKEN_CA_CERT_HASH}"
