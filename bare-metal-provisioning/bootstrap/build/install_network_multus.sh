#!/bin/bash

set -xe

RELEASE="v4.0.2"

kubectl apply -f "https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/${RELEASE}/deployments/multus-daemonset.yml"

# TODO: Implement a wait
sleep 10

# TODO: check if this cmd is really necessary (calico is now setup to forward ip)
jq '.delegates[0].plugins[0].container_settings.allow_ip_forwarding = true' /etc/cni/net.d/00-multus.conf -M | tee /etc/cni/net.d/00-multus.conf