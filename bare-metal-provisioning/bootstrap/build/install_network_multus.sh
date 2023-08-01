#!/bin/bash

set -xe

RELEASE="v4.0.2"

kubectl apply -f "https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/${RELEASE}/deployments/multus-daemonset.yml"
