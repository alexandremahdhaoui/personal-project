# Bootstrapping k3s cluster with Multus CNI Plugin

## Installing k3s

```shell 
#### Install k3s without flannel
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s -
```

## Installing Multus CNI Plugin
```shell
#### Install CNI plugin
# https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/quickstart.md
# https://gist.github.com/janeczku/ab5139791f28bfba1e0e03cfc2963ecf
URL="https://raw.githubusercontent.com/alexandremahdhaoui/personal-project/main/bare-metal-provisionning/bootstrap/multus-daemonset.yml?token=GHSAT0AAAAAACFRSD73B52FZJZOHMPTRSAYZGEHKMA"
curl -s "${URL}" | kubectl apply -f -
```