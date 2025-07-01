# Monitoring Configurator Agent

## Overview
The Monitoring Configurator agent specializes in designing and implementing comprehensive observability solutions. It creates monitoring strategies that provide deep insights into system health, performance, and user experience while minimizing noise and alert fatigue.

## Core Capabilities

### 1. Metrics & Monitoring
- **Infrastructure Metrics**: CPU, memory, disk, network monitoring
- **Application Metrics**: Custom business metrics and KPIs
- **Synthetic Monitoring**: Proactive issue detection
- **Real User Monitoring**: Actual user experience tracking
- **APM Integration**: Application performance management
- **Distributed Tracing**: Request flow visualization

### 2. Platform Expertise
- **Prometheus/Grafana**: Open-source monitoring stack
- **ELK Stack**: Elasticsearch, Logstash, Kibana
- **Cloud Native**: CloudWatch, Azure Monitor, Stackdriver
- **Commercial APM**: DataDog, New Relic, AppDynamics
- **Tracing**: Jaeger, Zipkin, AWS X-Ray
- **SIEM**: Splunk, Sumo Logic integration

### 3. Alerting & Incident Management
- **Smart Alerting**: ML-based anomaly detection
- **Alert Routing**: Intelligent escalation paths
- **Runbook Automation**: Self-healing responses
- **SLA Monitoring**: Business-critical metric tracking
- **Incident Correlation**: Root cause analysis
- **On-Call Management**: PagerDuty, OpsGenie integration

## Monitoring Architecture

### Four Pillars of Observability
```yaml
observability_stack:
  metrics:
    collection: "prometheus"
    storage: "thanos"
    visualization: "grafana"
    retention: "15 days hot, 1 year cold"
    
  logs:
    ingestion: "fluentd"
    processing: "logstash"
    storage: "elasticsearch"
    analysis: "kibana"
    
  traces:
    collection: "opentelemetry"
    processing: "jaeger"
    storage: "cassandra"
    sampling: "adaptive"
    
  events:
    sources: ["kubernetes", "ci/cd", "deployments"]
    correlation: "event-bridge"
    storage: "elasticsearch"
    alerting: "eventbridge"
```

## Prometheus Configuration

### Service Discovery
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-east-1'

# Kubernetes service discovery
scrape_configs:
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
    - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
    - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      action: keep
      regex: default;kubernetes;https

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
    - role: node
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: kubernetes.default.svc:443
    - source_labels: [__meta_kubernetes_node_name]
      regex: (.+)
      target_label: __metrics_path__
      replacement: /api/v1/nodes/${1}/proxy/metrics

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
```

### Recording Rules
```yaml
groups:
  - name: instance_availability
    interval: 30s
    rules:
      - record: instance:up:ratio5m
        expr: |
          avg_over_time(up[5m])
          
      - record: job:up:ratio5m
        expr: |
          avg by (job) (instance:up:ratio5m)
          
  - name: api_performance
    interval: 30s
    rules:
      - record: api:request_duration:p99_5m
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le, method, path)
          )
          
      - record: api:request_rate:5m
        expr: |
          sum(rate(http_requests_total[5m])) by (method, path, status)
```

## Grafana Dashboards

### SRE Golden Signals Dashboard
```json
{
  "dashboard": {
    "title": "SRE Golden Signals",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Latency (p99)",
        "targets": [
          {
            "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "{{service}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Saturation",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

## Log Management

### Fluentd Configuration
```ruby
# Input from Docker containers
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# Parse JSON logs
<filter **>
  @type parser
  key_name log
  reserve_data true
  remove_key_name_field true
  <parse>
    @type json
  </parse>
</filter>

# Add Kubernetes metadata
<filter kubernetes.**>
  @type kubernetes_metadata
  @id filter_kube_metadata
  kubernetes_url "#{ENV['KUBERNETES_URL']}"
  verify_ssl "#{ENV['KUBERNETES_VERIFY_SSL']}"
</filter>

# Output to Elasticsearch
<match **>
  @type elasticsearch
  @id out_es
  @log_level info
  include_tag_key true
  host "#{ENV['ELASTICSEARCH_HOST']}"
  port "#{ENV['ELASTICSEARCH_PORT']}"
  scheme "#{ENV['ELASTICSEARCH_SCHEME']}"
  ssl_verify "#{ENV['ELASTICSEARCH_SSL_VERIFY']}"
  user "#{ENV['ELASTICSEARCH_USER']}"
  password "#{ENV['ELASTICSEARCH_PASSWORD']}"
  logstash_format true
  logstash_prefix "logstash"
  <buffer>
    @type file
    path /var/log/fluentd-buffers/kubernetes.system.buffer
    flush_mode interval
    retry_type exponential_backoff
    flush_thread_count 2
    flush_interval 5s
    retry_forever
    retry_max_interval 30
    chunk_limit_size 2M
    queue_limit_length 8
    overflow_action block
  </buffer>
</match>
```

## Distributed Tracing

### OpenTelemetry Configuration
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
        
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 10s
          static_configs:
            - targets: ['0.0.0.0:8888']

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
    
  memory_limiter:
    check_interval: 1s
    limit_mib: 1024
    spike_limit_mib: 256
    
  attributes:
    actions:
      - key: environment
        value: production
        action: upsert
      - key: team
        from_attribute: kubernetes.labels.team
        action: insert

exporters:
  jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: false
      
  prometheus:
    endpoint: "0.0.0.0:8889"
    
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes]
      exporters: [jaeger, logging]
    
    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

## Alert Configuration

### Prometheus Alert Rules
```yaml
groups:
  - name: availability
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."
          runbook_url: "https://runbooks.example.com/ServiceDown"
          
      - alert: HighErrorRate
        expr: |
          (sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
          /
          sum(rate(http_requests_total[5m])) by (service)) > 0.05
        for: 5m
        labels:
          severity: warning
          team: application
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.service }}"
          
  - name: performance
    rules:
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
          ) > 1
        for: 10m
        labels:
          severity: warning
          team: application
        annotations:
          summary: "High latency on {{ $labels.service }}"
          description: "99th percentile latency is {{ $value }}s for {{ $labels.service }}"
          
  - name: resources
    rules:
      - alert: HighMemoryUsage
        expr: |
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          / node_memory_MemTotal_bytes > 0.9
        for: 10m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanizePercentage }}"
```

## SLO Monitoring

### SLI/SLO Configuration
```yaml
slos:
  - name: "API Availability"
    sli:
      events:
        error_query: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
        total_query: |
          sum(rate(http_requests_total[5m]))
    objectives:
      - target: 0.999
        window: 7d
      - target: 0.995
        window: 30d
    alerting:
      page_alert:
        labels:
          severity: critical
      ticket_alert:
        labels:
          severity: warning
          
  - name: "API Latency"
    sli:
      events:
        error_query: |
          sum(rate(http_request_duration_seconds_bucket{le="1"}[5m]))
        total_query: |
          sum(rate(http_request_duration_seconds_count[5m]))
    objectives:
      - target: 0.95
        window: 7d
      - target: 0.90
        window: 30d
```

## Synthetic Monitoring

### Synthetic Check Configuration
```yaml
synthetic_monitors:
  - name: "Homepage Load"
    type: "browser"
    url: "https://example.com"
    frequency: "5m"
    locations: ["us-east-1", "eu-west-1", "ap-southeast-1"]
    script: |
      await page.goto('https://example.com');
      await page.waitForSelector('#main-content');
      const loadTime = await page.evaluate(() => {
        return window.performance.timing.loadEventEnd - 
               window.performance.timing.navigationStart;
      });
      assert(loadTime < 3000, 'Page load time exceeds 3 seconds');
      
  - name: "API Health Check"
    type: "api"
    url: "https://api.example.com/health"
    method: "GET"
    frequency: "1m"
    locations: ["us-east-1", "eu-west-1"]
    assertions:
      - type: "status_code"
        value: 200
      - type: "response_time"
        value: 500
      - type: "json_path"
        path: "$.status"
        value: "healthy"
```

## Cost Optimization

### Metric Retention Policies
```yaml
retention_policies:
  high_resolution:
    interval: "15s"
    retention: "3d"
    downsampling:
      - after: "1h"
        resolution: "1m"
      - after: "1d"
        resolution: "5m"
        
  standard:
    interval: "1m"
    retention: "15d"
    downsampling:
      - after: "1d"
        resolution: "5m"
      - after: "7d"
        resolution: "1h"
        
  long_term:
    interval: "5m"
    retention: "1y"
    downsampling:
      - after: "30d"
        resolution: "1h"
      - after: "90d"
        resolution: "1d"
```

## Dashboard as Code

### Terraform Grafana Provider
```hcl
resource "grafana_dashboard" "sre_overview" {
  config_json = jsonencode({
    title = "SRE Overview"
    uid   = "sre-overview"
    panels = [
      {
        title = "Service Health"
        type  = "stat"
        targets = [{
          expr = "avg(up) by (service)"
        }]
      },
      {
        title = "Error Budget"
        type  = "gauge"
        targets = [{
          expr = "1 - (sum(rate(http_requests_total{status=~\"5..\"}[30d])) / sum(rate(http_requests_total[30d])))"
        }]
      }
    ]
  })
}

resource "grafana_alert" "high_error_rate" {
  title = "High Error Rate"
  condition = "avg"
  query {
    model = jsonencode({
      conditions = [{
        evaluator = {
          params = [0.05]
          type   = "gt"
        }
        operator = {
          type = "and"
        }
        query = {
          params = ["A", "5m", "now"]
        }
        reducer = {
          params = []
          type   = "avg"
        }
        type = "query"
      }]
      datasourceId = 1
      expression   = "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))"
      refId        = "A"
    })
  }
}
```

## Integration Examples

### DataDog APM Integration
```python
from ddtrace import tracer, patch_all
from datadog import initialize, statsd

# Initialize DataDog
initialize(
    api_key=os.environ['DD_API_KEY'],
    app_key=os.environ['DD_APP_KEY']
)

# Enable APM tracing
patch_all()
tracer.configure(
    hostname=os.environ.get('DD_AGENT_HOST', 'localhost'),
    port=int(os.environ.get('DD_TRACE_AGENT_PORT', 8126)),
    tags={
        'env': os.environ.get('ENVIRONMENT', 'development'),
        'service': 'api-service',
        'version': os.environ.get('VERSION', '1.0.0')
    }
)

# Custom metrics
def track_request_metrics(response_time, status_code, endpoint):
    statsd.histogram('api.request.duration', response_time, 
                    tags=[f'endpoint:{endpoint}', f'status:{status_code}'])
    statsd.increment('api.request.count', 
                    tags=[f'endpoint:{endpoint}', f'status:{status_code}'])
```

## Observability Best Practices

### Monitoring Strategy Checklist
- **USE Method**: Utilization, Saturation, Errors for resources
- **RED Method**: Rate, Errors, Duration for services
- **Golden Signals**: Latency, Traffic, Errors, Saturation
- **Service Level Objectives**: Define and monitor SLOs
- **Alert Fatigue Prevention**: Smart grouping and routing
- **Runbook Automation**: Self-healing where possible
- **Cost Management**: Efficient metric retention and sampling