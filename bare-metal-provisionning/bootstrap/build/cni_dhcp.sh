#!/bin/bash

CNI_DHCP_SCRIPT="/usr/local/bin/cni-dhcp"
cat <<EOF | tee "${CNI_DHCP_SCRIPT}"
#!/bin/bash
rm -rf /run/cni/dhcp.sock
/opt/cni/bin/dhcp daemon
EOF
chmod 755 "${CNI_DHCP_SCRIPT}"

SERVICE_NAME="cni-dhcp"
cat <<EOF | tee /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=${SERVICE_NAME}
Documentation=https://www.cni.dev/plugins/current/ipam/dhcp/

[Service]
Type=simple
ExecStart=${CNI_DHCP_SCRIPT}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

restorecon -Rv /etc/systemd/system/"${SERVICE_NAME}".service
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"
