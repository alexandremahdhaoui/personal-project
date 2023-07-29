# Bootstrapping Bare Metal provisioning

## Prepare your system

```shell
dnf upgrade --refresh -y
echo -e 'set -o vi\nalias k="kubectl"\nalias kg="k get"\nalias kd="k describe"\nalias kl="k logs"' | tee -a /etc/bashrc
. /etc/bashrc
```

## Optional: Upgrade your system

[Follow this link](./fedora-system-upgrade.md)

## Boostrap a k8s management cluster

- [Bootstrapping a k0s cluster](k0s.md)
- [Bootstrapping a k3s cluster (unstable)](k3s.md)

### Post-installation

1. [Install dhcp CNI Plugin](cni-dhcp.md)

2. [Test Multus after k8s cluster installation](test-multus.yml)

```shell
kubectl apply -f https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisionning/bootstrap/test-multus.yml?token=GHSAT0AAAAAACFRSD72EV3X2RLC7ETQU3PKZGE7WFQ
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
k krew install virt
```

