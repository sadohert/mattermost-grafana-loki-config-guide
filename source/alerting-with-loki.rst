Log Alerting with Grafana and Loki
==================================

|entry-ent|

.. |entry-ent| raw:: html

   <span class="badge badge--entry">Plans: Entry, Enterprise, Enterprise Advanced</span>

This guide explains how to set up proactive alerts in Grafana based on specific strings or patterns appearing in your logs. While the `initial Loki guide </administration-guide/scale/deploy-loki-log-aggregation>`_ focuses on log exploration, this guide helps you move from reactive troubleshooting to proactive incident detection.

Use cases for Log Alerting:
- **Security**: Alert on multiple failed login attempts or unauthorized access patterns.
- **Application Health**: Alert on specific "Critical" or "Fatal" error strings.
- **Integration issues**: Alert when a specific plugin or external service integration fails.
- **Performance**: Alert on "Slow query" or "Request timeout" messages.

Prerequisites
-------------

- Grafana and Loki deployed and configured per the `Loki log aggregation guide </administration-guide/scale/deploy-loki-log-aggregation>`_.
- Mattermost application logs being shipped to Loki with the `service_name` label.
- Grafana alert contact points (e.g., Slack, PagerDuty, Email) already configured.

Step 1: Define your LogQL alert query
-------------------------------------

Loki alerts are based on **LogQL**. To create an alert, you must convert a log stream into a numerical value (a metric) that Grafana can evaluate against a threshold.

1. Navigate to **Explore** in Grafana and select your **Loki** data source.
2. Draft a query to find the specific logs you want to alert on. 

**Example: Alert on "panic" or "fatal" errors in Mattermost logs**

.. code-block:: text

   {service_name="mattermost"} | json | msg =~ "(?i).*panic.*|.*fatal.*"

3. Once you've verified the logs appear, wrap the query in a metric function like ``count_over_time``. This counts how many matching lines occurred in a specific window (e.g., 5 minutes).

.. code-block:: text

   sum(count_over_time({service_name="mattermost"} | json | msg =~ "(?i).*panic.*|.*fatal.*" [5m]))

.. tip::

   **Why use sum()?** Using ``sum(...)`` ensures that if the error happens across multiple server instances, the alert evaluates the total count. If you want to alert per-instance — and have ``{{ $labels.service_instance_id }}`` available in your annotation templates — use ``sum(...) by (service_instance_id)`` instead. Labels dropped by aggregation are not available in ``$labels``.

Step 2: Create a Grafana Alert Rule
-----------------------------------

1. In Grafana, go to **Alerting > Alert rules**.
2. Select **Create alert rule**.
3. **Step 1: Enter alert rule name**: Give it a descriptive name (e.g., "Mattermost Critical Log Errors").
4. **Step 2: Define query and alert condition**:
   - **Data source**: Select **Loki**.
   - **Query**: Paste your metric-based LogQL from Step 1.
   - **Expressions**: 
     - Grafana typically adds a **Reduce** expression (`A`) and a **Threshold** expression (`B`).
     - Set the **Reduce** function to `Last` (to get the most recent count).
     - Set the **Threshold** to `Is above` and enter your limit (e.g., `0` if any occurrence should trigger an alert).
5. **Step 3: Set evaluation behavior**:
   - **Folder**: Choose or create a folder for your alerts.
   - **Evaluation group**: Create a new group (e.g., "log-alerts").
   - **Evaluation interval**: How often to run the check (e.g., `1m`).
   - **Pending period (For)**: How long the condition must be met before firing (e.g., `0m` for instant alerts, or `5m` to filter out blips).
6. **Step 4: Add annotations**:
   - **Summary**: "Critical error detected in {{ $labels.service_name }} logs."
   - **Description**: "{{ $values.A.Value | printf \"%.0f\" }} matching log lines detected. Search Loki for ``{service_name=\"{{ $labels.service_name }}\"}`` to investigate."

   .. note::

      ``$labels`` contains only the labels that survive your LogQL aggregation. With ``sum(count_over_time(...))`` (no ``by`` clause), only stream selector labels like ``service_name`` are available. If you want ``{{ $labels.service_instance_id }}`` in your annotations, use ``sum(count_over_time(...)) by (service_instance_id)`` in your query — this fires one alert per instance and makes ``service_instance_id`` available in ``$labels``. ``$values.A.Value`` is always available and contains the numeric result of your query.

Step 3: Configure Notifications
-------------------------------

1. **Step 5: Notifications**:
   - Assign the alert to a **Notification Policy**.
   - Use custom labels if you want certain alerts to go to specific teams (e.g., `team=devops`).
2. Select **Save rule and exit**.

Useful Alerting Queries
-----------------------

**Detect high error rate (over 10 errors in 5 minutes):**

.. code-block:: text

   sum(count_over_time({service_name="mattermost"} | json | detected_level="error" [5m])) > 10

**Detect database connection pool issues:**

.. code-block:: text

   sum(count_over_time({service_name="mattermost"} |~ "connection pool" [2m])) > 0

**Detect specific plugin failures:**

.. code-block:: text

   sum(count_over_time({service_name="mattermost"} |~ "plugin_id=.*com.mattermost.aws-sns.*" |~ "failed" [5m]))

Best Practices
--------------

- **Avoid noisy alerts**: Don't alert on common "Warnings". Start with "Error" or "Fatal" levels.
- **Use labels**: Ensure your OTel Collector configuration provides enough metadata (like `service_instance_id`) so your alert notifications tell you exactly *where* the issue is happening.
- **Test with Explore**: Always run your query in the Explore tab first to see the data over time before creating the alert.
- **Retention**: Remember that Loki only alerts on data within its retention period. If Loki is down or data is missing, alerts will not fire.
