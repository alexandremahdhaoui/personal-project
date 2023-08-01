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
METALCONF_IGNITION_URL="${METALCONF_IP}/ignition"

NGINX_ROOT_DIR="/nginx"
IPXE_EFI_BUILD_DIR="/ipxe-efi"
IGNITION_BUILD_DIR="/ignition"

RELEASE="main"
BASE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/${RELEASE}/bare-metal-provisioning/bootstrap/build"
BUILD_IPXE_URL="${BASE_URL}/build_ipxe.sh"
BUILD_IGNITION_URL="${BASE_URL}/build_ignition.sh"

. "${BASE_URL}/helpers/get_ipv4.sh"

# TODO: Super insecure, create a service to replace that part. (token will never expire)
# It's also a bad practice to store that information into a configmap...
KUBEADM_JOIN_CMD="$(kubeadm token create --print-join-command --ttl 0) --control-plane"

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
    set CONFIGURL https://${METALCONF_IGNITION_URL}

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
  bootstrap_init.butane: |
    variant: fcos
    version: 1.5.0
    systemd:
      units:
        - name: bootstrap_init.service
          enabled: true
          contents: |
            [Unit]
            Description="Init cluster"
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=bash -c 'curl -sfL "https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/bootstrap_init.sh" | sh -xe -'
            [Install]
            WantedBy=multi-user.target
  bootstrap_join_control_plane.butane: |
    variant: fcos
    version: 1.5.0
    systemd:
      units:
        - name: bootstrap_join_control_plane.service
          enabled: true
          contents: |
            [Unit]
            Description="Join cluster as control plane"
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=bash -c 'curl -sfL "https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/bootstrap_join_control_plane.sh" | sh -xse -'
            [Install]
            WantedBy=multi-user.target
  bootstrap_join_worker.butane: |
    variant: fcos
    version: 1.5.0
    systemd:
      units:
        - name: bootstrap_join_worker.service
          enabled: true
          contents: |
            [Unit]
            Description="Join cluster as worker node"
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=bash -c 'curl -sfL "https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/bootstrap_join_worker.sh" | sh -xse -'
            [Install]
            WantedBy=multi-user.target
  kubeadm: |
    <insert_kubeadm_join_command_or_a_token>
EOF

#### Install nginx helm chart
cat <<EOF | helm upgrade --install metalconf oci://registry-1.docker.io/bitnamicharts/nginx --values -
fullnameOverride: metalconf

initContainers:
  - name: ignition-bootstrap_init
    image: fedora:latest
    command: [ 'sh', '-c', 'curl -sL "${BUILD_IGNITION_URL}" | sh -xse - /input/butane /output/bootstrap_init' ]
    volumeMounts:
      - name: metalconf
        mountPath: /input
      - name: ignition
        mountPath: /output
  - name: ignition-bootstrap_join_control_plane
    image: fedora:latest
    command: [ 'sh', '-c', 'curl -sL "${BUILD_IGNITION_URL}" | sh -xse - /input/butane /output/bootstrap_join_control_plane' ]
    volumeMounts:
      - name: metalconf
        mountPath: /input
      - name: ignition
        mountPath: /output
  - name: ignition-bootstrap_join_worker
    image: fedora:latest
    command: [ 'sh', '-c', 'curl -sL "${BUILD_IGNITION_URL}" | sh -xse - /input/butane /output/bootstrap_join_worker' ]
    volumeMounts:
      - name: metalconf
        mountPath: /input
      - name: ignition
        mountPath: /output
  - name: ipxe-efi
    image: fedora:latest
    command: [ 'sh', '-c', 'curl -sL "${BUILD_IPXE_URL}" | sh -xse - ${METALCONF_IPXE_CONFIG_URL} ${IPXE_EFI_BUILD_DIR}' ]
    volumeMounts:
      - name: ipxe-efi
        mountPath: ${IPXE_EFI_BUILD_DIR}

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
      autoindex on;
      alias ${IGNITION_BUILD_DIR};
    }

    location /kubeadm {
      autoindex on;
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
