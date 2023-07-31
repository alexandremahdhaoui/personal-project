#!/bin/bash

set -xe

RELEASE=$(curl -sL -s https://dl.k8s.io/release/stable.txt)

curl -sLO "https://dl.k8s.io/release/${RELEASE}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
