#!/bin/sh

set -xe

NETWORK_CIDR=${1:-"172.16.0.0/16"}

URL="https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"
curl -sfL "${URL}" | sed "s@10.244.0.0/16@${NETWORK_CIDR}@" | kubectl apply -f -
