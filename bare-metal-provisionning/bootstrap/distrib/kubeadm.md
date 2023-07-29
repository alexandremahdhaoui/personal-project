# Bootstrapping a kubernetes cluster with Kubeadm


## Permanently disable swap

```shell
systemctl disable "systemd-zram-setup@zram0.service"
systemctl mask "systemd-zram-setup@zram0.service"
swapoff -a
```

## Verify virtualization

```shell
grep -E --color '(vmx|svm)' /proc/cpuinfo
lsmod | grep -i kvm
```

## Prerequisites

```shell
dnf install -y git
```

## Worker node binaries

List of binaries:
- cni-plugins
- containerd
- crictl
- kubectl
- kubelet
- kube-proxy
- runc

```shell
URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisionning/bootstrap/build/worker_node.sh"
curl -sfL "${URL}" | sh -
```