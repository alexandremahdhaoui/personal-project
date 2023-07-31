#!/bin/bash

set -xe

RELEASE="v0.13.10"

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${RELEASE}/config/manifests/metallb-native.yaml"

cat <<EOF | kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-pool-0
  namespace: metallb-system
spec:
  addresses:
  - 172.31.0.0-172.31.255.254
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: lb-pool-0
  namespace: metallb-system
spec:
  ipAddressPools:
  - lb-pool-0
EOF

