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
  promtail-mattermost.yaml          # Promtail config for Mattermost app servers
  promtail-postgres.yaml            # Optional: Promtail config for PostgreSQL servers
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
┌─────────────────┐        ┌──────────────────┐
│ App + Promtail  │──push──│ Loki (:3100)     │
│ App + Promtail  │──push──│ Prometheus (:9090)│
│ (optional)      │        │ Grafana (:3000)   │
│ DB  + Promtail  │──push──│                  │
└─────────────────┘        └──────────────────┘
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

### [promtail-mattermost.yaml](config/promtail-mattermost.yaml)

> **Each Mattermost app server** — install to `/opt/promtail/promtail-config.yaml`

**Placeholders to replace before starting:**

| Placeholder | Replace with |
|-------------|-------------|
| `<LOKI_HOST>` | IP or hostname of the monitoring server |
| `<MM_HOSTNAME>` | This server's hostname (e.g., `mm-app-01`) |

Key settings to be aware of:

- **`__path__`** — Defaults to `/opt/mattermost/logs/mattermost.log`. Change if your install path differs.

---

### [promtail-postgres.yaml](config/promtail-postgres.yaml) *(optional)*

> **PostgreSQL server** — install to `/opt/promtail/promtail-config.yaml`

**Placeholders to replace before starting:**

| Placeholder | Replace with |
|-------------|-------------|
| `<LOKI_HOST>` | IP or hostname of the monitoring server |
| `<PG_HOSTNAME>` | This server's hostname (e.g., `mm-db-01`) |

Key settings to be aware of:

- **`__path__`** — Defaults to the RHEL/Amazon Linux path for PostgreSQL 15. See the comments in the file for Ubuntu/Debian paths. Does not apply to Amazon RDS.

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

**Template variables:** `service_name`, `instance`, `log_level`, `search` (free-text)
