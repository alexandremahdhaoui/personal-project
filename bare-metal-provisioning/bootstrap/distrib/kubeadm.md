# Bootstrapping a kubernetes cluster with Kubeadm

- [Automating kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#automating-kubeadm)
- [Untaint CP node to enable it as a worker](https://stackoverflow.com/a/74792489)
- [Schedule Pods on a CP node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#control-plane-node-isolation)

## Control-plane initialization

```shell
URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/bootstrap_init.sh"
curl -sfL "${URL}" -H 'Cache-Control: no-cache' | sh -xe -
```

## Join cluster as a Control Plane Node

```shell
URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/bootstrap_join_control_plane.sh"
curl -sfL "${URL}" | sh -xe -
```

## Join cluster as a Worker Node

```shell
URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisioning/bootstrap/build/bootstrap_join_worker.sh"
curl -sfL "${URL}" | sh -xe -
```


