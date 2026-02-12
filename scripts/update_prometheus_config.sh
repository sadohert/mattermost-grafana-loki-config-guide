#!/bin/bash
# update_prometheus_config.sh
# Usage: ./update_prometheus_config.sh

METRICS_SERVER_IP="172.31.28.41"
METRICS_SERVER_PUBLIC_IP="100.53.33.222"

PG1="172.31.12.219"
PG2="172.31.89.107"
PG3="172.31.28.242"

echo "Updating Prometheus configuration on $METRICS_SERVER_PUBLIC_IP ($METRICS_SERVER_IP)..."

# Define the new jobs with friendly instance names
CAT_CMD=$(cat <<EOF
  - job_name: postgres
    static_configs:
      - targets: ['$PG1:9187']
        labels:
          instance: 'pg1'
          cluster: 'ha-postgres'
      - targets: ['$PG2:9187']
        labels:
          instance: 'pg2'
          cluster: 'ha-postgres'
      - targets: ['$PG3:9187']
        labels:
          instance: 'pg3'
          cluster: 'ha-postgres'

  - job_name: postgres-node
    static_configs:
      - targets: ['$PG1:9100']
        labels:
          instance: 'pg1'
          cluster: 'ha-postgres'
      - targets: ['$PG2:9100']
        labels:
          instance: 'pg2'
          cluster: 'ha-postgres'
      - targets: ['$PG3:9100']
        labels:
          instance: 'pg3'
          cluster: 'ha-postgres'
EOF
)

# Use SSH to update the file
# We append these jobs to the end of the scrape_configs section.
# This assumes /etc/prometheus/prometheus.yml exists and has a scrape_configs section.

# Drafting the command to be run on the metrics server:
# sudo tee -a /etc/prometheus/prometheus.yml <<EOF
# $CAT_CMD
# EOF
# sudo systemctl restart prometheus

echo "Please run the following commands on the Mattermost Metrics Server ($METRICS_SERVER_IP):"
echo "--------------------------------------------------------------------------------"
echo "sudo tee -a /etc/prometheus/prometheus.yml <<EOF"
echo "$CAT_CMD"
echo "EOF"
echo "sudo systemctl restart prometheus"
echo "--------------------------------------------------------------------------------"
