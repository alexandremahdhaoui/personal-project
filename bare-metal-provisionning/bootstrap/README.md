# Bootstrapping Bare Metal provisioning

## Prepare your system

```shell
dnf upgrade --refresh -y
echo -e 'set -o vi\nalias k="kubectl"\nalias kg="k get"\nalias kd="k describe"\nalias kl="k logs"' | tee -a /etc/bashrc
. /etc/bashrc
```

## Disable SELinux

```shell
grubby --update-kernel=ALL --args 'selinux=0 intel_iommu=on iommu=pt rd.driver.pre=vfio-pci pci=realloc'
```

## Optional: Upgrade your system

[Follow this link](system/fedora-system-upgrade.md)

## Prerequisites

```shell
dnf install -y container-selinux libvirt
```

## Boostrap a k8s management cluster

- [Bootstrapping a k0s cluster](distrib/k0s.md)
- [Bootstrapping a k3s cluster (unstable)](distrib/k3s.md)
- [Bootsrapping with Kubeadm](distrib/kubeadm.md)

### Post-installation

1. [Install dhcp CNI Plugin](build/cni_dhcp.sh)

2. [Test Multus after k8s cluster installation](test/test-multus.yml)

```shell
kubectl create -f https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisionning/bootstrap/test-multus.yml?token=GHSAT0AAAAAACFRSD72IOQPE2SBQDRXMPZOZGFBOCQ
# Cleanup
kubectl delete networkattachmentdefinition.k8s.cni.cncf.io/test pod/test
```

### Install Kubevirt

```shell
#### Install Kubevirt
# Point at latest release
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
# Deploy the Kubevirt operator
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
# Create the Kubevirt CR (instance deployment request) which triggers the actual installation
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml
# wait until all Kubevirt components are up
kubectl -n kubevirt wait kv kubevirt --for condition=Available
# Disable custom SELinux Policy
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
```

### Install virtctl with Krew 
```shell
#### Install virtctl in krew
# Install krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
  echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' | tee -a /etc/bashrc
)
. /etc/bashrc
# Install virtctl
kubectl krew install virt
```

### Test Kubevirt

```shell
kubectl delete VirtualMachine/test0 networkattachmentdefinition.k8s.cni.cncf.io/test0

cat <<EOF | kubectl create -f -
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: test0
spec:
  config: '{
      "cniVersion": "1.0.0",
	  "name": "test0",
	  "type": "macvlan",
	  "master": "enp0s31f6",
	  "mode": "bridge",
	  "linkInContainer": false,
	  "ipam": {
		"type": "dhcp"
	  }
    }'
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test0
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          interfaces:
          - name: default
            masquerade: {}
          - name: test0-macvlan
            bridge: {}
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        pod: {}
      - name: test0-macvlan
        multus:
          networkName: test0
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:devel
        name: containerdisk
EOF

kubectl delete VirtualMachine/test0 networkattachmentdefinition.k8s.cni.cncf.io/test0
```

## Launch a Fedora CoreOS VM
https://docs.fedoraproject.org/en-US/fedora-coreos/provisioning-kubevirt/