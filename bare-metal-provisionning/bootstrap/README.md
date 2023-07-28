# Bootstrapping Bare Metal provisionning

## Prepare your system

```shell
dnf upgrade --refresh -y
echo -e 'set -o vi\nalias k="kubectl"\nalias kg="k get"\nalias kd="k describe"' | tee -a /etc/bashrc
. /etc/bashrc
```

## Optional: Upgrade your system

[Follow this link](./fedora-system-upgrade.md)

## Boostrap kubernetes management cluster

```shell 
#### Install k3s without flannel
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s -

#### Install CNI plugin
# https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/quickstart.md
# https://gist.github.com/janeczku/ab5139791f28bfba1e0e03cfc2963ecf
URL=""
curl -s "${URL}" | kubectl apply -f -

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
kubectl krew install virt

wget "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/virtctl-${RELEASE}-linux-amd64"
chmod 755 "virtctl-${RELEASE}-linux-amd64"
mv "virtctl-${RELEASE}-linux-amd64" /usr/local/bin/virtctl
```
