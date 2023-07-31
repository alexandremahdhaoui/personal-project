#!/bin/sh

set -xe

cat <<EOF | kubectl create -f -
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: test0
spec:
  config: '{
      "cniVersion": "1.0.0",
	  "name": "test0",
	  "type": "macvlan",
	  "master": "enp0s31f6",
	  "mode": "bridge",
	  "linkInContainer": false,
	  "ipam": {
		"type": "dhcp"
	  }
    }'
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test0
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          interfaces:
          - name: default
            masquerade: {}
          - name: test0-macvlan
            bridge: {}
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      - name: test0-macvlan
        multus:
          networkName: test0
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:devel
        name: containerdisk
EOF

kubectl delete VirtualMachine/test0 networkattachmentdefinition.k8s.cni.cncf.io/test0