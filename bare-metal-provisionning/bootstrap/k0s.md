# K0S bootstrapping

## Install K0s

```shell
curl -sSLf https://get.k0s.sh | sh
k0s install controller --single
k0s start

alias kubectl=k0s\ kubectl
```

## Install Multus

```shell
k apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml
```
