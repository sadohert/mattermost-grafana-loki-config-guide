# Mattermost Loki Log Aggregation — Configuration Guide

A step-by-step enablement guide for adding Grafana Loki centralized log aggregation to an existing Mattermost deployment that already uses Prometheus and Grafana for performance monitoring.

## Who is this for?

- **Mattermost TAMs** delivering services engagements
- **Mattermost Channel Partners** supporting customer deployments
- **IT Ops / SysAdmin teams** operating Mattermost in production

## Prerequisites

- Mattermost deployed on EC2 / bare-metal Linux servers
- Mattermost **JSON file logging enabled** (the default on all plans)
- Prometheus and Grafana already deployed per the [Mattermost performance monitoring guide](https://docs.mattermost.com/administration-guide/scale/deploy-prometheus-grafana-for-performance-monitoring.html)
- SSH access with sudo privileges

## What's included

```
source/
  deploy-loki-log-aggregation.rst   # The main guide (RST, Mattermost docs style)
config/
  loki-config.yaml                  # Production-ready Loki config (14-day retention)
  otel-collector-config.yaml        # OpenTelemetry Collector config for logs
dashboards/
  mattermost-loki-logs.json         # Grafana dashboard (import via UI)
```

## Quick start

1. Read `source/deploy-loki-log-aggregation.rst` — it walks through everything step by step.
2. Copy the config files below to the appropriate servers and edit the placeholders.
3. Import the Grafana dashboard JSON.

## Architecture

```
Mattermost Servers          Monitoring Server
┌──────────────────┐        ┌──────────────────┐
│ App + OTel Col   │──push──│ Loki (:3100)     │
│ App + OTel Col   │──push──│ Prometheus (:9090)│
│ (optional)       │        │ Grafana (:3000)   │
│ DB  + OTel Col   │──push──│                  │
└──────────────────┘        └──────────────────┘
```

## Retention

Log retention defaults to **14 days**. See the `retention_period` comments in the Loki config for instructions on adjusting this (30 days, 90 days, 1 year, etc.) and estimating disk usage.

---

## Configuration files

Download each config file, edit the placeholders noted below, and copy to the target server. Full details are in the [step-by-step guide](source/deploy-loki-log-aggregation.rst).

### [loki-config.yaml](config/loki-config.yaml)

> **Monitoring server** — install to `/opt/loki/loki-config.yaml`

Key settings to be aware of:

- **`retention_period`** — Defaults to `336h` (14 days). Loki requires hours; see the comments in the file for 30d / 90d / 1yr values and disk usage estimates.
- **`compactor.retention_enabled`** — Must stay `true` or retention is not enforced.
- **`storage.filesystem`** — Stores chunks and indexes under `/opt/loki/data/`. Ensure sufficient disk space for your retention window.

---

### [otel-collector-config.yaml](config/otel-collector-config.yaml)

> **Mattermost and PostgreSQL servers** — install to `/etc/otelcol-contrib/config.yaml`

**Placeholders to replace before starting:**

| Placeholder | Replace with |
|-------------|-------------|
| `<LOKI_HOST>` | IP or hostname of the monitoring server |
| `<HOSTNAME>` | This server's hostname (e.g., `mm-app-01`) |
| `<SERVICE_NAME>` | The service type (e.g., `mattermost` or `postgres`) |

Key settings to be aware of:

- **`filelog` receivers** — Tails `/opt/mattermost/logs/mattermost.log` and `/var/log/postgresql/*.json`.
- **`otlphttp` exporter** — Sends data to Loki's OTLP endpoint (Loki 3.0+).

---

### [mattermost-loki-logs.json](dashboards/mattermost-loki-logs.json) *(Grafana dashboard)*

> Import into Grafana: **Dashboards > New > Import > Upload JSON file**

| Panel | Description |
|-------|-------------|
| Log Volume by Level | Stacked bar chart — log rate by severity (color-coded) |
| Error / Warning / Total counters | Stat panels for the selected time range |
| HTTP 4xx/5xx Responses | Count of application-level HTTP errors |
| Error Rate Over Time | Time series per Mattermost instance |
| Top Error Messages | Table ranking most frequent errors (5 min windows) |
| Log Browser | Searchable, filterable log viewer with template variables |

**Template variables:** `service_name`, `service_instance_id`, `detected_severity`, `search` (free-text)

---

## Troubleshooting

### "I don't see any logs in Grafana"

1. **Check Log Level**: Ensure your Mattermost server is actually generating logs. If the server is idle and Log Level is set to `ERROR`, the file will be empty.
   - **Fix**: Temporarily set **File Log Level** to `DEBUG` or `INFO` in the System Console to verify flow.
2. **Check Connectivity**: Run `curl -v http://<LOKI_HOST>:3100/ready` from the app server to verify the firewall is open.
3. **Check Permissions**: Ensure the `otelcol` user can read the log file (e.g., `sudo -u otelcol cat /opt/mattermost/logs/mattermost.log`).

---

## Demo Script

Use this script to demonstrate the power of unified observability in Grafana (Metrics + Logs side-by-side).

1. **Open Explore**:
   - Click the **Compass icon** (Explore) in the left sidebar.
   - **Split** the view (button in top toolbar) so you have two panels.

2. **Query Metrics (Left Panel)**:
   - Data Source: **Prometheus**.
   - **Scenario A (Throughput)**:
     - Metric: `sum(rate(mattermost_api_time_count[5m])) by (instance)`
     - Meaning: Total API Requests per second per server.
   - **Scenario B (Saturation)**:
     - Metric: `label_replace(100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100), "instance", "$1", "instance", "(.*):.*")`
     - Meaning: CPU Usage % per server (port stripped for cleaner matching).
   - **Note**: Run only *one* Scenario at a time. Explore uses a single Y-axis, so mixing "Requests/sec" (10s-100s) with "CPU %" or "Latency" (0-1) will distort the graph.
   - Action: Click **Run Query**.

3. **Query Logs (Right Panel)**:
   - Data Source: **Loki**.
   - Filter: `{service_name="mattermost"} | json | detected_level="error"`
   - Action: Click **Run Query**.

4. **Correlate**:
   - Click the **Chain Icon** (top toolbar) to sync time ranges.
   - **Zoom in** on a spike in the CPU or Request graph.
   - The Loki panel will automatically filter to show *exactly* the logs from that high-load timeframe.

5. **Build Dashboard**:
   - Click **Add to Dashboard** -> **New Dashboard**.
   - Layout the graph and logs side-by-side for a permanent "Battle Station" view.

6. **Make it Dynamic (Bonus)**:
   - "Explore" queries are static. To get Dropdowns (Variables):
   - **Step A**: Go to **Dashboard Settings** (Gear Icon) -> **Variables** -> **Add Variable**.
   - **Step B**: Configure the Variable:
     - **Name**: `instance`
     - **Label**: `Instance`
     - **Type**: `Query`
     - **Data Source**: `Prometheus`
     - **Query Type**: `Label values`
     - **Label**: `instance` (Select from dropdown)
     - **Metric**: *(Optional - Select `node_cpu_seconds_total` if you want to filter)*
     - *(Note: You don't type a raw query here; just use the dropdowns)*
   - **Step C**: Make it Multi-select:
     - Check **Multi-value**: `On`
     - Check **Include All option**: `On`
   - **Step D**: Update your Panel Queries:
     - Change: `sum(rate(mattermost_api_time_count[5m])) by (instance)`
     - To: `sum(rate(mattermost_api_time_count{instance=~"$instance"}[5m])) by (instance)`
     - *(Notice the curly braces `{}` and the `=~` for regex matching)*
   - **Step E**: Click **Apply**. Now you have a professional dropdown!
