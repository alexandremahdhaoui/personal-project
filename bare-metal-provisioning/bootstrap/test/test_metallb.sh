#!/bin/sh

set -xe

TEST_NAME="test-metallb"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: ${TEST_NAME}
  name: ${TEST_NAME}
  namespace: default
spec:
  containers:
  - name: ${TEST_NAME}
    image: ealen/echo-server:latest
    ports:
      - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ${TEST_NAME}
  name: ${TEST_NAME}
  namespace: default
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: ${TEST_NAME}
  type: LoadBalancer
EOF

LOAD_BALANCER_IP=$(kubectl get "svc/${TEST_NAME}" -oyaml | yq '.status.loadBalancer.ingress[0].ip')

if curl -sfL "${LOAD_BALANCER_IP}"; then
    kubectl delete "pod/${TEST_NAME}" "svc/${TEST_NAME}"
    exit 0
  else
    kubectl delete "pod/${TEST_NAME}" "svc/${TEST_NAME}"
    exit 1
fi
