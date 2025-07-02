# MetaClaude Monitoring System

Enhanced monitoring capabilities for the Tool Execution Service (TES) with detailed error tracking, resource monitoring, and performance metrics.

## Components

### 1. Enhanced Tool Execution Service (TES)
**Location:** `/core/tool-execution-service.py`

#### New Features:
- **Error Categorization**: TIMEOUT, VALIDATION, DEPENDENCY, EXECUTION, PERMISSION, RESOURCE, UNKNOWN
- **Resource Tracking**: Memory usage (start/end/peak), CPU time, wall time
- **Retry Logic**: Automatic retry with exponential backoff for transient failures
- **Detailed Error Context**: Suggestions for resolving common errors
- **Execution Lifecycle Logging**: Timestamps and detailed execution flow

#### Error Details Structure:
```python
ErrorDetails(
    category=ErrorCategory.TIMEOUT,
    message="Script execution timed out after 30000ms",
    context={
        'script_id': 'validate_api_schema',
        'script_path': 'specialists/api-ui-designer/validate-api-schema.py',
        'specialist': 'api-ui-designer'
    },
    suggestions=[
        "Increase the timeout value in the script configuration",
        "Optimize the script to run faster",
        "Check for infinite loops or blocking operations"
    ],
    stack_trace="..."  # Full Python stack trace if available
)
```

### 2. Execution Logger
**Location:** `/monitoring/execution-logger.py`

Structured logging system for all script executions with:
- JSON Lines format for easy parsing
- Automatic log rotation and compression
- Configurable retention policies
- Query interface for log analysis

#### Features:
- **Log Levels**: DEBUG, INFO, WARN, ERROR
- **Automatic Rotation**: By size (default 100MB) and daily
- **Compression**: Gzip compression for rotated logs
- **Retention**: Configurable days to keep logs (default 30 days)
- **Async Logging**: Non-blocking writes for performance

#### Usage:
```python
from monitoring.execution_logger import ExecutionLogger

logger = ExecutionLogger()
logger.log_execution(
    script_id='validate_api_schema',
    specialist='api-ui-designer',
    inputs={'schema_file': 'api.yaml'},
    result=execution_result,
    session_id='session-123',
    correlation_id='request-456'
)
```

#### Query Interface:
```bash
# View recent failures
./execution-logger.py --failed --limit 20

# Show statistics for the last hour
./execution-logger.py --stats --start-date "$(date -v-1H '+%Y-%m-%d %H:%M:%S')"

# Export as JSON for analysis
./execution-logger.py --json --specialist "api-ui-designer" > api_logs.json

# Group statistics by user
./execution-logger.py --stats --group-by user
```

### 3. Metrics Collector
**Location:** `/monitoring/metrics-collector.py`

Real-time metrics collection with multiple export formats:
- **Prometheus Format**: For integration with monitoring stacks
- **StatsD Protocol**: For real-time metrics streaming
- **Internal Aggregation**: Histograms with percentiles (p50, p90, p95, p99)

#### Metrics Tracked:
- `metaclaude.executions.total`: Total execution count
- `metaclaude.executions.success`: Successful executions
- `metaclaude.executions.failure`: Failed executions (tagged by error category)
- `metaclaude.execution.duration_seconds`: Execution duration histogram
- `metaclaude.resource.memory_peak_mb`: Peak memory usage
- `metaclaude.resource.cpu_time_seconds`: CPU time consumption
- `metaclaude.executions.retries`: Retry attempts

#### Usage:
```python
from monitoring.metrics_collector import MetricsCollector

collector = MetricsCollector(statsd_host='localhost')
collector.record_execution(
    script_id='validate_api_schema',
    specialist='api-ui-designer',
    result=execution_result
)
```

#### Export Formats:
```bash
# Prometheus format
./metrics-collector.py --prometheus

# Generate report
./metrics-collector.py --report --period 60 --json

# Show current metrics
./metrics-collector.py --current
```

### 4. Monitoring Integration
**Location:** `/core/monitoring-integration.py`

Seamless integration layer that combines TES with monitoring:

```python
from core.monitoring_integration import create_monitored_tes

# Create TES with monitoring enabled
tes = create_monitored_tes(
    enable_logging=True,
    enable_metrics=True,
    statsd_host='metrics.example.com'
)

# Execute with automatic monitoring
result = tes.execute(
    'validate_api_schema',
    {'schema_file': 'api.yaml'},
    session_id='session-123'
)

# Get execution statistics
stats = tes.get_execution_stats()

# Export Prometheus metrics
metrics = tes.export_prometheus_metrics()
```

### 5. Web Monitoring Dashboard
**Location:** `/monitoring/dashboard.py`

Web-based monitoring dashboard with real-time updates via WebSocket:

```bash
# Run web dashboard (default ports: HTTP 8080, WebSocket 8081)
./dashboard.py

# Custom ports
./dashboard.py --http-port 8888 --ws-port 8889
```

Features:
- **Real-time Updates**: WebSocket connection for live data
- **Summary Metrics**: Total executions, success rate, average duration
- **Active Alerts**: Real-time alert notifications
- **Top Scripts**: Performance breakdown by script and specialist
- **Recent Executions**: Live feed of script executions
- **Error Analysis**: Categorized error breakdown

### 6. Terminal Monitoring Dashboard
**Location:** `/monitoring/dashboard-terminal.py`

Terminal-based real-time monitoring dashboard:

```bash
# Run interactive terminal dashboard
./dashboard-terminal.py

# Text-mode output (for logging)
./dashboard-terminal.py --text
```

Features:
- Real-time execution status
- Success/failure rates
- Top scripts by execution count
- Recent execution history
- Active metrics summary

### 7. Alert System

The metrics collector includes automatic alert detection for anomalies:

#### Alert Thresholds:
- **Error Rate**: Triggers when error rate exceeds 10% (configurable)
- **P95 Duration**: Alerts when 95th percentile duration exceeds 30s
- **Memory Usage**: Warns when peak memory exceeds 1GB
- **Execution Rate**: Detects 50% drops in execution rate

#### Configuration:
```python
from monitoring.metrics_collector import MetricsCollector

collector = MetricsCollector()

# Set custom thresholds
collector.set_alert_threshold('error_rate_percent', 15.0)
collector.set_alert_threshold('p95_duration_seconds', 60.0)
collector.set_alert_threshold('memory_peak_mb', 2048.0)

# Register alert callback
def on_alert(alerts):
    for alert in alerts:
        print(f"ALERT [{alert['severity']}]: {alert['message']}")
        # Send to Slack, PagerDuty, etc.

collector.register_alert_callback(on_alert)
```

#### Alert Structure:
```json
{
    "timestamp": "2024-01-15T10:30:45",
    "type": "error_rate_high",
    "severity": "warning",  // or "critical"
    "message": "Error rate is 15.3% (threshold: 10.0%)",
    "value": 15.3,
    "threshold": 10.0,
    "specialist": "api-ui-designer"  // optional
}
```

## Integration with Existing TES

### Direct Usage:
```python
from core.tool_execution_service import ToolExecutionService

tes = ToolExecutionService('registry.json')
result = tes.execute('script_id', {'arg': 'value'})

# Access enhanced error information
if not result.success and result.error_details:
    print(f"Error Category: {result.error_details.category.value}")
    print(f"Suggestions:")
    for suggestion in result.error_details.suggestions:
        print(f"  - {suggestion}")

# Check resource usage
if result.resource_usage:
    print(f"Peak Memory: {result.resource_usage.peak_memory_mb}MB")
    print(f"CPU Time: {result.resource_usage.cpu_time_seconds}s")
```

### With Monitoring:
```python
from core.monitoring_integration import MonitoredToolExecutionService

# Use monitored version for automatic logging and metrics
tes = MonitoredToolExecutionService('registry.json')
result = tes.execute('script_id', {'arg': 'value'})
```

## Configuration

### Environment Variables:
- `METACLAUDE_LOG_DIR`: Custom log directory (default: `.claude/logs/executions`)
- `METACLAUDE_METRICS_HOST`: StatsD host for metrics
- `METACLAUDE_METRICS_PORT`: StatsD port (default: 8125)

### Log Retention:
Configure in `ExecutionLogger` initialization:
```python
logger = ExecutionLogger(
    rotation_size_mb=100,      # Rotate at 100MB
    retention_days=30,         # Keep logs for 30 days
    async_logging=True         # Non-blocking writes
)
```

## Best Practices

1. **Always use correlation IDs** for tracking related executions
2. **Monitor error categories** to identify systemic issues
3. **Set up alerts** for high failure rates or resource usage
4. **Regular log analysis** to optimize script performance
5. **Export metrics** to your monitoring stack (Prometheus, Grafana)

## Troubleshooting

### High Memory Usage:
1. Check `peak_memory_mb` in execution logs
2. Review scripts with consistently high memory usage
3. Adjust memory limits in script registry

### Timeout Issues:
1. Check execution duration trends
2. Identify scripts that frequently timeout
3. Optimize slow scripts or increase timeout values

### Permission Errors:
1. Review sandbox configuration
2. Check file permissions for script files
3. Verify required permissions in script registry

## Dependencies

- `psutil`: For resource monitoring
- `websockets`: For real-time web dashboard
- Python 3.7+: For dataclasses and type hints
- Standard library: json, gzip, threading, curses, asyncio

Install dependencies:
```bash
pip install psutil websockets
```