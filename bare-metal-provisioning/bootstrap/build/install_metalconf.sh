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

# Fedora CoreOS & rpm-ostree
# test: kubectl run fedora --image quay.io/fedora/fedora-coreos:stable --command -- sleep 3600
#       kubectl exec -it fedora -- bash
#       kubectl delete pod fedora

METALCONF_IP="${1:-"10.0.0.3"}"

METALCONF_NAME="MetalConf"
METALCONF_VERSION="v0.1.0"
METALCONF_IPXE_CONFIG_URL="${METALCONF_IP}/ipxe/config"
METALCONF_IGNITION_URL="${METALCONF_IP}/ignition/bootstrap_join_worker"

NGINX_ROOT_DIR="/nginx"
IPXE_EFI_BUILD_DIR="/ipxe-efi"
IGNITION_BUILD_DIR="/ignition"

RELEASE="main"
BASE_URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/${RELEASE}/bare-metal-provisioning/bootstrap/build"
BUILD_IPXE_URL="${BASE_URL}/build_ipxe.sh"
BUILD_IGNITION_URL="${BASE_URL}/build_ignition.sh"

# TODO: Super insecure, create a service to replace that part.
#  - token will never expire
#  - bad practice to store these info in a configmap
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
    set CONFIGURL http://${METALCONF_IGNITION_URL}

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
            After=multi-user.target
            Description="Init cluster"
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=bash -c 'curl -sfL -H 'Cache-Control: no-cache' "${BASE_URL}/bootstrap_init.sh" | sh -xe -'
            [Install]
            WantedBy=default.target
  bootstrap_join_control_plane.butane: |
    variant: fcos
    version: 1.5.0
    systemd:
      units:
        - name: bootstrap_join_control_plane.service
          enabled: true
          contents: |
            [Unit]
            After=multi-user.target
            Description="Join cluster as control plane"
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=bash -c 'curl -sfL -H 'Cache-Control: no-cache' "${BASE_URL}/bootstrap_join_control_plane.sh" | sh -xse - "${KUBEADM_JOIN_CMD}"'
            [Install]
            WantedBy=default.target
  bootstrap_join_worker.butane: |
    variant: fcos
    version: 1.5.0
    systemd:
      units:
        - name: bootstrap_join_worker.service
          enabled: true
          contents: |
            [Unit]
            After=multi-user.target
            Description="Join cluster as worker node"
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=bash -c 'curl -sfL -H 'Cache-Control: no-cache' "${BASE_URL}/bootstrap_join_worker.sh" | sh -xse - "${KUBEADM_JOIN_CMD}"'
            [Install]
            WantedBy=default.target
  test_fcos.butane: |
    variant: fcos
    version: 1.5.0
    passwd:
      users:
        - name: core
          password_hash: \$y\$j9T\$61iCmQ03P4M12JUBiZ47G1\$eZ5XCsiTpgQudiosv/9HkDhFdVo.UwzlxFPphDmMfrD
          groups:
            - wheel
          shell: /bin/bash
  kubeadm: |
    <insert_kubeadm_join_command_or_a_token>
EOF

#### Install nginx helm chart
cat <<EOF | helm upgrade --install metalconf oci://registry-1.docker.io/bitnamicharts/nginx --values -
fullnameOverride: metalconf

initContainers:
  - name: ignition
    image: fedora:latest
    command:
    - 'sh'
    - '-c'
    - |-
      for x in bootstrap_join_worker bootstrap_join_control_plane bootstrap_init output; do
        curl -sL "${BUILD_IGNITION_URL}" | sh -xse - \${x}.butane \${x}.ign;
      done
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
  - name: nginx-root-dir
    image: fedora:latest
    command:
      - 'sh'
      - '-c'
      - |-
        mkdir -p ${NGINX_ROOT_DIR}/ipxe ${NGINX_ROOT_DIR}/ignition ${NGINX_ROOT_DIR}/kubeadm &&
        cp -f /metalconf/config.ipxe ${NGINX_ROOT_DIR}/ipxe/config &&
        cp -f ${IPXE_EFI_BUILD_DIR}/ipxe.efi ${NGINX_ROOT_DIR}/ipxe/efi &&
        cp -f ${IGNITION_BUILD_DIR}/*.ign ${NGINX_ROOT_DIR}/ignition &&
        cp -f /metalconf/kubeadm ${NGINX_ROOT_DIR}/kubeadm
    volumeMounts:
      - name: nginx-root-dir
        mountPath: ${NGINX_ROOT_DIR}
      - name: metalconf
        mountPath: /metalconf
      - name: ignition
        mountPath: /${IGNITION_BUILD_DIR}
      - name: ipxe-efi
        mountPath: ${IPXE_EFI_BUILD_DIR}

serverBlock: |-
  server {
    listen 0.0.0.0:8080;
    root ${NGINX_ROOT_DIR};
    autoindex on;
    autoindex_format json;
    autoindex_localtime on;

    location /info {
      return 200 "{\"name\": \"${METALCONF_NAME}\", \"version\": \"${METALCONF_VERSION}}\"\n";
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
  - name: nginx-root-dir
    emptyDir: {}
extraVolumeMounts:
  - name: nginx-root-dir
    mountPath: ${NGINX_ROOT_DIR}

service:
  annotations:
    metallb.universe.tf/loadBalancerIPs: ${METALCONF_IP}
EOF
