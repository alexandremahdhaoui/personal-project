#!/bin/bash

set -xe

#### Install Kubevirt
# Point at latest release
RELEASE=$(curl -sL "https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt")

# Deploy the Kubevirt operator
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml"

# Create the Kubevirt CR (instance deployment request) which triggers the actual installation
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml"

# wait until all Kubevirt components are up
kubectl -n kubevirt wait kv kubevirt --for condition=Available

# Enable feature flags
cat <<EOF | kubectl apply -f -
---
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - LiveMigration
        - DataVolumes
        - ExpandDisks
        - ExperimentalIgnitionSupport
        - Sidecar
        - HostDevices
        - Snapshot
        - HotplugVolumes
        - ExperimentalVirtiofsSupport
        - DisableCustomSELinuxPolicy
EOF
