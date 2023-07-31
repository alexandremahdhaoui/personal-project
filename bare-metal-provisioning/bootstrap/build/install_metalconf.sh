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



dnf install -y helm

#### Install nginx helm chart
helm install metalconf oci://registry-1.docker.io/bitnamicharts/nginx
