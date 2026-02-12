#!/bin/bash
# deploy_otel_collector.sh
# Usage: ./deploy_otel_collector.sh <IP_ADDR> <HOSTNAME> <LOKI_HOST> [SERVICE_NAME]

IP_ADDR=$1
HOSTNAME=$2
LOKI_HOST=$3
SERVICE_NAME=${4:-mattermost} # Default to mattermost if not provided
KEY_PATH="/Users/stuartdoherty/customers/vultr/ha-postgres-reprmgr-haproxy/terraform/ha-postgres-admin-key.pem"

if [ -z "$IP_ADDR" ] || [ -z "$HOSTNAME" ] || [ -z "$LOKI_HOST" ]; then
    echo "Usage: $0 <IP_ADDR> <HOSTNAME> <LOKI_HOST> [SERVICE_NAME]"
    exit 1
fi

echo "Deploying OpenTelemetry Collector to $HOSTNAME ($IP_ADDR) for service $SERVICE_NAME..."

# 1. SSH and Install OTel Collector Contrib
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ubuntu@$IP_ADDR <<EOF
# Add OTel Collector repository (if not already present)
if ! command -v otelcol-contrib &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
    curl -sL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.145.0/otelcol-contrib_0.145.0_linux_amd64.deb -o otelcol-contrib.deb
    sudo dpkg -i otelcol-contrib.deb
    rm otelcol-contrib.deb
fi

# Ensure permissions for log files
sudo usermod -aG adm otelcol-contrib
sudo usermod -aG postgres otelcol-contrib || true
sudo usermod -aG ubuntu otelcol-contrib || true

# Ensure group read permissions on logs
sudo chmod g+r /opt/mattermost/logs/mattermost.log 2>/dev/null || true
sudo chmod g+rx /opt/mattermost/logs 2>/dev/null || true
sudo chmod g+r /var/log/postgresql/*.json 2>/dev/null || true
EOF

# 2. Preparation of the configuration on the local machine
# Create a temporary config file with the correct placeholders
sed "s/<HOSTNAME>/$HOSTNAME/g; s/<LOKI_HOST>/$LOKI_HOST/g; s/<SERVICE_NAME>/$SERVICE_NAME/g" config/otel-collector-config.yaml > config/otel-collector-$HOSTNAME.yaml

# 3. Upload and Apply Config
scp -i $KEY_PATH -o StrictHostKeyChecking=no config/otel-collector-$HOSTNAME.yaml ubuntu@$IP_ADDR:/tmp/otel-collector-config.yaml
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ubuntu@$IP_ADDR <<EOF
sudo mkdir -p /etc/otelcol-contrib
sudo mv /tmp/otel-collector-config.yaml /etc/otelcol-contrib/config.yaml

# Restart service
sudo systemctl daemon-reload
sudo systemctl enable otelcol-contrib
sudo systemctl restart otelcol-contrib
sudo systemctl status otelcol-contrib --no-pager
EOF

# 4. Cleanup
rm config/otel-collector-$HOSTNAME.yaml
echo "OpenTelemetry Collector successfully deployed to $HOSTNAME"
