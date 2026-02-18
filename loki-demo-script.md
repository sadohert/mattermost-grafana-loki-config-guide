# Loki Log Aggregation Demo - "From Chaos to Clarity"

**Demo Type:** Recorded Technical Demo
**Target Audience:** Mixed technical audience (DevOps engineers, team leads, decision-makers)
**Duration:** 5 minutes
**Presenter:** [Your Name]
**Date:** February 2026
**Recording Format:** Screen capture with voiceover

---

## Overview

**Goal:** Demonstrate how Loki provides unified log aggregation that transforms slow, scattered troubleshooting into fast, centralized incident response with powerful dashboarding and alerting capabilities.

**Key Messages:**
- Loki eliminates the pain of scattered logs across multiple systems
- Unified log exploration dramatically speeds up troubleshooting
- Mission Control dashboards provide real-time visibility into application health
- Built-in alerting opportunities catch issues before they become incidents

**Prerequisites:**
- Demo environment with load test running against Mattermost
- Postgres database connected to Mattermost
- Grafana with Loki data source configured
- Sample "Mission Control" dashboard template available

---

## Demo Setup

**Environment:**
- Grafana with Loki data source configured
- Loki collecting logs via OpenTelemetry Collector from:
  - Mattermost application servers (JSON logs at `/opt/mattermost/logs/mattermost.log`)
  - Postgres database server (optional)
  - Load test running to generate realistic traffic
- Pre-built dashboard: `mattermost-loki-logs.json`

**Required Materials:**
- Screen recording software ready (OBS, QuickTime, etc.)
- Grafana Explore view prepared with Loki data source
- Pre-built "Mattermost Log Aggregation" dashboard imported
- Blank dashboard ready for quick customization demo
- LogQL queries prepared (copy-paste ready - see script below)

**Recording Tips:**
- Test all queries before recording to ensure they return data
- Clear browser history/cookies for clean UI
- Set Grafana time range to "Last 15 minutes" or "Last 1 hour" for live data
- Close unnecessary browser tabs and notifications
- Use 1920x1080 resolution for best quality
- Record in segments if needed (you can edit together later)

---

## Script

### SCENE 1: The Scattered Logs Problem (00:00-00:40)

*[Start with Grafana Explore view visible]*

**Talking Points:**

"Imagine you're on call at 2 AM. Users are reporting slow response times in your Mattermost instance. Where do you start looking?"

*[Pause for 2 seconds]*

"With traditional logging, you'd be checking Mattermost application logs on one server, Postgres database logs on another, maybe load balancer logs on a third system. Each with different formats, different timestamps, different access methods. This scattered approach turns a 5-minute investigation into a 30-minute nightmare."

"Today, I'll show you how we solve this with Loki—bringing all logs into one unified view. In the next 5 minutes, you'll see how to explore logs across multiple systems, build a Mission Control dashboard for real-time visibility, and set up the foundation for proactive alerting."

**Key Moments:**
- Emphasize the pain: multiple systems, slow investigation
- Set expectation: 5 minutes to see complete solution

---

### SCENE 2: Unified View with Loki (00:40-01:30)

*[Navigate to Grafana Explore, show Loki data source]*

**Demo Actions:**
```logql
{service_name="mattermost"}
```

**Talking Points:**

"Here's the difference Loki makes. With one simple query, I can see all logs from our Mattermost application servers."

*[Execute query, show log results streaming in]*

"Notice we have logs flowing in real-time from our demo setup via OpenTelemetry Collector from each Mattermost server. Every request, every database query, every error—all in one place with consistent timestamps."

"But here's where it gets powerful. Let me show you logs from both Mattermost *and* Postgres together."

**Demo Actions:**
```logql
{service_name=~"mattermost|postgres"}
```

*[Execute query, show combined log stream]*

**Talking Points:**

"Now I'm seeing application logs and database logs side-by-side, correlated by timestamp. When a user reports a slow query, I can immediately see both the application request and the corresponding database activity. This unified view is what transforms troubleshooting from a scavenger hunt into actual investigation."

**Key Moments:**
- Show logs streaming in real-time
- Emphasize "one place, consistent timestamps, correlated view"
- Pause 3 seconds to let the unified view sink in

---

### SCENE 3: Exploring Logs (01:30-02:45)

*[Continue in Explore view]*

**Talking Points:**

"Let me show you how quickly we can investigate issues with LogQL—Loki's query language. Say we want to find all errors in the last 15 minutes."

**Demo Actions:**
```logql
{service_name="mattermost"} | json | level="error"
```

*[Execute query, show filtered error logs]*

**Talking Points:**

"There we go—every error from all Mattermost servers, automatically parsed as JSON so I can dig into the details. In a traditional setup, I'd be SSH-ing into multiple servers, running grep commands, correlating timestamps manually. Here, it's instant and unified."

"Now let's get more specific. Let's find all HTTP 4xx and 5xx errors—client and server errors from our API."

**Demo Actions:**
```logql
{service_name="mattermost"} | json | status_code >= 400
```

*[Execute query]*

**Talking Points:**

"Perfect. I can see exactly when HTTP errors are happening across all servers. Notice the JSON parsing automatically extracts the status_code field so I can filter on it."

"And because this is unified with our Postgres logs, I can correlate with database activity. Let me show you Postgres errors."

**Demo Actions:**
```logql
{service_name="postgres"} | json | level="error"
```

*[Execute query - may show no results if DB is healthy]*

**Talking Points:**

"Database looks healthy—no errors. So if we're seeing application errors, we know the database itself is likely not the root cause. That single insight just saved us from going down the wrong troubleshooting path."

"This exploratory workflow—filtering, drilling down, correlating across systems—is what cuts investigation time from 30 minutes to 5 minutes."

**Key Moments:**
- Show 2-3 progressive queries building on each other
- Emphasize speed: "instant" vs "SSH-ing and grep-ing"
- Highlight the investigative insight about connection pool

---

### SCENE 4: Building Mission Control (02:45-04:00)

*[Navigate to Dashboards, show existing dashboard or blank dashboard]*

**Talking Points:**

"Now, exploring logs is powerful for investigations. But what if you want continuous visibility? That's where dashboards come in."

"Let me show you how quick it is to create a Mission Control dashboard for your application."

**Demo Actions:**
*[Click "+ New Dashboard" or open blank dashboard]*
*[Add a new panel]*

```logql
sum(count_over_time({service_name="mattermost"} | json [$__auto])) by (level)
```

*[Configure as time series bar chart showing log volume by level]*

**Talking Points:**

"Here I'm adding a panel that shows log volume broken down by severity—info, warning, error. This gives me an instant health check: if error logs spike, something's wrong. Notice the colors: green for info, yellow for warnings, red for errors."

*[Add second panel quickly]*

**Demo Actions:**
```logql
sum(count_over_time({service_name="mattermost"} | json | level="error" [$__auto]))
```

*[Configure as stat panel showing total errors]*

**Talking Points:**

"And here's a simple error counter—total errors in the selected time range. If this number starts climbing, we know we have an issue before users even report it."

*[Reference additional panel ideas]*

"You can add panels for HTTP error rates, top error messages, even break it down by server instance using the service_instance_id field. The key is that all of this data is coming from logs—no application code changes needed."

**Key Moments:**
- Show how quick it is to add panels (don't belabor the details)
- Emphasize "no code changes needed"
- Mention real metrics: error rates, latency, connection pools

**Transition:**
"Now, you don't have to build this from scratch..."

---

### SCENE 5: Existing Resources & Impact (04:00-04:40)

*[Navigate to show pre-built dashboard or reference it]*

**Talking Points:**

"Now, you don't have to build all of this from scratch. We've already created a comprehensive dashboard called 'Mattermost Log Aggregation' that you can import directly."

*[Navigate to the pre-built "Mattermost Log Aggregation" dashboard]*

"This dashboard includes everything you need: log volume by level, error and warning counters, HTTP 4xx/5xx response tracking, error rate over time broken down by server instance, and even a table showing the top recurring error messages."

*[Scroll through dashboard panels]*

"At the bottom, there's a full log browser with dropdown filters for service name, instance, log level, and free-text search. This becomes your single pane of glass for application health across all systems."

"And here's the bigger opportunity: alerting."

*[Point to a panel or metric]*

"Every query you see here can become an alert rule. For example, if the error rate crosses a threshold, trigger a PagerDuty alert. If database connection pools are exhausted, send a Slack notification. You're moving from reactive troubleshooting to proactive incident prevention."

**Talking Points (continued):**

"Let's recap the impact we've seen:
- Investigation time: from 30 minutes down to 5 minutes
- Unified visibility: all logs in one place, correlated by timestamp
- Proactive alerting: catch issues before they escalate
- No application changes: this all runs on existing logs"

**Key Moments:**
- Show or reference the complete Mission Control dashboard
- Emphasize alerting opportunity (prevention vs reaction)
- Quantify the impact: 30 min → 5 min investigation time

---

### SCENE 6: Next Steps (04:40-05:00)

**Talking Points:**

"So here's how to get started with your own Loki setup:

First, grab the dashboard template—it's in the repository at `dashboards/mattermost-loki-logs.json`. Just import it into Grafana and you're ready to go.

Second, follow the step-by-step configuration guide at `source/deploy-loki-log-aggregation.rst`. It walks you through installing Loki on your monitoring server, deploying the OpenTelemetry Collector to each Mattermost server, and configuring everything for production use.

And third, the guide includes a full set of LogQL query examples for common troubleshooting scenarios—HTTP errors, authentication issues, specific server instances—everything you need to get started."

*[Pause]*

"Thanks for watching. Let's turn your scattered logs into centralized clarity."

**Call-to-Action:**
- Import the dashboard: `dashboards/mattermost-loki-logs.json`
- Follow the configuration guide: `source/deploy-loki-log-aggregation.rst`
- Explore LogQL query examples in the guide

**Resources:**
- Dashboard Template: `dashboards/mattermost-loki-logs.json`
- Configuration Guide: `source/deploy-loki-log-aggregation.rst`
- Config Files: `config/loki-config.yaml` and `config/otel-collector-config.yaml`
- GitHub Repository: [Your repo URL]

---

## Notes for Presenter

**Recording Tips:**
- **Record in segments**: You can record each scene separately and edit together later
- **Pause for query rendering**: Let each query result render for 2-3 seconds so viewers can process—you can trim excess silence in editing
- **Slow down for complex sections**: The dashboard customization (02:45-04:00) has multiple steps; speak deliberately and let actions complete
- **Energy in recap and CTA**: The impact section (04:00-04:40) and closing should be energetic and confident
- **Clean up UI**: Hide browser bookmarks bar, close unnecessary tabs, turn off desktop notifications
- **Test everything first**: Run all queries before recording to ensure they return data and load reasonably fast

**Voiceover Best Practices:**
- Record audio separately if needed—you can use the script as written, then sync voiceover to screen recording
- Avoid "um," "uh," filler words—pause and re-record that sentence
- Smile while talking—it comes through in your voice
- Vary your tone and energy to maintain engagement
- Don't apologize or hedge ("this might be slow," "hopefully this works")—just show confidence

**Common Viewer Questions (address proactively in narration):**
- "Does this replace our logging infrastructure?" → Addressed in opening ("no code changes needed")
- "How much does this cost?" → Loki is open source (mention if relevant)
- "Can we use our existing Grafana?" → Yes, Loki is a data source plugin

**Things to Avoid:**
- Don't say "obviously" or "clearly"—not everyone will find it obvious
- Don't get deep into LogQL syntax—show simple, powerful examples
- Don't skip the impact section (04:00-04:40)—this is where business value lands
- Avoid meta-commentary like "as you can see here"—viewers can see; just explain what's happening

**Optional Additions (if running short):**
- Show the log context feature (click a log line to see surrounding context)
- Demonstrate a regex filter: `{service_name="mattermost"} |~ "(?i)(auth|login|token)"`
- Show filtering by specific server: `{service_name="mattermost", service_instance_id="mm-app-01"}`
- Mention the top errors table query: `topk(5, sum(count_over_time(...)) by (msg))`

**Cut if Running Long:**
- Skip the second dashboard panel creation (keep just one example)
- Shorten the dashboard scrolling at 04:00 (quick pass instead of detailed)
- Combine Scene 5 and 6 (go from dashboard directly to CTA)

**Post-Production:**
- Add title card at the beginning with demo title and your name
- Add text overlays for key queries or important concepts
- Consider adding soft background music (low volume, non-distracting)
- Add end card with resources and contact info
- Export at 1080p, 30fps minimum

---

## Technical Checklist

**Before Recording:**
- [ ] Verify load test is running and generating logs
- [ ] Confirm Loki is receiving logs: `curl -s http://localhost:3100/ready` should return "ready"
- [ ] Verify OpenTelemetry Collector is running on Mattermost servers: `sudo systemctl status otelcol-contrib`
- [ ] Test all LogQL queries in Grafana Explore (copy-paste from script)
- [ ] Confirm "Mattermost Log Aggregation" dashboard is imported and populated
- [ ] Set Grafana time range to "Last 15 minutes" or "Last 1 hour" for live data
- [ ] Clear browser cache, close unnecessary tabs, hide bookmarks bar
- [ ] Disable desktop notifications (Slack, email, etc.)
- [ ] Test screen recording software and audio levels
- [ ] Run a practice recording to check timing (should be ~4:30-5:00)

**Environment Assumptions:**
- Grafana version: 10.0+ (for modern Loki integration)
- Loki data source configured and healthy in Grafana
- Labels used: `service_name="mattermost"`, `service_name="postgres"`, `service_instance_id`
- Log format: JSON (Mattermost default) with fields like `level`, `status_code`, `msg`
- OpenTelemetry Collector shipping logs to Loki via OTLP HTTP endpoint (:3100/otlp)

**Queries to Pre-Test:**
1. `{service_name="mattermost"}` → Should return recent logs
2. `{service_name="mattermost"} | json | level="error"` → Should return errors (if any)
3. `{service_name="mattermost"} | json | status_code >= 400` → Should return HTTP errors (if any)
4. Dashboard panels should all populate with data

---

---

## Bonus Scene (Optional): Metrics + Logs Correlation

If you want to extend the demo to show the power of correlating metrics and logs side-by-side in Grafana, add this scene after Scene 3 or Scene 5:

**Scene: Unified Observability (02:45-03:45) - Optional**

*[Navigate to Grafana Explore, click "Split" view button]*

**Talking Points:**
"One of the most powerful features is correlating metrics and logs on the same timeline. Let me show you."

*[Configure left panel with Prometheus data source]*

**Demo Actions (Left Panel - Prometheus):**
```promql
sum(rate(mattermost_api_time_count[5m])) by (instance)
```

**Talking Points:**
"On the left, I'm showing API request rate from Prometheus—our metrics data source."

*[Configure right panel with Loki data source]*

**Demo Actions (Right Panel - Loki):**
```logql
{service_name="mattermost"} | json | level="error"
```

**Talking Points:**
"On the right, I'm showing error logs from Loki. Now watch this—"

*[Click the "Link" icon to sync time ranges]*
*[Zoom in on a spike in the metrics graph]*

**Talking Points:**
"When I zoom in on a spike in API traffic, the logs automatically filter to that same timeframe. I can immediately see what errors were happening during that spike. This is how you go from 'we have a problem' to 'here's the root cause' in seconds."

**Key Moments:**
- Emphasize the synchronized time ranges
- Show how zooming on one side affects the other
- Mention this is built-in Grafana functionality, no custom integration needed

---

**Good luck with your recording! You've got a powerful story to tell about transforming chaos into clarity.**
