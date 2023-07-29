# Install DHCP CNI Plugin

[Documentation](https://www.cni.dev/plugins/current/ipam/dhcp/)

## Debugging solution

```shell
# Make sure the unix socket has been removed
rm -f /run/cni/dhcp.sock
nohup /opt/cni/bin/dhcp daemon &
```

## Create a service on each node

```shell
SERVICE_NAME=cni-dhcp

cat <<EOF | tee /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=${SERVICE_NAME}
Documentation=https://www.cni.dev/plugins/current/ipam/dhcp/
[Service]
Type=simple
ExecStart=rm -rf /run/cni/dhcp.sock && /opt/cni/bin/dhcp daemon
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

restorecon -Rv /etc/systemd/system/${SERVICE_NAME}.service
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl start ${SERVICE_NAME}
```

## Using a daemonset (experimental)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cni-dhcp
  namespace: kube-system
  labels:
    tier: node
    app: cni-dhcp
    name: cni-dhcp
spec:
  selector:
    matchLabels:
      name: cni-dhcp
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        tier: node
        app: cni-dhcp
        name: cni-dhcp
    spec:
      tolerations:
        - operator: Exists
          effect: NoSchedule
        - operator: Exists
          effect: NoExecute
      containers:
        - name: cni-dhcp
          image: alpine
          command: ["/host/opt/cni/bin/dhcp"]
          args:
            - "daemon"
            - "-hostprefix"
            -  "/host"
          resources:
            requests:
              cpu: "100m"
              memory: "50Mi"
            limits:
              cpu: "100m"
              memory: "50Mi"
          securityContext:
            privileged: false
          volumeMounts:
            - name: cni-dhcp-bin
              mountPath: /host/opt/cni/bin/
            - name: sock-destination
              mountPath: /host/run/cni/
      initContainers:
        - name: cni-dhcp-init
          image: alpine 
          command: ["rm"]
          args:
            - "-rf"
            - "/host/run/cni/dhcp.sock"
          resources:
            requests:
              cpu: "10m"
              memory: "15Mi"
          securityContext:
            privileged: false
          volumeMounts:
            - name: sock-destination
              mountPath: /host/run/cni/
      terminationGracePeriodSeconds: 10
      volumes:
        - name: cni-dhcp-bin
          hostPath:
            path: /opt/cni/bin/
        - name: sock-destination
          hostPath:
            path: /run/cni/
```