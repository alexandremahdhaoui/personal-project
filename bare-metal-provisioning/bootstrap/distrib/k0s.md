# K0S bootstrapping

## Install K0s

```shell
curl -sSLf https://get.k0s.sh | sh
k0s install controller --single
k0s start

sudo ln -s "/usr/local/bin/k0s" /usr/local/bin/kubectl
```

## Install Multus

```shell
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml
```
