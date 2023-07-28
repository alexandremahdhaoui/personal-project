# Bootstrapping Bare Metal provisionning

```shell
# Install k3s without flannel
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s -

# Install CNI plugin
# https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/quickstart.md
# https://gist.github.com/janeczku/ab5139791f28bfba1e0e03cfc2963ecf

```

