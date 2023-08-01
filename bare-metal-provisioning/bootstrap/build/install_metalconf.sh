#!/bin/sh

set -xe

# MetalConf Documentation
#
# alternative: https://github.com/poseidon/matchbox
#
# Introduction
#   - Server resolves to metalconf.local resides at addr 10.0.0.3,
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

METALCONF_IP="${1:-"10.0.0.3"}"

METALCONF_NAME="MetalConf"
METALCONF_VERSION="v0.1.0"
METALCONF_IPXE_CONFIG_URL="${METALCONF_IP}/ipxe/config"

NGINX_ROOT_DIR="/nginx"
IPXE_EFI_BUILD_DIR="/ipxe-efi"
IGNITION_BUILD_DIR="/ignition"

RELEASE="main"
BASE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/${RELEASE}/bare-metal-provisioning/bootstrap/build"
BUILD_IPXE_URL="${BASE_URL}/build_ipxe.sh"
BUILD_IGNITION_URL="${BASE_URL}/build_ignition.sh"

# Prerequisites
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
    #!ipxe

    set STREAM stable
    set VERSION 38.20230709.3.0
    set INSTALLDEV /dev/sda
    set CONFIGURL https://example.com/config.ign

    set BASEURL https://builds.coreos.fedoraproject.org/prod/streams/\${STREAM}/builds/\${VERSION}/x86_64

    kernel \${BASEURL}/fedora-coreos-\${VERSION}-live-kernel-x86_64 initrd=main coreos.live.rootfs_url=\${BASEURL}/fedora-coreos-\${VERSION}-live-rootfs.x86_64.img coreos.inst.install_dev=\${INSTALLDEV} coreos.inst.ignition_url=\${CONFIGURL}
    initrd --name main \${BASEURL}/fedora-coreos-\${VERSION}-live-initramfs.x86_64.img

    boot

  # butane will be available only for "kubeadm join".
  # bootstrapping init through iPXE is out of scope atm
  # NB0: once we have at least 3 servers running the control plane, we could restart a server to boot as a control
  #      plane, and enable us to rollover the manual "bootstrap init" node.
  # NB1: there is no distinction between booting a control plane node & a worker node.
  #      we need during refactoring to make the ignition provisioning dynamic.
  #      we could also create an operator that takes care to track servers & orchestrate the bare metal cluster.
  butane: |
    <butane-config>

  kubeadm: |
    <insert_kubeadm_join_command_or_a_token>
EOF

#### Install nginx helm chart
cat <<EOF | helm upgrade --install metalconf oci://registry-1.docker.io/bitnamicharts/nginx --values -
fullnameOverride: metalconf

initContainers:
  - name: ipxe-efi
    image: fedora:latest
    command: [ 'sh', '-c', 'curl -sL "${BUILD_IPXE_URL}" | sh -xse - ${METALCONF_IPXE_CONFIG_URL} ${IPXE_EFI_BUILD_DIR}' ]
    volumeMounts:
      - name: ipxe-efi
        mountPath: ${IPXE_EFI_BUILD_DIR}
  - name: ignition
    image: fedora:latest
    command: [ 'sh', '-c', 'curl -sL "${BUILD_IGNITION_URL}" | sh -xse - /input/butane /output/ignition' ]
    volumeMounts:
      - name: metalconf
        mountPath: /input
      - name: ignition
        mountPath: /output

serverBlock: |-
  server {
    listen 0.0.0.0:8080;

    location /ipxe/efi {
      index ipxe.efi;
      alias ${IPXE_EFI_BUILD_DIR};
    }

    location /ipxe/config {
      index config.ipxe;
      alias ${NGINX_ROOT_DIR};
    }

    location /ignition {
      index ignition;
      alias ${IGNITION_BUILD_DIR};
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
  - name: ignition
    emptyDir: {}
extraVolumeMounts:
  - name: metalconf
    mountPath: ${NGINX_ROOT_DIR}
  - name: ipxe-efi
    mountPath: ${IPXE_EFI_BUILD_DIR}
  - name: ignition
    mountPath: ${IGNITION_BUILD_DIR}

service:
  annotations:
    metallb.universe.tf/loadBalancerIPs: ${METALCONF_IP}
EOF
