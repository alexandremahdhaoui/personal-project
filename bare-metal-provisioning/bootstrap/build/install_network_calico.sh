#!/bin/bash

set -xe

RELEASE="v3.26.1"

# install operator
kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${RELEASE}/manifests/tigera-operator.yaml"
# install calico resource manifest
curl -sL "https://raw.githubusercontent.com/projectcalico/calico/${RELEASE}/manifests/custom-resources.yaml" \
  | yq 'with(select(.kind == "Installation"); with(.spec.calicoNetwork.ipPools[0];.cidr = "172.16.0.0/16"))' \
  | kubectl create -f -
