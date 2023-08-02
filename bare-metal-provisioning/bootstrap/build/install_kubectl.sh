#!/bin/bash

set -xe

RELEASE=$(curl -sL -s https://dl.k8s.io/release/stable.txt)

curl -sLO "https://dl.k8s.io/release/${RELEASE}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Aliases
cat <<EOF | tee -a /etc/profile
alias k="kubectl"

# basic
alias ka="k apply -f"
alias kcreate="k create"

# Config
alias kctx="k config current-context"
kcontexts () {
	k config get-contexts | awk '{print \$1}'
}
alias kcu="k config use-context"

# Describe
kd () { k describe \$@; }
alias kdds="kd daemonset"
alias kdi="kd ingress"
alias kdic="kd ingressclass"
alias kdp="kd pod"
alias kdr="kd replicaset"
alias kds="kd service"
alias kdst="kd statefulset"

# Edit
alias ke="k edit"
alias keds="ke daemonset"
alias kest="ke statefulset"
alias ker="ke replicaset"

# Execute
alias kex="k exec -it"

# Get
kg () { k get \$@; }
alias kgp="kg pod"
alias kga="kg -A"
alias kgd="kg deployments"
alias kgds="kg daemonset"
alias kgi="kg ingress"
alias kgic="kg ingressclass"
alias kgr="kg replicaset"
alias kgs="kg service"
alias kgst="kg statefulset"
kgg ()   { kg "\$1" | grep "\$2"; }
kggp ()  { kgp | grep "\$1"; }
kggpa ()  { kgp -A | grep "\$1"; }

kgy () { kg \$@ -oyaml | yq --colors; }

# Set
k.config.set-context.current () { k config set-context --current "\$@"; }
kns  () {
  if [ ! -z "\$1" ]; then
    k.config.set-context.current --namespace="\$1" && echo Successfully switched to namespace: "\$1"
  else
    k.config.set-context.current --namespace="default" && echo Successfully switched to namespace: "default"
  fi
}

# Logs
alias kl="k logs"
alias kll="kl -l"

# Port-Forward
alias kpf="k port-forward"
EOF
