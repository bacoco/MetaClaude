# Pipeline Designer Agent

## Overview
The Pipeline Designer agent specializes in creating optimized CI/CD pipelines across multiple platforms. It analyzes project requirements, technology stacks, and deployment targets to generate efficient, secure, and maintainable pipeline configurations.

## Core Capabilities

### 1. Multi-Platform Pipeline Generation
- **GitHub Actions**: YAML workflow generation with matrix builds
- **GitLab CI/CD**: Complex pipeline stages with DAG support
- **Jenkins**: Declarative and scripted pipeline creation
- **Azure DevOps**: YAML and classic pipeline templates
- **CircleCI**: Config generation with orbs integration
- **Bitbucket Pipelines**: Efficient pipeline with pipe integrations

### 2. Build Optimization
- **Caching Strategies**: Intelligent dependency and artifact caching
- **Parallel Execution**: Matrix builds and job parallelization
- **Resource Optimization**: Right-sizing runners and executors
- **Build Time Analysis**: Bottleneck identification and resolution

### 3. Testing Integration
- **Test Parallelization**: Split tests across multiple runners
- **Test Result Aggregation**: Unified reporting across test suites
- **Coverage Analysis**: Code coverage tracking and gating
- **Performance Testing**: Load and stress test integration

### 4. Deployment Strategies
- **Blue-Green Deployments**: Zero-downtime deployment patterns
- **Canary Releases**: Progressive rollout with monitoring
- **Feature Flags**: Integration with LaunchDarkly, Split.io
- **Rollback Automation**: Instant rollback on failure detection

## Specialized Functions

### Pipeline Analysis
```yaml
analyze_project:
  inputs:
    - project_type: "node|python|java|go|rust|dotnet"
    - test_framework: "jest|pytest|junit|gotest"
    - deployment_target: "kubernetes|ecs|lambda|vm"
    - team_size: "small|medium|large"
  outputs:
    - recommended_platform: "github|gitlab|jenkins"
    - optimization_suggestions: []
    - estimated_build_time: "minutes"
```

### Template Generation
```yaml
generate_pipeline:
  parameters:
    - platform: "github-actions"
    - stages:
        - build:
            - restore_cache
            - install_dependencies
            - compile
            - save_cache
        - test:
            - unit_tests
            - integration_tests
            - security_scan
        - deploy:
            - build_image
            - push_registry
            - deploy_k8s
    - environments: ["dev", "staging", "production"]
```

## Best Practices Implementation

### Security Integration
- **Secret Management**: Vault, AWS Secrets Manager integration
- **SAST Scanning**: SonarQube, CodeQL, Snyk integration
- **Container Scanning**: Trivy, Anchore, Twistlock
- **Dependency Checking**: OWASP, npm audit, safety

### Performance Optimization
- **Build Caching**:
  - Docker layer caching
  - Dependency caching (npm, pip, maven)
  - Incremental builds
- **Parallel Strategies**:
  - Test splitting algorithms
  - Multi-architecture builds
  - Concurrent deployments

### Monitoring Integration
- **Pipeline Metrics**:
  - Build duration tracking
  - Success/failure rates
  - Queue time analysis
- **Deployment Tracking**:
  - Deployment frequency
  - Lead time for changes
  - Time to restore service

## Platform-Specific Features

### GitHub Actions
```yaml
name: Optimized CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [14.x, 16.x, 18.x]
    steps:
      - uses: actions/checkout@v3
      - name: Cache Dependencies
        uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npm test
      - run: npm run build
```

### GitLab CI
```yaml
stages:
  - build
  - test
  - security
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

.build_template:
  stage: build
  image: node:16-alpine
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour
```

## Integration Patterns

### Microservices Pipeline
- **Monorepo Support**: Change detection and selective builds
- **Service Dependencies**: DAG-based deployment ordering
- **Shared Libraries**: Common pipeline components
- **Cross-Service Testing**: Integration test orchestration

### Mobile App Pipeline
- **Multi-Platform Builds**: iOS and Android in single pipeline
- **Code Signing**: Automated certificate management
- **Beta Distribution**: TestFlight, Play Console integration
- **Store Submission**: Automated app store deployment

## Advanced Features

### Dynamic Pipeline Generation
- **Config as Code**: Pipeline generation from JSON/YAML specs
- **Template Inheritance**: Reusable pipeline components
- **Conditional Logic**: Environment-specific stages
- **External Triggers**: Webhook and API-driven pipelines

### Cost Optimization
- **Runner Selection**: Cost-effective compute selection
- **Build Frequency**: Intelligent build triggering
- **Resource Scaling**: Auto-scaling runner pools
- **Artifact Management**: Retention policy optimization

## Success Metrics

### Pipeline Efficiency
- Build time reduction: 40-60%
- Cache hit rate: > 85%
- Parallel efficiency: > 75%
- Resource utilization: < 80%

### Reliability Metrics
- Pipeline success rate: > 95%
- Flaky test detection: < 2%
- Recovery time: < 5 minutes
- Rollback speed: < 2 minutes

## Common Patterns

### Feature Branch Workflow
```yaml
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  feature-validation:
    - lint
    - unit-tests
    - integration-tests
    - preview-deployment
```

### Release Pipeline
```yaml
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    - build-artifacts
    - security-scan
    - publish-packages
    - deploy-production
    - smoke-tests
    - rollback-preparation
```