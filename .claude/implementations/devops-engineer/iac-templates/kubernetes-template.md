# Kubernetes Infrastructure Template

## Overview
This template provides production-ready Kubernetes manifests and Helm charts for deploying microservices applications with best practices for security, scalability, and observability.

## Directory Structure
```
kubernetes/
├── namespaces/
│   ├── dev.yaml
│   ├── staging.yaml
│   └── production.yaml
├── base/
│   ├── deployments/
│   ├── services/
│   ├── configmaps/
│   ├── secrets/
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   ├── staging/
│   └── production/
├── helm-charts/
│   ├── microservice/
│   ├── database/
│   └── monitoring/
├── operators/
│   ├── cert-manager/
│   ├── ingress-nginx/
│   └── prometheus/
└── scripts/
    ├── deploy.sh
    └── rollback.sh
```

## Base Kubernetes Manifests

### Namespace Configuration
```yaml
# namespaces/production.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    istio-injection: enabled
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "100"
    requests.memory: 200Gi
    limits.cpu: "200"
    limits.memory: 400Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "2"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: production
spec:
  limits:
  - default:
      memory: 512Mi
      cpu: 500m
    defaultRequest:
      memory: 256Mi
      cpu: 100m
    type: Container
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
```

### Deployment Template
```yaml
# base/deployments/app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app: app
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: app
      version: v1
  template:
    metadata:
      labels:
        app: app
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: app
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: app
        image: myregistry/app:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        - containerPort: 8081
          name: metrics
          protocol: TCP
        env:
        - name: ENVIRONMENT
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /startup
            port: http
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 30
        volumeMounts:
        - name: config
          mountPath: /etc/config
          readOnly: true
        - name: secrets
          mountPath: /etc/secrets
          readOnly: true
        - name: cache
          mountPath: /cache
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
      volumes:
      - name: config
        configMap:
          name: app-config
      - name: secrets
        secret:
          secretName: app-secrets
          defaultMode: 0400
      - name: cache
        emptyDir:
          sizeLimit: 1Gi
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - app
              topologyKey: kubernetes.io/hostname
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: app
```

### Service Configuration
```yaml
# base/services/app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app
  labels:
    app: app
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  - port: 8081
    targetPort: metrics
    protocol: TCP
    name: metrics
  selector:
    app: app
---
apiVersion: v1
kind: Service
metadata:
  name: app-headless
  labels:
    app: app
spec:
  type: ClusterIP
  clusterIP: None
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: app
```

### Horizontal Pod Autoscaler
```yaml
# base/deployments/app-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1k"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Min
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 4
        periodSeconds: 30
      selectPolicy: Max
```

### PodDisruptionBudget
```yaml
# base/deployments/app-pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: app
  unhealthyPodEvictionPolicy: AlwaysAllow
```

### Ingress Configuration
```yaml
# base/ingress/app-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app
            port:
              number: 80
```

## Kustomization

### Base Kustomization
```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployments/app-deployment.yaml
  - deployments/app-hpa.yaml
  - deployments/app-pdb.yaml
  - services/app-service.yaml
  - configmaps/app-configmap.yaml
  - serviceaccounts/app-sa.yaml
  - ingress/app-ingress.yaml

configMapGenerator:
  - name: app-config
    files:
      - configs/app.properties
      - configs/logging.yaml

secretGenerator:
  - name: app-secrets
    envs:
      - secrets/app.env

images:
  - name: myregistry/app
    newTag: latest

commonLabels:
  app.kubernetes.io/name: app
  app.kubernetes.io/instance: app
  app.kubernetes.io/component: backend
  app.kubernetes.io/part-of: myapp

commonAnnotations:
  app.kubernetes.io/managed-by: kustomize
```

### Production Overlay
```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

bases:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml
  - hpa-patch.yaml

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - ENVIRONMENT=production
      - LOG_LEVEL=info

secretGenerator:
  - name: app-secrets
    behavior: merge
    envs:
      - secrets/production.env

images:
  - name: myregistry/app
    newTag: v1.2.3

replicas:
  - name: app
    count: 5

resources:
  - production-networkpolicy.yaml
  - production-servicemonitor.yaml
```

## Helm Charts

### Chart Structure
```yaml
# helm-charts/microservice/Chart.yaml
apiVersion: v2
name: microservice
description: A Helm chart for deploying microservices
type: application
version: 1.0.0
appVersion: "1.0"
keywords:
  - microservice
  - kubernetes
home: https://github.com/company/microservice
sources:
  - https://github.com/company/microservice
maintainers:
  - name: DevOps Team
    email: devops@company.com
dependencies:
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

### Values File
```yaml
# helm-charts/microservice/values.yaml
replicaCount: 3

image:
  repository: myregistry/app
  pullPolicy: IfNotPresent
  tag: ""

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL

service:
  type: ClusterIP
  port: 80
  targetPort: 8080
  annotations: {}

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - "{{ include \"microservice.name\" . }}"
        topologyKey: kubernetes.io/hostname

persistence:
  enabled: false
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 8Gi
  annotations: {}

postgresql:
  enabled: false
  auth:
    postgresPassword: ""
    database: app

redis:
  enabled: false
  auth:
    enabled: true
    password: ""

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics
  prometheusRule:
    enabled: true
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High error rate detected
          description: "Error rate is {{ $value | humanizePercentage }}"

config:
  LOG_LEVEL: info
  SERVER_PORT: 8080
  METRICS_PORT: 8081

secrets:
  DATABASE_URL: ""
  REDIS_URL: ""
  API_KEY: ""
```

### Deployment Template
```yaml
# helm-charts/microservice/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservice.fullname" . }}
  labels:
    {{- include "microservice.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "microservice.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "microservice.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "microservice.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.config.SERVER_PORT }}
              protocol: TCP
            - name: metrics
              containerPort: {{ .Values.config.METRICS_PORT }}
              protocol: TCP
          envFrom:
            - configMapRef:
                name: {{ include "microservice.fullname" . }}
            - secretRef:
                name: {{ include "microservice.fullname" . }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          startupProbe:
            httpGet:
              path: /startup
              port: http
            initialDelaySeconds: 0
            periodSeconds: 10
            failureThreshold: 30
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- if .Values.persistence.enabled }}
          volumeMounts:
            - name: data
              mountPath: /data
          {{- end }}
      {{- if .Values.persistence.enabled }}
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: {{ include "microservice.fullname" . }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

## Service Mesh Configuration

### Istio VirtualService
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: app
spec:
  hosts:
  - app.example.com
  gateways:
  - istio-system/main-gateway
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: app
        subset: v2
      weight: 100
  - route:
    - destination:
        host: app
        subset: v1
      weight: 90
    - destination:
        host: app
        subset: v2
      weight: 10
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
      retryOn: 5xx
```

### Istio DestinationRule
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: app
spec:
  host: app
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    loadBalancer:
      consistentHash:
        httpCookie:
          name: "session"
          ttl: 3600s
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 50
      splitExternalLocalOriginErrors: true
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

## GitOps with ArgoCD

### Application Definition
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservice
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/company/k8s-config
    targetRevision: HEAD
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - Validate=true
    - CreateNamespace=false
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
```

### AppProject Configuration
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
  namespace: argocd
spec:
  description: Production applications
  sourceRepos:
  - 'https://github.com/company/*'
  destinations:
  - namespace: 'production'
    server: https://kubernetes.default.svc
  - namespace: 'production-*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
  roles:
  - name: admin
    policies:
    - p, proj:production:admin, applications, *, production/*, allow
    groups:
    - company:platform-team
  - name: readonly
    policies:
    - p, proj:production:readonly, applications, get, production/*, allow
    groups:
    - company:developers
```

## Monitoring & Observability

### ServiceMonitor for Prometheus
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
    scheme: http
    tlsConfig:
      insecureSkipVerify: true
```

### PrometheusRule
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: app
  labels:
    prometheus: kube-prometheus
spec:
  groups:
  - name: app.rules
    interval: 30s
    rules:
    - alert: AppDown
      expr: up{job="app"} == 0
      for: 5m
      labels:
        severity: critical
        team: platform
      annotations:
        summary: "Application {{ $labels.pod }} is down"
        description: "{{ $labels.pod }} has been down for more than 5 minutes."
        
    - alert: HighErrorRate
      expr: |
        rate(http_requests_total{job="app",status=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "High error rate on {{ $labels.pod }}"
        description: "Error rate is {{ $value | humanizePercentage }}"
        
    - alert: HighLatency
      expr: |
        histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{job="app"}[5m])) > 1
      for: 10m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "High latency on {{ $labels.pod }}"
        description: "99th percentile latency is {{ $value }}s"
```

## Security Policies

### PodSecurityPolicy (deprecated, use Pod Security Standards)
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
  readOnlyRootFilesystem: true
```

### NetworkPolicy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
    - podSelector:
        matchLabels:
          app: nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: production
    ports:
    - protocol: TCP
      port: 5432
    - protocol: TCP
      port: 6379
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

## Deployment Scripts

### deploy.sh
```bash
#!/bin/bash
set -e

NAMESPACE=${1:-default}
RELEASE=${2:-myapp}
ENVIRONMENT=${3:-dev}

echo "Deploying $RELEASE to $NAMESPACE ($ENVIRONMENT)"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply namespace-specific resources
kubectl apply -f namespaces/$ENVIRONMENT.yaml

# Deploy with Kustomize
kubectl apply -k overlays/$ENVIRONMENT

# Or deploy with Helm
helm upgrade --install $RELEASE ./helm-charts/microservice \
  --namespace $NAMESPACE \
  --values helm-charts/microservice/values.yaml \
  --values helm-charts/microservice/values-$ENVIRONMENT.yaml \
  --set image.tag=$IMAGE_TAG \
  --wait \
  --timeout 10m

# Wait for deployment to be ready
kubectl rollout status deployment/$RELEASE -n $NAMESPACE

# Run smoke tests
./scripts/smoke-test.sh $NAMESPACE $RELEASE
```

## Best Practices

1. **Resource Management**
   - Always set resource requests and limits
   - Use HPA for automatic scaling
   - Implement PodDisruptionBudgets

2. **Security**
   - Run containers as non-root
   - Use read-only root filesystems
   - Implement NetworkPolicies
   - Use RBAC properly

3. **High Availability**
   - Use anti-affinity rules
   - Spread across zones
   - Set appropriate replica counts
   - Configure proper health checks

4. **Observability**
   - Export Prometheus metrics
   - Use structured logging
   - Implement distributed tracing
   - Set up proper alerting

5. **GitOps**
   - Separate config from code
   - Use declarative deployments
   - Implement proper RBAC
   - Version everything