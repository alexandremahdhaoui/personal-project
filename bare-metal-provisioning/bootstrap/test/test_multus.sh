#!/bin/bash

set -xe

cat <<EOF | kubectl create -f -
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: test
spec:
  config: '{
      "cniVersion": "0.3.1",
	    "name": "test",
	    "type": "macvlan",
	    "master": "enp0s31f6",
	    "mode": "bridge",
	    "linkInContainer": false,
	    "ipam": {
	      "type": "dhcp"
	    }
    }'
EOF
sleep 10
cat <<EOF | kubectl create -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: test
  annotations:
    k8s.v1.cni.cncf.io/networks: test
spec:
  containers:
  - name: test
    image: ealen/echo-server:latest
    ports:
      - containerPort: 80
EOF

kubectl delete networkattachmentdefinition.k8s.cni.cncf.io/test pod/test