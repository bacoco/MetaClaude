# GitLab CI/CD Pipeline Templates

## Overview
Production-ready GitLab CI/CD pipeline templates implementing best practices for containerized applications with security scanning, quality gates, and multi-environment deployments.

## Pipeline Structure
```
.gitlab/
├── ci/
│   ├── .gitlab-ci.yml
│   ├── templates/
│   │   ├── security.gitlab-ci.yml
│   │   ├── quality.gitlab-ci.yml
│   │   ├── build.gitlab-ci.yml
│   │   └── deploy.gitlab-ci.yml
│   └── scripts/
│       ├── deploy.sh
│       ├── rollback.sh
│       └── health-check.sh
└── agents/
    └── config/
        └── config.yaml
```

## Main CI/CD Pipeline

### Root Pipeline Configuration
```yaml
# .gitlab-ci.yml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/License-Scanning.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - project: 'platform/gitlab-ci-templates'
    ref: main
    file: 
      - '/templates/docker.gitlab-ci.yml'
      - '/templates/kubernetes.gitlab-ci.yml'

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_VERIFY: 1
  DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"
  
  # Application variables
  APP_NAME: myapp
  CONTAINER_REGISTRY: ${CI_REGISTRY}
  CONTAINER_IMAGE: ${CI_REGISTRY_IMAGE}
  
  # Build variables
  DOCKER_BUILDKIT: 1
  BUILDKIT_PROGRESS: plain
  
  # Kubernetes variables
  KUBE_NAMESPACE_DEV: ${APP_NAME}-dev
  KUBE_NAMESPACE_STAGING: ${APP_NAME}-staging
  KUBE_NAMESPACE_PROD: ${APP_NAME}-prod
  
  # Security scanning
  SECURE_ANALYZERS_PREFIX: "$CI_TEMPLATE_REGISTRY_HOST/security-products"
  SAST_EXCLUDED_PATHS: "node_modules/,vendor/,test/"
  SECRET_DETECTION_EXCLUDED_PATHS: "node_modules/,vendor/"

stages:
  - validate
  - build
  - test
  - security
  - quality
  - package
  - deploy-dev
  - deploy-staging
  - performance
  - deploy-production
  - post-deploy

workflow:
  rules:
    - if: $CI_MERGE_REQUEST_IID
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /^(develop|feature|hotfix|release)\/.+$/

# Cache configuration
.cache_config: &cache_config
  cache:
    key:
      files:
        - package-lock.json
        - yarn.lock
        - Gemfile.lock
        - go.sum
    paths:
      - node_modules/
      - .npm/
      - vendor/
      - .cache/

# Node.js base job
.node_base:
  image: node:18-alpine
  <<: *cache_config
  before_script:
    - npm ci --prefer-offline --cache .npm

# Docker base job
.docker_base:
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker info
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

#############
# Validate Stage
#############

lint:code:
  stage: validate
  extends: .node_base
  script:
    - npm run lint
    - npm run format:check
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

lint:dockerfile:
  stage: validate
  image: hadolint/hadolint:latest-alpine
  script:
    - hadolint Dockerfile
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes:
        - Dockerfile

lint:kubernetes:
  stage: validate
  image: garethr/kubeval:latest
  script:
    - find k8s -name "*.yaml" -o -name "*.yml" | xargs kubeval --kubernetes-version 1.25.0
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - k8s/**/*
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes:
        - k8s/**/*

validate:commits:
  stage: validate
  image: node:18-alpine
  script:
    - npx commitlint --from="$CI_MERGE_REQUEST_DIFF_BASE_SHA"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

#############
# Build Stage
#############

build:application:
  stage: build
  extends: .node_base
  script:
    - npm run build
    - npm run test:unit -- --coverage
  artifacts:
    paths:
      - dist/
      - coverage/
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
      junit: test-results/junit.xml
    expire_in: 1 week
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'

build:docker:
  stage: build
  extends: .docker_base
  needs: ["build:application"]
  script:
    - |
      # Set up build variables
      if [[ "$CI_COMMIT_TAG" ]]; then
        VERSION="$CI_COMMIT_TAG"
      elif [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then
        VERSION="latest"
      else
        VERSION="$CI_COMMIT_SHORT_SHA"
      fi
      
      # Build multi-platform image
      docker buildx create --use --name multibuilder || true
      docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
        --build-arg VCS_REF=$CI_COMMIT_SHA \
        --build-arg VERSION=$VERSION \
        --cache-from type=registry,ref=$CONTAINER_IMAGE:buildcache \
        --cache-to type=registry,ref=$CONTAINER_IMAGE:buildcache,mode=max \
        --tag $CONTAINER_IMAGE:$VERSION \
        --tag $CONTAINER_IMAGE:$CI_COMMIT_SHA \
        --push .
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG

#############
# Test Stage
#############

test:unit:
  stage: test
  extends: .node_base
  needs: []
  script:
    - npm run test:unit -- --coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
      junit: test-results/junit.xml

test:integration:
  stage: test
  extends: .node_base
  needs: ["build:docker"]
  services:
    - postgres:15-alpine
    - redis:7-alpine
  variables:
    POSTGRES_DB: test
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: "postgresql://test:test@postgres:5432/test"
    REDIS_URL: "redis://redis:6379"
  script:
    - npm run test:integration
  artifacts:
    reports:
      junit: test-results/integration-junit.xml

test:e2e:
  stage: test
  image: mcr.microsoft.com/playwright:v1.40.0-focal
  needs: ["build:docker"]
  services:
    - name: $CONTAINER_IMAGE:$CI_COMMIT_SHA
      alias: app
  variables:
    APP_URL: "http://app:3000"
  script:
    - npm ci
    - npx playwright install
    - npm run test:e2e
  artifacts:
    paths:
      - playwright-report/
      - test-results/
    when: always
    expire_in: 1 week

#############
# Security Stage
#############

security:trivy:
  stage: security
  needs: ["build:docker"]
  image: aquasec/trivy:latest
  script:
    - |
      trivy image \
        --severity HIGH,CRITICAL \
        --no-progress \
        --format template \
        --template "@contrib/gitlab.tpl" \
        --output gl-container-scanning-report.json \
        $CONTAINER_IMAGE:$CI_COMMIT_SHA
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG

security:grype:
  stage: security
  needs: ["build:docker"]
  image: anchore/grype:latest
  script:
    - grype $CONTAINER_IMAGE:$CI_COMMIT_SHA -o json > grype-report.json
    - grype $CONTAINER_IMAGE:$CI_COMMIT_SHA -f high
  artifacts:
    paths:
      - grype-report.json
    expire_in: 1 week

security:kubesec:
  stage: security
  image: kubesec/kubesec:latest
  script:
    - find k8s -name "*.yaml" -exec kubesec scan {} \; > kubesec-report.json
  artifacts:
    paths:
      - kubesec-report.json
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - k8s/**/*

#############
# Quality Stage
#############

quality:sonarqube:
  stage: quality
  image: sonarsource/sonar-scanner-cli:latest
  needs: ["test:unit", "test:integration"]
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
  script:
    - |
      sonar-scanner \
        -Dsonar.projectKey=${CI_PROJECT_PATH_SLUG} \
        -Dsonar.sources=src \
        -Dsonar.tests=test \
        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
        -Dsonar.testExecutionReportPaths=test-results/sonar-report.xml \
        -Dsonar.gitlab.project_id=$CI_PROJECT_ID \
        -Dsonar.gitlab.commit_sha=$CI_COMMIT_SHA \
        -Dsonar.gitlab.ref_name=$CI_COMMIT_REF_NAME
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - .sonar/cache
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

quality:bundlesize:
  stage: quality
  extends: .node_base
  needs: ["build:application"]
  script:
    - npm run bundlesize
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

#############
# Deploy Development
#############

deploy:dev:
  stage: deploy-dev
  image: bitnami/kubectl:latest
  needs: ["build:docker", "test:integration"]
  environment:
    name: development
    url: https://dev.${APP_NAME}.company.com
    kubernetes:
      namespace: ${KUBE_NAMESPACE_DEV}
  script:
    - |
      kubectl set image deployment/${APP_NAME} \
        ${APP_NAME}=${CONTAINER_IMAGE}:${CI_COMMIT_SHA} \
        -n ${KUBE_NAMESPACE_DEV}
      
      kubectl rollout status deployment/${APP_NAME} \
        -n ${KUBE_NAMESPACE_DEV} \
        --timeout=300s
      
      kubectl annotate deployment/${APP_NAME} \
        kubernetes.io/change-cause="GitLab CI $CI_PIPELINE_ID - $CI_COMMIT_SHORT_SHA" \
        -n ${KUBE_NAMESPACE_DEV} \
        --overwrite
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      when: on_success
    - if: $CI_COMMIT_BRANCH =~ /^feature\/.+$/
      when: manual

deploy:dev:database:
  stage: deploy-dev
  image: migrate/migrate:latest
  needs: ["deploy:dev"]
  script:
    - |
      migrate -path db/migrations \
        -database "${DEV_DATABASE_URL}" \
        up
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
      changes:
        - db/migrations/*

#############
# Deploy Staging
#############

deploy:staging:
  stage: deploy-staging
  image: bitnami/kubectl:latest
  needs: ["security:trivy", "quality:sonarqube"]
  environment:
    name: staging
    url: https://staging.${APP_NAME}.company.com
    kubernetes:
      namespace: ${KUBE_NAMESPACE_STAGING}
  script:
    - |
      # Blue-Green Deployment
      ./scripts/blue-green-deploy.sh \
        ${APP_NAME} \
        ${CONTAINER_IMAGE}:${CI_COMMIT_SHA} \
        ${KUBE_NAMESPACE_STAGING}
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: on_success

smoke-test:staging:
  stage: deploy-staging
  extends: .node_base
  needs: ["deploy:staging"]
  script:
    - npm run test:smoke -- --url https://staging.${APP_NAME}.company.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

#############
# Performance Testing
#############

performance:load-test:
  stage: performance
  image: grafana/k6:latest
  needs: ["smoke-test:staging"]
  script:
    - |
      k6 run \
        --out influxdb=http://influxdb:8086/k6 \
        --vus 50 \
        --duration 10m \
        performance/load-test.js
  artifacts:
    paths:
      - performance-report.html
    reports:
      performance: performance-report.json
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

performance:lighthouse:
  stage: performance
  image: cypress/browsers:latest
  needs: ["smoke-test:staging"]
  script:
    - npm install -g @lhci/cli
    - |
      lhci autorun \
        --collect.url="https://staging.${APP_NAME}.company.com" \
        --upload.target=temporary-public-storage
  artifacts:
    paths:
      - .lighthouseci/
    expire_in: 1 week
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

#############
# Deploy Production
#############

deploy:production:canary:
  stage: deploy-production
  image: fluxcd/flux-cli:latest
  needs: ["performance:load-test", "performance:lighthouse"]
  environment:
    name: production-canary
    url: https://canary.${APP_NAME}.company.com
    kubernetes:
      namespace: ${KUBE_NAMESPACE_PROD}
  before_script:
    - flux check --pre
  script:
    - |
      # Create Flagger canary deployment
      cat <<EOF | kubectl apply -f -
      apiVersion: flagger.app/v1beta1
      kind: Canary
      metadata:
        name: ${APP_NAME}
        namespace: ${KUBE_NAMESPACE_PROD}
      spec:
        targetRef:
          apiVersion: apps/v1
          kind: Deployment
          name: ${APP_NAME}
        progressDeadlineSeconds: 60
        service:
          port: 80
          targetPort: 8080
          gateways:
          - public-gateway.istio-system.svc.cluster.local
          hosts:
          - ${APP_NAME}.company.com
        analysis:
          interval: 1m
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
            url: http://flagger-loadtester.flagger-system/
            metadata:
              cmd: "hey -z 2m -q 10 -c 2 https://${APP_NAME}.company.com/"
      EOF
      
      # Update image
      kubectl set image deployment/${APP_NAME} \
        ${APP_NAME}=${CONTAINER_IMAGE}:${CI_COMMIT_SHA} \
        -n ${KUBE_NAMESPACE_PROD}
  rules:
    - if: $CI_COMMIT_TAG
      when: manual
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual

deploy:production:full:
  stage: deploy-production
  image: bitnami/kubectl:latest
  needs: ["deploy:production:canary"]
  environment:
    name: production
    url: https://${APP_NAME}.company.com
    kubernetes:
      namespace: ${KUBE_NAMESPACE_PROD}
  script:
    - |
      # Wait for canary to complete
      kubectl wait canary/${APP_NAME} \
        -n ${KUBE_NAMESPACE_PROD} \
        --for=condition=Promoted \
        --timeout=3600s
      
      # Tag image as stable
      docker pull ${CONTAINER_IMAGE}:${CI_COMMIT_SHA}
      docker tag ${CONTAINER_IMAGE}:${CI_COMMIT_SHA} ${CONTAINER_IMAGE}:stable
      docker push ${CONTAINER_IMAGE}:stable
  rules:
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual

#############
# Post Deploy
#############

notify:success:
  stage: post-deploy
  image: curlimages/curl:latest
  script:
    - |
      curl -X POST $SLACK_WEBHOOK \
        -H 'Content-type: application/json' \
        -d "{
          \"text\": \"✅ Deployment Successful\",
          \"attachments\": [{
            \"color\": \"good\",
            \"fields\": [
              {\"title\": \"Project\", \"value\": \"$CI_PROJECT_NAME\", \"short\": true},
              {\"title\": \"Environment\", \"value\": \"$CI_ENVIRONMENT_NAME\", \"short\": true},
              {\"title\": \"Version\", \"value\": \"$CI_COMMIT_TAG\", \"short\": true},
              {\"title\": \"Deployed by\", \"value\": \"$GITLAB_USER_NAME\", \"short\": true}
            ]
          }]
        }"
  rules:
    - if: $CI_COMMIT_TAG
      when: on_success
  when: on_success

update:documentation:
  stage: post-deploy
  image: python:3.11-alpine
  needs: ["deploy:production:full"]
  script:
    - pip install mkdocs-material
    - mkdocs build
    - mkdocs gh-deploy --force
  rules:
    - if: $CI_COMMIT_TAG
```

### Blue-Green Deployment Script
```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -euo pipefail

APP_NAME=$1
IMAGE=$2
NAMESPACE=$3

echo "🔵🟢 Starting Blue-Green deployment for $APP_NAME"

# Determine current active deployment
CURRENT_ACTIVE=$(kubectl get service $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "blue")

if [ "$CURRENT_ACTIVE" == "blue" ]; then
    NEW_ACTIVE="green"
    OLD_ACTIVE="blue"
else
    NEW_ACTIVE="blue"
    OLD_ACTIVE="green"
fi

echo "Current active: $OLD_ACTIVE, deploying to: $NEW_ACTIVE"

# Update the inactive deployment
kubectl set image deployment/$APP_NAME-$NEW_ACTIVE \
    $APP_NAME=$IMAGE \
    -n $NAMESPACE

# Wait for rollout to complete
kubectl rollout status deployment/$APP_NAME-$NEW_ACTIVE \
    -n $NAMESPACE \
    --timeout=300s

# Run health checks
echo "Running health checks on $NEW_ACTIVE deployment..."
HEALTH_ENDPOINT=$(kubectl get service $APP_NAME-$NEW_ACTIVE -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

for i in {1..30}; do
    if curl -f "http://$HEALTH_ENDPOINT/health" > /dev/null 2>&1; then
        echo "✅ Health check passed"
        break
    fi
    echo "Waiting for health check... ($i/30)"
    sleep 10
done

# Switch traffic to new deployment
kubectl patch service $APP_NAME -n $NAMESPACE -p \
    '{"spec":{"selector":{"version":"'$NEW_ACTIVE'"}}}'

echo "🔄 Traffic switched to $NEW_ACTIVE"

# Verify traffic switch
sleep 30

# Keep old deployment for quick rollback
echo "✅ Blue-Green deployment completed. Old version ($OLD_ACTIVE) kept for rollback."
```

### GitLab Agent Configuration
```yaml
# .gitlab/agents/production/config.yaml
gitops:
  manifest_projects:
    - id: platform/k8s-manifests
      default_namespace: myapp-prod
      paths:
        - glob: 'production/**/*.yaml'
      reconcile_timeout: 3600s
      dry_run_strategy: client
      prune: true
      prune_timeout: 600s
      prune_propagation_policy: foreground
      inventory_policy: must_match

observability:
  logging:
    level: info
    grpc_level: warn
  metrics:
    enabled: true
    
ci_access:
  projects:
    - id: mycompany/myapp
      environments:
        - production
        - production-canary

user_access:
  projects:
    - id: mycompany/myapp
      groups:
        - id: platform-team
          
flux:
  version: 2.0.0
  resources:
    - toolkit.fluxcd.io/v1beta2/kustomization
    - helm.toolkit.fluxcd.io/v2beta1/helmrelease
```

### Environment-Specific Templates

#### Security Scanning Template
```yaml
# .gitlab/ci/templates/security.gitlab-ci.yml
.security_scan:
  stage: security
  allow_failure: false
  variables:
    SECURE_LOG_LEVEL: debug
  tags:
    - docker

security:dependency-check:
  extends: .security_scan
  image: owasp/dependency-check:latest
  script:
    - |
      dependency-check.sh \
        --project "$CI_PROJECT_NAME" \
        --scan . \
        --format ALL \
        --enableExperimental \
        --enableRetired \
        --out reports
  artifacts:
    paths:
      - reports/
    reports:
      dependency_scanning: reports/dependency-check-report.json

security:semgrep:
  extends: .security_scan
  image: returntocorp/semgrep:latest
  script:
    - semgrep --config=auto --json --output=semgrep-report.json
  artifacts:
    reports:
      sast: semgrep-report.json

security:gitleaks:
  extends: .security_scan
  image: zricethezav/gitleaks:latest
  script:
    - gitleaks detect --source . -v --report-path=gitleaks-report.json
  artifacts:
    reports:
      secret_detection: gitleaks-report.json
```

#### Deployment Template
```yaml
# .gitlab/ci/templates/deploy.gitlab-ci.yml
.deploy_base:
  image: alpine/helm:latest
  before_script:
    - apk add --no-cache curl kubectl
    - kubectl config use-context $KUBE_CONTEXT
  tags:
    - kubernetes

.deploy_helm:
  extends: .deploy_base
  script:
    - |
      helm upgrade --install $APP_NAME \
        ./helm-chart \
        --namespace $KUBE_NAMESPACE \
        --create-namespace \
        --values helm-chart/values.yaml \
        --values helm-chart/values-$CI_ENVIRONMENT_NAME.yaml \
        --set image.repository=$CONTAINER_IMAGE \
        --set image.tag=$CI_COMMIT_SHA \
        --set ingress.hosts[0].host=$CI_ENVIRONMENT_URL \
        --wait \
        --timeout 10m

.rollback:
  extends: .deploy_base
  when: manual
  script:
    - helm rollback $APP_NAME -n $KUBE_NAMESPACE
```

### Release Process
```yaml
# .gitlab/ci/release.gitlab-ci.yml
release:create:
  stage: release
  image: node:18-alpine
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - apk add --no-cache git curl
    - npm install -g semantic-release @semantic-release/gitlab
    - semantic-release
  artifacts:
    paths:
      - CHANGELOG.md

release:helm-chart:
  stage: release
  image: alpine/helm:latest
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - |
      helm package ./helm-chart --version ${CI_COMMIT_TAG#v}
      helm repo index . --url https://charts.company.com
      curl -X POST \
        -F "chart=@${APP_NAME}-${CI_COMMIT_TAG#v}.tgz" \
        https://charts.company.com/api/charts

release:docker-manifest:
  stage: release
  extends: .docker_base
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - |
      # Create multi-arch manifest
      docker manifest create ${CONTAINER_IMAGE}:${CI_COMMIT_TAG} \
        ${CONTAINER_IMAGE}:${CI_COMMIT_SHA}-amd64 \
        ${CONTAINER_IMAGE}:${CI_COMMIT_SHA}-arm64
      
      docker manifest push ${CONTAINER_IMAGE}:${CI_COMMIT_TAG}
      
      # Update latest tag
      docker manifest create ${CONTAINER_IMAGE}:latest \
        ${CONTAINER_IMAGE}:${CI_COMMIT_SHA}-amd64 \
        ${CONTAINER_IMAGE}:${CI_COMMIT_SHA}-arm64
      
      docker manifest push ${CONTAINER_IMAGE}:latest
```

## Best Practices

1. **Use CI/CD Components**: Leverage GitLab's reusable CI/CD components
2. **Implement Security Scanning**: Integrate security at every stage
3. **Use Review Apps**: Deploy merge requests to temporary environments
4. **Cache Aggressively**: Speed up pipelines with proper caching
5. **Parallel Execution**: Run independent jobs in parallel
6. **Environment Protection**: Use approval rules for production
7. **Monitor Pipeline Performance**: Track and optimize pipeline duration