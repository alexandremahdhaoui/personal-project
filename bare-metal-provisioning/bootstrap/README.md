# Bootstrapping Bare Metal provisioning

# TODO:

- [ ] Create or Install operator for managing openWrt router.
  - To automate the iPXE provisionning
- [ ] Take look at [bitnami/charts](https://github.com/bitnami/charts/tree/main/bitnami) & update install scripts
  - or alternatively [truecharts/charts](https://github.com/truecharts/charts)
using these charts. E.g.: for Multus CNI.
- [ ] Install cert-manager... etc

## Prepare your system

## Optional: Upgrade your system

[Follow this link](system/fedora-system-upgrade.md)

## Boostrap a k8s management cluster

- [Bootsrapping with kubeadm](distrib/kubeadm.md)
- [Bootstrapping a k0s cluster](distrib/k0s.md)
- [Bootstrapping a k3s cluster (unstable)](distrib/k3s.md)

### Post-installation

1. [Install dhcp CNI Plugin](build/install_cni_dhcp.sh)

2. [Test Multus after k8s cluster installation](test/test_multus.sh)


## Launch a Fedora CoreOS VM
https://docs.fedoraproject.org/en-US/fedora-coreos/provisioning-kubevirt/