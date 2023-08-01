# Bootstrapping a kubernetes cluster with Kubeadm

- [Automating kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#automating-kubeadm)
- [Untaint CP node to enable it as a worker](https://stackoverflow.com/a/74792489)
- [Schedule Pods on a CP node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation)

## Control-plane initialization

```shell
URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/bootstrap_init.sh"
curl -sfL "${URL}" -H 'Cache-Control: no-cache' | sh -xe -
```

## Join cluster as a Control Plane or Worker Node

Joining as a control plane or worker node is available by PXE.
