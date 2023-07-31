#!/bin/bash

set -xe

# enable overlay & bridge
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# enable tftp helpers
#sudo modprobe nf_conntrack_tftp
#sudo modprobe nf_nat_tftp
#cat <<EOF | sudo tee -a /etc/modules-load.d/k8s.conf
#nf_conntrack_tftp
#nf_nat_tftp
#EOF

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
