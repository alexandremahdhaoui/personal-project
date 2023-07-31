#!/bin/bash

set -xe

# https://medium.com/@darpanmalhotra/exposing-tftp-server-as-kubernetes-service-part-1-22ba7b017dd0

cat <<EOF | kubectl create -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: test0
spec:
  containers:
  - name: test
    image: quay.io/coreos/coreos-installer:release
    command: [ 'sleep', '3600' ]
    ports:
      - containerPort: 80
EOF

# TFTP Server
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: dnsmasq-conf
data:
  dnsmasq.conf: |
    port=0
    enable-tftp
    tftp-root=/var/lib/tftp
    dhcp-boot=
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: tftp-server
  name: tftp-server-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tftp-server
  template:
    metadata:
      labels:
        app: tftp-server
    spec:
      initContainers:
      - name: fedora-coreos-downloader
        image: quay.io/coreos/coreos-installer:release
        command: [ 'sh', '-c', 'coreos-installer download -f pxe -C /var/lib/tftp' ]
        volumeMounts:
        - name: tftp-root
          mountPath: /var/lib/tftp
      containers:
      - image: strm/dnsmasq:latest
        name: tftp-server
        command: [ 'sh', '-c', 'cp -f /tmp/dnsmasq.conf /etc' ]
        volumeMounts:
        - name: tftp-root
          mountPath: /var/lib/tftp
        - name: dnsmasq-conf
          mountPath: /tmp
        ports:
        - containerPort: 69
          name: tftp
          protocol: UDP
      volumes:
      - name: tftp-root
        emptyDir: {}
      - name: dnsmasq-conf
        configMap:
          name: dnsmasq-conf
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: tftp-server
  name: tftp-server
  namespace: default
spec:
  ports:
  - name: tftp
    port: 69
    protocol: UDP
    targetPort: 69
  selector:
    app: tftp-server
  type: LoadBalancer
EOF