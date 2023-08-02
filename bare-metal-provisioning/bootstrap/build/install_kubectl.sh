#!/bin/bash

set -xe

RELEASE=$(curl -sL -s https://dl.k8s.io/release/stable.txt)

curl -sLO "https://dl.k8s.io/release/${RELEASE}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# install
echo '. <(curl -sfL https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases)' | tee -a /etc/profile
