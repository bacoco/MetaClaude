# GitHub Actions Pipeline Templates

## Overview
This collection provides production-ready GitHub Actions workflow templates for various scenarios including CI/CD, security scanning, multi-environment deployments, and automated releases.

## Basic CI/CD Pipeline

### Node.js Application
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  NODE_VERSION: '18.x'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Lint and Test
  quality-checks:
    name: Quality Checks
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for better analysis

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Cache dependencies
        uses: actions/cache@v3
        id: cache-deps
        with:
          path: |
            node_modules
            ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - name: Install dependencies
        if: steps.cache-deps.outputs.cache-hit != 'true'
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run type check
        run: npm run type-check

      - name: Run tests
        run: npm run test:ci
        env:
          CI: true

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: |
            coverage/
            test-results/

      - name: Code Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

  # Security Scanning
  security:
    name: Security Scanning
    runs-on: ubuntu-latest
    needs: quality-checks
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  # Build and Push Docker Image
  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [quality-checks, security]
    permissions:
      contents: read
      packages: write
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-

      - name: Build and push Docker image
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            NODE_VERSION=${{ env.NODE_VERSION }}
            BUILD_DATE=${{ github.event.repository.updated_at }}
            VCS_REF=${{ github.sha }}

      - name: Run Trivy on Docker image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
          format: 'sarif'
          output: 'docker-trivy-results.sarif'

      - name: Upload Docker scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'docker-trivy-results.sarif'

  # Deploy to Development
  deploy-dev:
    name: Deploy to Development
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment:
      name: development
      url: https://dev.example.com
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster dev-cluster \
            --service app-service \
            --force-new-deployment \
            --desired-count 2

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster dev-cluster \
            --services app-service

      - name: Run smoke tests
        run: |
          npm run test:smoke -- --url=https://dev.example.com

  # Deploy to Production
  deploy-prod:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://example.com
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_PROD_ROLE_ARN }}
          aws-region: us-east-1

      - name: Deploy with CodeDeploy
        run: |
          aws deploy create-deployment \
            --application-name MyApp \
            --deployment-group-name production \
            --revision location=S3,bucket=my-deploy-bucket,key=deploy-${{ github.sha }}.zip \
            --deployment-config-name CodeDeployDefault.AllAtOnceBlueGreen
```

## Multi-Language Support

### Python Application
```yaml
name: Python CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  PYTHON_VERSION: '3.11'

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
          
      - name: Cache pip packages
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-
            
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
          
      - name: Run tests with pytest
        run: |
          pytest tests/ \
            --cov=src \
            --cov-report=xml \
            --cov-report=html \
            --junitxml=junit/test-results-${{ matrix.python-version }}.xml
            
      - name: Upload test results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: pytest-results-${{ matrix.python-version }}
          path: junit/test-results-${{ matrix.python-version }}.xml
          
      - name: Lint with multiple tools
        run: |
          # Black for formatting
          black --check src/ tests/
          
          # isort for import sorting
          isort --check-only src/ tests/
          
          # flake8 for style guide enforcement
          flake8 src/ tests/
          
          # mypy for type checking
          mypy src/
          
          # bandit for security issues
          bandit -r src/
```

### Go Application
```yaml
name: Go CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  GO_VERSION: '1.21'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
          
      - name: Cache Go modules
        uses: actions/cache@v3
        with:
          path: |
            ~/go/pkg/mod
            ~/.cache/go-build
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-
            
      - name: Download dependencies
        run: go mod download
        
      - name: Run tests
        run: |
          go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
          go tool cover -html=coverage.out -o coverage.html
          
      - name: Run benchmarks
        run: go test -bench=. -benchmem ./...
        
      - name: Static analysis
        run: |
          # Install tools
          go install honnef.co/go/tools/cmd/staticcheck@latest
          go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
          
          # Run checks
          go vet ./...
          staticcheck ./...
          golangci-lint run
          
      - name: Build
        run: |
          CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o app-linux-amd64
          CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags="-w -s" -o app-darwin-amd64
          CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="-w -s" -o app-windows-amd64.exe
```

## Advanced Workflows

### Matrix Build Strategy
```yaml
name: Matrix Build

on:
  push:
    branches: [main]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [16, 18, 20]
        include:
          - os: ubuntu-latest
            node: 18
            experimental: true
        exclude:
          - os: windows-latest
            node: 16
    runs-on: ${{ matrix.os }}
    continue-on-error: ${{ matrix.experimental == true }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Use Node.js ${{ matrix.node }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          
      - name: Install and test
        run: |
          npm ci
          npm test
          
      - name: Platform-specific build
        run: |
          if [ "$RUNNER_OS" == "Linux" ]; then
            npm run build:linux
          elif [ "$RUNNER_OS" == "Windows" ]; then
            npm run build:windows
          elif [ "$RUNNER_OS" == "macOS" ]; then
            npm run build:macos
          fi
        shell: bash
```

### Deployment with Environments
```yaml
name: Deploy with Environments

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'staging'
        type: choice
        options:
          - development
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: ${{ github.event.inputs.environment || 'staging' }}
      url: ${{ steps.deploy.outputs.url }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure environment
        id: config
        run: |
          if [[ "${{ github.event.inputs.environment }}" == "production" ]]; then
            echo "cluster=prod-cluster" >> $GITHUB_OUTPUT
            echo "namespace=production" >> $GITHUB_OUTPUT
            echo "replicas=5" >> $GITHUB_OUTPUT
          elif [[ "${{ github.event.inputs.environment }}" == "staging" ]]; then
            echo "cluster=staging-cluster" >> $GITHUB_OUTPUT
            echo "namespace=staging" >> $GITHUB_OUTPUT
            echo "replicas=3" >> $GITHUB_OUTPUT
          else
            echo "cluster=dev-cluster" >> $GITHUB_OUTPUT
            echo "namespace=development" >> $GITHUB_OUTPUT
            echo "replicas=1" >> $GITHUB_OUTPUT
          fi
          
      - name: Deploy to Kubernetes
        id: deploy
        env:
          KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
        run: |
          echo "$KUBE_CONFIG" | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig
          
          kubectl set image deployment/app \
            app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
            -n ${{ steps.config.outputs.namespace }}
            
          kubectl scale deployment/app \
            --replicas=${{ steps.config.outputs.replicas }} \
            -n ${{ steps.config.outputs.namespace }}
            
          kubectl rollout status deployment/app \
            -n ${{ steps.config.outputs.namespace }}
            
          URL=$(kubectl get ingress app -n ${{ steps.config.outputs.namespace }} -o jsonpath='{.spec.rules[0].host}')
          echo "url=https://$URL" >> $GITHUB_OUTPUT
```

### Monorepo Support
```yaml
name: Monorepo CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      api: ${{ steps.filter.outputs.api }}
      web: ${{ steps.filter.outputs.web }}
      mobile: ${{ steps.filter.outputs.mobile }}
      shared: ${{ steps.filter.outputs.shared }}
    steps:
      - uses: actions/checkout@v4
      
      - uses: dorny/paths-filter@v2
        id: filter
        with:
          filters: |
            api:
              - 'packages/api/**'
              - 'packages/shared/**'
            web:
              - 'packages/web/**'
              - 'packages/shared/**'
            mobile:
              - 'packages/mobile/**'
              - 'packages/shared/**'
            shared:
              - 'packages/shared/**'

  test-api:
    needs: changes
    if: needs.changes.outputs.api == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'
          cache-dependency-path: packages/api/package-lock.json
          
      - name: Install and test API
        run: |
          cd packages/api
          npm ci
          npm test
          npm run build
          
  test-web:
    needs: changes
    if: needs.changes.outputs.web == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'
          cache-dependency-path: packages/web/package-lock.json
          
      - name: Install and test Web
        run: |
          cd packages/web
          npm ci
          npm test
          npm run build
          
      - name: Run E2E tests
        run: |
          cd packages/web
          npm run test:e2e
```

### Release Automation
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: write
  packages: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          registry-url: 'https://registry.npmjs.org'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Build
        run: npm run build
        
      - name: Generate changelog
        id: changelog
        run: |
          npm install -g conventional-changelog-cli
          conventional-changelog -p angular -i CHANGELOG.md -s -r 0
          
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body_path: CHANGELOG.md
          draft: false
          prerelease: false
          
      - name: Publish to NPM
        run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
          
      - name: Build and push Docker images
        run: |
          docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }} .
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}
          docker tag ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }} ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

### Dependency Updates
```yaml
name: Dependency Updates

on:
  schedule:
    - cron: '0 0 * * MON'  # Weekly on Monday
  workflow_dispatch:

jobs:
  update-dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          
      - name: Update dependencies
        run: |
          npx npm-check-updates -u
          npm install
          npm audit fix
          
      - name: Run tests
        run: npm test
        
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: 'chore: update dependencies'
          title: 'Weekly dependency updates'
          body: |
            ## Dependency Updates
            
            This PR contains the weekly automated dependency updates.
            
            ### Changes
            - Updated npm dependencies to latest versions
            - Fixed any security vulnerabilities found by npm audit
            
            ### Checklist
            - [ ] All tests pass
            - [ ] No breaking changes identified
            - [ ] Security vulnerabilities addressed
          branch: deps/weekly-update
          delete-branch: true
```

### Performance Testing
```yaml
name: Performance Tests

on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          
      - name: Build application
        run: |
          npm ci
          npm run build
          
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            http://localhost:3000
            http://localhost:3000/products
            http://localhost:3000/checkout
          budgetPath: ./lighthouse-budget.json
          uploadArtifacts: true
          temporaryPublicStorage: true
          
      - name: Load testing with k6
        run: |
          docker run --rm \
            -v $PWD:/scripts \
            grafana/k6 run /scripts/load-test.js \
            --out json=results.json
            
      - name: Analyze results
        run: |
          node scripts/analyze-performance.js results.json
          
      - name: Comment PR
        uses: actions/github-script@v6
        if: github.event_name == 'pull_request'
        with:
          script: |
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('performance-summary.json', 'utf8'));
            
            const comment = `## Performance Test Results
            
            | Metric | Value | Target | Status |
            |--------|-------|--------|--------|
            | Page Load Time | ${results.loadTime}ms | < 3000ms | ${results.loadTime < 3000 ? '✅' : '❌'} |
            | Time to Interactive | ${results.tti}ms | < 5000ms | ${results.tti < 5000 ? '✅' : '❌'} |
            | Response Time (p95) | ${results.p95}ms | < 500ms | ${results.p95 < 500 ? '✅' : '❌'} |
            | Requests/sec | ${results.rps} | > 100 | ${results.rps > 100 ? '✅' : '❌'} |
            `;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

## Reusable Workflows

### Shared Testing Workflow
```yaml
# .github/workflows/shared-test.yml
name: Shared Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: '18'
      test-command:
        required: false
        type: string
        default: 'npm test'
    secrets:
      NPM_TOKEN:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          registry-url: 'https://registry.npmjs.org'
          
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          
      - name: Install dependencies
        run: npm ci
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
          
      - name: Run tests
        run: ${{ inputs.test-command }}
```

### Using Reusable Workflow
```yaml
name: CI

on:
  push:
    branches: [main, develop]

jobs:
  test-frontend:
    uses: ./.github/workflows/shared-test.yml
    with:
      node-version: '18'
      test-command: 'npm run test:frontend'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      
  test-backend:
    uses: ./.github/workflows/shared-test.yml
    with:
      node-version: '18'
      test-command: 'npm run test:backend'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Best Practices

1. **Caching**
   - Cache dependencies for faster builds
   - Use cache keys with hashes of lock files
   - Set up restore keys for partial matches

2. **Security**
   - Use OIDC for cloud authentication
   - Store secrets in GitHub Secrets
   - Run security scans on every PR
   - Keep actions up to date

3. **Performance**
   - Run jobs in parallel when possible
   - Use matrix builds wisely
   - Cancel outdated workflows
   - Optimize Docker builds

4. **Maintainability**
   - Use reusable workflows
   - Keep workflows DRY
   - Version your actions
   - Document complex logic