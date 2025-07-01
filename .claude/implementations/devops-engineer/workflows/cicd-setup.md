# CI/CD Setup Workflow

## Overview
This workflow guides the complete setup of a CI/CD pipeline from scratch, including repository configuration, pipeline creation, testing integration, and deployment automation. It's designed to work with any technology stack and deployment target.

## Prerequisites
- Source code repository access (GitHub, GitLab, Bitbucket)
- Cloud provider credentials (AWS, Azure, GCP)
- Container registry access
- Target deployment environment

## Workflow Steps

### Phase 1: Repository Analysis & Setup

#### 1.1 Analyze Project Structure
```yaml
project_analysis:
  - detect_language:
      files: ["package.json", "pom.xml", "go.mod", "Gemfile", "requirements.txt"]
      output: primary_language
  - identify_frameworks:
      patterns: ["react", "spring", "django", "express", "rails"]
      output: frameworks_used
  - check_existing_ci:
      files: [".github/workflows", ".gitlab-ci.yml", "Jenkinsfile"]
      output: existing_pipeline
  - analyze_dependencies:
      command: "dependency-check"
      output: dependency_report
```

#### 1.2 Initialize Version Control
```bash
# Configure branch protection
configure_branch_protection() {
  gh api repos/:owner/:repo/branches/main/protection \
    --method PUT \
    --field required_status_checks='{"strict":true,"contexts":["continuous-integration"]}' \
    --field enforce_admins=false \
    --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
    --field restrictions=null
}

# Set up commit hooks
install_pre_commit_hooks() {
  cat > .pre-commit-config.yaml << EOF
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
  - repo: https://github.com/psf/black
    rev: 23.1.0
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
EOF
  pre-commit install
}
```

### Phase 2: Pipeline Configuration

#### 2.1 Create Pipeline Template
```yaml
# GitHub Actions Example
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Code Analysis
        uses: github/super-linter@v4
        env:
          DEFAULT_BRANCH: main
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  test:
    runs-on: ubuntu-latest
    needs: analyze
    strategy:
      matrix:
        test-suite: [unit, integration, e2e]
    steps:
      - uses: actions/checkout@v3
      - name: Set up environment
        run: |
          echo "Setting up test environment"
          docker-compose -f docker-compose.test.yml up -d
      - name: Run ${{ matrix.test-suite }} tests
        run: |
          npm run test:${{ matrix.test-suite }}
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/${{ matrix.test-suite }}.xml

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v3
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      - name: Log in to registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Production
        run: |
          echo "Deploying to production"
          # Add deployment logic here
```

#### 2.2 Security Integration
```yaml
security_scanning:
  dependency_check:
    - tool: "snyk"
      stage: "build"
      fail_on: "high"
    - tool: "owasp-dependency-check"
      stage: "test"
      report: "dependency-check-report.html"
  
  static_analysis:
    - tool: "sonarqube"
      config:
        server: "${SONAR_HOST_URL}"
        token: "${SONAR_TOKEN}"
        quality_gate: true
    - tool: "codeql"
      languages: ["javascript", "python"]
  
  container_scanning:
    - tool: "trivy"
      severity: "HIGH,CRITICAL"
      exit_code: 1
    - tool: "anchore"
      policy: "strict"
```

### Phase 3: Testing Framework

#### 3.1 Test Automation Setup
```javascript
// test-config.js
module.exports = {
  unit: {
    testMatch: ['**/__tests__/unit/**/*.test.js'],
    collectCoverageFrom: ['src/**/*.js'],
    coverageThreshold: {
      global: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80
      }
    }
  },
  integration: {
    testMatch: ['**/__tests__/integration/**/*.test.js'],
    setupFilesAfterEnv: ['<rootDir>/tests/setup/integration.js'],
    testTimeout: 30000
  },
  e2e: {
    preset: 'jest-playwright-preset',
    testMatch: ['**/__tests__/e2e/**/*.test.js'],
    testTimeout: 60000
  }
};
```

#### 3.2 Performance Testing
```yaml
performance_tests:
  load_test:
    tool: "k6"
    script: |
      import http from 'k6/http';
      import { check } from 'k6';
      
      export let options = {
        stages: [
          { duration: '30s', target: 20 },
          { duration: '1m30s', target: 100 },
          { duration: '20s', target: 0 },
        ],
        thresholds: {
          http_req_duration: ['p(99)<1500'],
          http_req_failed: ['rate<0.1'],
        },
      };
      
      export default function() {
        let response = http.get('https://api.example.com/health');
        check(response, {
          'status is 200': (r) => r.status === 200,
          'response time < 500ms': (r) => r.timings.duration < 500,
        });
      }
```

### Phase 4: Deployment Configuration

#### 4.1 Environment Setup
```yaml
environments:
  development:
    auto_deploy: true
    branch: develop
    url: https://dev.example.com
    variables:
      NODE_ENV: development
      LOG_LEVEL: debug
  
  staging:
    auto_deploy: true
    branch: staging
    url: https://staging.example.com
    approvals:
      required: 1
      reviewers: ["qa-team"]
    variables:
      NODE_ENV: staging
      LOG_LEVEL: info
  
  production:
    auto_deploy: false
    branch: main
    url: https://example.com
    approvals:
      required: 2
      reviewers: ["senior-engineers", "ops-team"]
    variables:
      NODE_ENV: production
      LOG_LEVEL: error
```

#### 4.2 Deployment Strategies
```yaml
deployment_strategy:
  type: "blue_green"
  health_check:
    endpoint: "/health"
    interval: 10s
    timeout: 5s
    success_threshold: 3
    failure_threshold: 2
  
  traffic_shift:
    method: "weighted"
    steps:
      - weight: 10
        duration: 5m
        validation:
          error_rate: "< 1%"
          response_time_p99: "< 1000ms"
      - weight: 50
        duration: 10m
        validation:
          error_rate: "< 1%"
          response_time_p99: "< 1000ms"
      - weight: 100
  
  rollback:
    automatic: true
    conditions:
      - metric: "error_rate"
        threshold: "> 5%"
        duration: "2m"
      - metric: "response_time_p99"
        threshold: "> 2000ms"
        duration: "5m"
```

### Phase 5: Monitoring Integration

#### 5.1 Pipeline Metrics
```yaml
pipeline_monitoring:
  metrics:
    - name: "build_duration"
      type: "histogram"
      labels: ["branch", "status"]
    - name: "test_pass_rate"
      type: "gauge"
      labels: ["test_suite", "branch"]
    - name: "deployment_frequency"
      type: "counter"
      labels: ["environment", "status"]
    - name: "lead_time"
      type: "histogram"
      labels: ["environment"]
  
  dashboards:
    - name: "CI/CD Overview"
      panels:
        - title: "Build Success Rate"
          query: "rate(builds_total{status='success'}[1d])"
        - title: "Average Build Time"
          query: "avg(build_duration_seconds) by (branch)"
        - title: "Deployment Frequency"
          query: "increase(deployments_total[1d]) by (environment)"
```

#### 5.2 Alerting Rules
```yaml
alerts:
  - name: "PipelineFailureRate"
    expr: |
      rate(pipeline_runs_total{status="failed"}[30m]) > 0.2
    for: "10m"
    labels:
      severity: "warning"
      team: "platform"
    annotations:
      summary: "High pipeline failure rate"
      description: "Pipeline failure rate is {{ $value | humanizePercentage }}"
  
  - name: "LongBuildTime"
    expr: |
      avg(build_duration_seconds) by (job) > 1800
    for: "15m"
    labels:
      severity: "warning"
      team: "platform"
    annotations:
      summary: "Build taking too long"
      description: "Average build time is {{ $value | humanizeDuration }}"
```

## Best Practices

### 1. Pipeline Optimization
- Use caching for dependencies and Docker layers
- Parallelize test execution
- Implement incremental builds
- Use matrix builds for multiple versions

### 2. Security Considerations
- Never commit secrets to version control
- Use secret management services
- Implement least privilege access
- Regular security scanning

### 3. Cost Optimization
- Use spot instances for CI runners
- Implement smart test selection
- Clean up old artifacts
- Monitor resource usage

## Troubleshooting Guide

### Common Issues
1. **Slow Builds**
   - Check cache hit rates
   - Analyze dependency download times
   - Review Docker layer caching
   - Consider build parallelization

2. **Flaky Tests**
   - Implement retry logic
   - Improve test isolation
   - Add wait conditions
   - Use test containers

3. **Deployment Failures**
   - Verify credentials and permissions
   - Check network connectivity
   - Review resource quotas
   - Validate configuration files

## Success Metrics
- **Build Success Rate**: > 95%
- **Average Build Time**: < 10 minutes
- **Test Coverage**: > 80%
- **Deployment Success Rate**: > 98%
- **Lead Time**: < 1 hour
- **MTTR**: < 30 minutes