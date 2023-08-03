#!/bin/bash

set -xe

{
  kubectl delete vm fcos0
  kubectl delete network-attachment-definitions.k8s.cni.cncf.io bridge-test
  kubectl delete secret/my-pub-key
  kubectl delete svc/vmiservice
}

kubectl create secret generic my-pub-key --from-file=key1=/etc/ssh/ssh_host_ed25519_key.pub

STREAM="stable" # or "testing" or "next"

kubectl apply -f - <<EOF
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: bridge-test
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "bridge-test",
      "type": "bridge",
      "bridge": "br1",
      "ipam": {
        "type": "host-local",
        "subnet": "10.253.0.0/24"
      }
    }'
EOF

kubectl create -f - <<EOF
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: fcos0
  labels:
    kubevirt.io/size: small
    kubevirt.io/domain: fcos0
spec:
  running: true
  template:
    spec:
      networks:
      - name: test1
        multus:
#          default: true
          networkName: bridge-test
      - name: default
        pod: {}
      domain:
        devices:
          interfaces:
          - name: default
            bridge: {}
          - name: test1
            bridge: {}
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          rng: {}
        resources:
          requests:
            memory: 2048M
      volumes:
      - containerDisk:
          image: quay.io/fedora/fedora-coreos-kubevirt:${STREAM}
        name: containerdisk
      - name: cloudinitdisk
        cloudInitConfigDrive:
          userDataBase64: "$(curl -sfL http://10.0.0.3/ignition/bootstrap_join_worker | base64 -w0)"
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: my-pub-key
          propagationMethod:
            qemuGuestAgent:
              users:
              - fedora
EOF

kubectl create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: vmiservice
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 22
  selector:
    kubevirt.io/domain: fcos0
  type: ClusterIP
EOF


# https://megamorf.gitlab.io/2022/02/16/kubectl-wait-on-arbitrary-json-path/
# kubectl wait vmi/fcos0 --for jsonpath='{.status.phase}'=Running
kubectl wait vm/fcos0 --for jsonpath='{.status.ready}'=true
