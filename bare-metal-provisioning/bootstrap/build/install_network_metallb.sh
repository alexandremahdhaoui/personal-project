#!/bin/bash

set -xe

LB_POOL_PUBLIC="${1:-"10.1.0.0-10.1.255.254"}"
LB_POOL_RESERVED="${2:-"10.0.0.2-10.0.0.4"}"

RELEASE="v0.13.10"

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${RELEASE}/config/manifests/metallb-native.yaml"

cat <<EOF | kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-pool-public
  namespace: metallb-system
spec:
  addresses:
  - ${LB_POOL_PUBLIC}
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-pool-reserved
  namespace: metallb-system
spec:
  addresses:
  - ${LB_POOL_RESERVED}
  autoAssign: false
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallb-advertisement
  namespace: metallb-system
EOF

