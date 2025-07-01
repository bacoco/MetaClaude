# Deployment Strategist Agent

## Overview
The Deployment Strategist agent specializes in designing and implementing sophisticated deployment strategies that minimize risk, ensure high availability, and enable rapid rollback. It analyzes application architecture, traffic patterns, and business requirements to recommend optimal deployment approaches.

## Core Capabilities

### 1. Deployment Strategy Design
- **Blue-Green Deployments**: Zero-downtime deployments with instant rollback
- **Canary Releases**: Progressive rollout with monitoring and automatic rollback
- **Rolling Updates**: Gradual replacement with health checks
- **Feature Flags**: Dark launches and percentage-based rollouts
- **A/B Testing**: Traffic splitting for experimentation
- **Shadow Deployments**: Risk-free production testing

### 2. Platform Expertise
- **Kubernetes**: Advanced deployment configurations and operators
- **AWS ECS/Fargate**: Task definition management and service updates
- **Serverless**: Lambda versioning and alias management
- **Traditional VMs**: Orchestrated instance replacement
- **Edge Computing**: CDN and edge function deployments
- **Multi-Region**: Coordinated global deployments

### 3. Risk Management
- **Health Checks**: Comprehensive readiness and liveness probes
- **Circuit Breakers**: Automatic failure isolation
- **Rollback Automation**: Instant reversion on failure detection
- **Smoke Tests**: Post-deployment validation
- **Chaos Engineering**: Failure injection testing
- **Disaster Recovery**: RTO/RPO optimization

## Deployment Patterns

### Blue-Green Deployment
```yaml
deployment_strategy:
  type: blue_green
  parameters:
    target_group_swap:
      blue_target_group: "app-blue-tg"
      green_target_group: "app-green-tg"
    validation:
      smoke_tests:
        - endpoint: "/health"
          expected_status: 200
        - endpoint: "/api/version"
          expected_response: "${new_version}"
    traffic_switch:
      method: "dns_weighted_routing"
      switch_time: "instant"
    rollback:
      automatic: true
      conditions:
        - error_rate: "> 5%"
        - response_time: "> 1000ms"
```

### Canary Release Strategy
```yaml
canary_deployment:
  stages:
    - name: "initial"
      traffic_percentage: 5
      duration: "10m"
      success_criteria:
        error_rate: "< 1%"
        p99_latency: "< 500ms"
    - name: "expansion"
      traffic_percentage: 25
      duration: "30m"
      success_criteria:
        error_rate: "< 1%"
        p99_latency: "< 500ms"
    - name: "final"
      traffic_percentage: 100
      duration: "1h"
  monitoring:
    metrics:
      - "error_rate"
      - "latency_p50"
      - "latency_p99"
      - "cpu_utilization"
      - "memory_utilization"
  rollback:
    automatic: true
    preserve_metrics: true
```

### Feature Flag Integration
```javascript
// LaunchDarkly configuration
const featureFlagConfig = {
  flags: {
    "new-checkout-flow": {
      variations: {
        control: { enabled: false },
        treatment: { enabled: true }
      },
      targeting: {
        default: "control",
        rules: [
          {
            variation: "treatment",
            clauses: [
              {
                attribute: "segment",
                op: "in",
                values: ["beta_users"]
              }
            ]
          }
        ]
      },
      rollout: {
        variations: [
          { variation: "control", weight: 95 },
          { variation: "treatment", weight: 5 }
        ]
      }
    }
  }
};
```

## Kubernetes Deployments

### Progressive Delivery with Flagger
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: frontend
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  progressDeadlineSeconds: 60
  service:
    port: 80
    targetPort: 8080
    gateways:
    - public-gateway.istio-system.svc.cluster.local
    hosts:
    - app.example.com
  analysis:
    interval: 30s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 30s
    webhooks:
    - name: load-test
      url: http://flagger-loadtester.test/
      timeout: 5s
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://frontend-canary.test:80/"
```

### GitOps Deployment
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-example
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 40
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 80
      - pause: {duration: 10m}
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
        args:
        - name: service-name
          value: rollout-example
```

## AWS Deployment Strategies

### ECS Blue-Green with CodeDeploy
```json
{
  "version": 1,
  "Resources": [
    {
      "TargetService": {
        "Type": "AWS::ECS::Service",
        "Properties": {
          "TaskDefinition": "<NEW_TASK_DEFINITION>",
          "LoadBalancerInfo": {
            "ContainerName": "app",
            "ContainerPort": 80
          },
          "PlatformVersion": "LATEST",
          "NetworkConfiguration": {
            "AwsvpcConfiguration": {
              "Subnets": ["subnet-12345", "subnet-67890"],
              "SecurityGroups": ["sg-12345"],
              "AssignPublicIp": "DISABLED"
            }
          }
        }
      }
    }
  ],
  "Hooks": [
    {
      "BeforeAllowTestTraffic": "arn:aws:lambda:region:account:function:CodeDeployHook_preTrafficHook"
    },
    {
      "AfterAllowTestTraffic": "arn:aws:lambda:region:account:function:CodeDeployHook_postTrafficHook"
    },
    {
      "BeforeAllowTraffic": "arn:aws:lambda:region:account:function:CodeDeployHook_preAllowTraffic"
    },
    {
      "AfterAllowTraffic": "arn:aws:lambda:region:account:function:CodeDeployHook_postAllowTraffic"
    }
  ]
}
```

### Lambda Canary Deployment
```python
import boto3
import json

def deploy_lambda_canary(function_name, new_version, canary_percentage=10):
    lambda_client = boto3.client('lambda')
    
    # Publish new version
    version_response = lambda_client.publish_version(
        FunctionName=function_name,
        Description=f'Deployment version {new_version}'
    )
    
    # Update alias with weighted routing
    alias_response = lambda_client.update_alias(
        FunctionName=function_name,
        Name='live',
        FunctionVersion=version_response['Version'],
        RoutingConfig={
            'AdditionalVersionWeights': {
                version_response['Version']: canary_percentage / 100.0
            }
        }
    )
    
    return {
        'version': version_response['Version'],
        'canary_percentage': canary_percentage,
        'alias': alias_response['AliasArn']
    }
```

## Multi-Region Deployment

### Global Traffic Management
```yaml
multi_region_deployment:
  regions:
    - name: "us-east-1"
      weight: 40
      primary: true
    - name: "eu-west-1"
      weight: 30
      primary: false
    - name: "ap-southeast-1"
      weight: 30
      primary: false
  
  deployment_order:
    - region: "ap-southeast-1"
      canary_percentage: 10
      validation_time: "30m"
    - region: "eu-west-1"
      canary_percentage: 10
      validation_time: "30m"
    - region: "us-east-1"
      canary_percentage: 5
      validation_time: "1h"
  
  health_checks:
    interval: 30
    timeout: 10
    healthy_threshold: 2
    unhealthy_threshold: 3
  
  failover:
    automatic: true
    dns_ttl: 60
```

## Rollback Strategies

### Automated Rollback
```python
class RollbackManager:
    def __init__(self, deployment_id):
        self.deployment_id = deployment_id
        self.metrics_client = MetricsClient()
        self.deployment_client = DeploymentClient()
    
    def monitor_deployment(self):
        baseline_metrics = self.get_baseline_metrics()
        current_metrics = self.get_current_metrics()
        
        if self.should_rollback(baseline_metrics, current_metrics):
            self.execute_rollback()
    
    def should_rollback(self, baseline, current):
        conditions = [
            current['error_rate'] > baseline['error_rate'] * 1.5,
            current['p99_latency'] > baseline['p99_latency'] * 2,
            current['success_rate'] < 0.95,
            current['cpu_utilization'] > 0.90
        ]
        return any(conditions)
    
    def execute_rollback(self):
        # Capture current state for analysis
        self.capture_failure_state()
        
        # Execute rollback
        self.deployment_client.rollback(self.deployment_id)
        
        # Notify team
        self.send_rollback_notification()
```

## Testing Strategies

### Smoke Test Suite
```yaml
smoke_tests:
  critical_paths:
    - name: "API Health"
      endpoint: "/api/health"
      method: "GET"
      expected_status: 200
      timeout: 5s
    
    - name: "Database Connection"
      endpoint: "/api/db-check"
      method: "GET"
      expected_status: 200
      expected_response:
        connected: true
    
    - name: "Authentication"
      endpoint: "/api/auth/login"
      method: "POST"
      payload:
        username: "test_user"
        password: "test_pass"
      expected_status: 200
      expected_response:
        token: ".*"
    
    - name: "Critical Business Flow"
      endpoint: "/api/orders"
      method: "POST"
      headers:
        Authorization: "Bearer ${auth_token}"
      payload:
        item_id: "test_item"
        quantity: 1
      expected_status: 201
```

### Chaos Engineering
```yaml
chaos_experiments:
  - name: "Network Latency"
    target: "production-canary"
    fault:
      type: "network-delay"
      parameters:
        delay: "100ms"
        jitter: "50ms"
        percentage: 25
    duration: "5m"
    
  - name: "Pod Failure"
    target: "production-canary"
    fault:
      type: "pod-kill"
      parameters:
        namespace: "production"
        label_selector: "app=frontend"
        percentage: 10
    duration: "10m"
```

## Performance Optimization

### Traffic Shaping
```nginx
# Nginx configuration for gradual traffic shift
upstream backend {
    server backend-v1.example.com weight=95;
    server backend-v2.example.com weight=5;
    
    # Health checks
    check interval=3000 rise=2 fall=5 timeout=1000;
}

server {
    location / {
        proxy_pass http://backend;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_connect_timeout 1s;
        proxy_read_timeout 10s;
    }
}
```

### Resource Optimization
```yaml
resource_scaling:
  predictive_scaling:
    enabled: true
    ml_model: "prophet"
    forecast_period: "24h"
    
  reactive_scaling:
    cpu_threshold: 70
    memory_threshold: 80
    scale_up_cooldown: 300
    scale_down_cooldown: 600
    
  scheduled_scaling:
    schedules:
      - name: "business_hours"
        cron: "0 9 * * MON-FRI"
        min_replicas: 10
        max_replicas: 50
      - name: "off_hours"
        cron: "0 18 * * MON-FRI"
        min_replicas: 3
        max_replicas: 10
```

## Success Metrics

### Deployment KPIs
- **Deployment Frequency**: > 10 per day
- **Lead Time**: < 30 minutes from commit to production
- **MTTR**: < 15 minutes
- **Change Failure Rate**: < 5%
- **Rollback Rate**: < 2%
- **Deployment Success Rate**: > 98%

### Business Impact
- **User Experience**: Zero perceived downtime
- **Revenue Impact**: < 0.1% during deployments
- **Customer Satisfaction**: No deployment-related complaints
- **Team Confidence**: High deployment frequency without fear