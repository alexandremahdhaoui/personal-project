#!/bin/sh

set -xe

# MetalConf Documentation
#
# Introduction
#   - Server resolves to metalconf.local resides at addr 172.16.0.3,
#     or for a subnet XXX.XXX.XXX.0/{8,12,16,24}: resides on addr XXX.XXX.XXX.3
#
# What does MetalConf serves?
#   - metalconf.local/ipxe/efi: iPXE binary w/ embedded script. Built as an init-container?
#   - metalconf.local/ipxe/config: iPXE Fedora CoreOS txt file
#   - metalconf.local/ignition: Fedora CoreOS Ignition file
#   - metalconf.local/kubeadm/{token,certs,init-cmd,join-cmd}: Kubeadm token/certificates for joining the cluster
#
# How to serve those files?
#   - Use nginx helm chart: https://github.com/bitnami/charts/tree/main/bitnami/nginx
#
# Future implementation:
#   - Add authentication mechanism
#   - Add orchestration logic to provide custom iPXE or ignition file.

METALCONF_NAME="MetalConf"
METALCONF_VERSION="v0.1.0"
METALCONF_IP="172.16.0.3"
NGINX_ROOT_DIR="/nginx"


dnf install -y helm

# ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: metalconf
  namespace: default
data:
  SPECIAL_LEVEL: very
  SPECIAL_TYPE: charm
  ipxe-config
EOF

#### Install nginx helm chart
cat <<EOF | helm upgrade --install metalconf oci://registry-1.docker.io/bitnamicharts/nginx --values -
fullnameOverride: metalconf

#initContainers:
# - name: ipxe-efi

serverBlock: |-
  server {
    listen 0.0.0.0:8080;

    root ${NGINX_ROOT_DIR};

    location / {
      return 200 "${METALCONF_NAME} ${METALCONF_VERSION}\n";
    }
  }

extraVolumes:
  - name: ipxe-efi
    emptyDir: {}
  - name: metalconf
extraVolumesMounts:
  - name: metalconf
    mountPath: ${NGINX_ROOT_DIR}/

service:
  annotations:
    metallb.universe.tf/loadBalancerIPs: ${METALCONF_IP}
EOF
