# Fedora CoreOS

## Create an ignition file with butane

```shell
alias butane='podman run --rm --interactive       \
              --security-opt label=disable        \
              --volume ${PWD}:/pwd --workdir /pwd \
              quay.io/coreos/butane:release'

cat <<EOF | butane --pretty --strict -o config.ign
variant: fcos
version: 1.5.0
passwd:
  users:
    - name: core
      password_hash: $(podman run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt)
      groups:
        - wheel
      shell: /bin/bash
EOF
```