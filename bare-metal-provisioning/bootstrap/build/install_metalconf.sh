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
IPXE_EFI_EMPTY_DIR="/ipxe-efi"

COMPILE_IPXE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/compile_ipxe.sh"
METALCONF_IPXE_CONFIG_URL="${METALCONF_IP}/ipxe/config"

dnf install -y helm

# ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: metalconf
  namespace: default
data:
  config.ipxe: |
    <ipxe_config>
  ignition: |
    <ignition_file>
  kubeadm: |
    <kubeadm>
EOF

#### Install nginx helm chart
cat <<EOF | helm upgrade --install metalconf oci://registry-1.docker.io/bitnamicharts/nginx --values -
fullnameOverride: metalconf

initContainers:
  - name: ipxe-efi
    image: fedora:latest
    command: [ 'sh', '-c', 'curl -sL "${COMPILE_IPXE_URL}" | sh -xse - ${METALCONF_IPXE_CONFIG_URL} ${IPXE_EFI_EMPTY_DIR}' ]
    volumeMounts:
      - name: ipxe-efi
        mountPath: ${IPXE_EFI_EMPTY_DIR}

serverBlock: |-
  server {
    listen 0.0.0.0:8080;

    location /ipxe/efi {
      index ipxe.efi;
      alias ${IPXE_EFI_EMPTY_DIR};
    }

    location /ipxe/config {
      index config.ipxe;
      alias ${NGINX_ROOT_DIR};
    }

    location /ignition {
      index ignition;
      alias ${NGINX_ROOT_DIR};
    }

    location /kubeadm {
      index kubeadm;
      alias ${NGINX_ROOT_DIR};
    }

    location / {
      return 200 "${METALCONF_NAME} ${METALCONF_VERSION}\n";
    }
  }

extraVolumes:
  - name: metalconf
    configMap:
      name: metalconf
  - name: ipxe-efi
    emptyDir: {}
extraVolumeMounts:
  - name: metalconf
    mountPath: ${NGINX_ROOT_DIR}
  - name: ipxe-efi
    mountPath: ${IPXE_EFI_EMPTY_DIR}

service:
  annotations:
    metallb.universe.tf/loadBalancerIPs: ${METALCONF_IP}
EOF
