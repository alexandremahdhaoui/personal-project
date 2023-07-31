#!/bin/bash

set -xe

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
  - 172.31.0.0-172.31.255.254
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-pool-reserved
  namespace: metallb-system
spec:
  addresses:
  - 172.16.0.2-172.16.0.4
  autoAssign: false
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallb-advertisement
  namespace: metallb-system
EOF

