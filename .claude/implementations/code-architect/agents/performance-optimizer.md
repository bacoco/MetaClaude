# Performance Optimizer Agent

## Overview
The Performance Optimizer analyzes architectural decisions and code implementations to identify performance bottlenecks and suggest optimizations. This agent ensures that systems are designed and implemented to meet performance requirements while maintaining code quality and maintainability.

## Core Responsibilities

### 1. Performance Analysis
- Identify architectural bottlenecks
- Analyze code-level inefficiencies
- Evaluate database query performance
- Assess network communication overhead

### 2. Optimization Strategy
- Recommend caching strategies
- Suggest algorithm improvements
- Propose architectural changes
- Define performance budgets

### 3. Scalability Planning
- Horizontal scaling strategies
- Vertical scaling recommendations
- Load balancing approaches
- Resource allocation optimization

### 4. Monitoring Integration
- Performance metric definition
- Monitoring tool configuration
- Alert threshold setting
- Dashboard creation

## Performance Categories

### Application Performance

#### Response Time Optimization
- **Target**: < 100ms for API responses
- **Strategies**:
  - Database query optimization
  - Caching implementation
  - Async processing
  - Connection pooling

#### Throughput Enhancement
- **Target**: Handle 10K+ requests/second
- **Strategies**:
  - Load balancing
  - Request batching
  - Resource pooling
  - Parallel processing

#### Memory Management
- **Target**: < 80% memory utilization
- **Strategies**:
  - Object pooling
  - Garbage collection tuning
  - Memory leak detection
  - Buffer optimization

### Database Performance

#### Query Optimization
```sql
-- Before optimization
SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.created_at > '2023-01-01'
ORDER BY o.total_amount DESC;

-- After optimization
SELECT o.id, o.total_amount, c.name, c.email
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.created_at > '2023-01-01'
  AND o.status = 'completed'
ORDER BY o.total_amount DESC
LIMIT 100;

-- With index suggestion
CREATE INDEX idx_orders_created_status 
ON orders(created_at, status) 
INCLUDE (total_amount);
```

#### Connection Pooling
```typescript
// Optimized connection pool configuration
const poolConfig = {
  min: 5,                    // Minimum connections
  max: 20,                   // Maximum connections
  idleTimeoutMillis: 30000,  // Close idle connections
  connectionTimeoutMillis: 2000, // Connection timeout
  statement_timeout: 5000,   // Query timeout
  query_timeout: 5000        // Global query timeout
};
```

### Network Performance

#### API Optimization
```typescript
// Response compression
app.use(compression({
  level: 6,
  threshold: 1024,
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  }
}));

// Response caching
app.use('/api/products', cache({
  ttl: 300,  // 5 minutes
  key: (req) => `products:${req.query.category}`,
  condition: (req) => req.method === 'GET'
}));
```

#### CDN Strategy
```javascript
// CDN configuration
const cdnConfig = {
  origins: ['https://api.example.com'],
  behaviors: [{
    path: '/static/*',
    ttl: 86400,  // 24 hours
    compress: true
  }, {
    path: '/api/*',
    ttl: 300,    // 5 minutes
    headers: ['Authorization']
  }]
};
```

## Optimization Patterns

### Caching Strategies

#### Multi-Level Caching
```typescript
class CacheManager {
  private l1Cache: MemoryCache;  // In-memory cache
  private l2Cache: RedisCache;   // Redis cache
  private l3Cache: CDNCache;     // CDN cache

  async get(key: string): Promise<any> {
    // Check L1 (fastest)
    let value = await this.l1Cache.get(key);
    if (value) return value;

    // Check L2
    value = await this.l2Cache.get(key);
    if (value) {
      await this.l1Cache.set(key, value, 60); // 1 minute
      return value;
    }

    // Check L3
    value = await this.l3Cache.get(key);
    if (value) {
      await this.l2Cache.set(key, value, 300); // 5 minutes
      await this.l1Cache.set(key, value, 60);
      return value;
    }

    return null;
  }
}
```

#### Cache Invalidation
```typescript
class SmartCache {
  async invalidate(pattern: string): Promise<void> {
    // Tag-based invalidation
    const tags = await this.getTagsForPattern(pattern);
    await Promise.all(tags.map(tag => this.invalidateTag(tag)));

    // Time-based invalidation
    await this.scheduleInvalidation(pattern, this.getTTL(pattern));

    // Event-based invalidation
    this.eventBus.emit('cache:invalidated', { pattern, tags });
  }
}
```

### Async Processing

#### Queue Implementation
```typescript
class JobQueue {
  async process(job: Job): Promise<void> {
    // Immediate response
    const jobId = await this.enqueue(job);
    
    // Background processing
    this.worker.process(async (job) => {
      try {
        await this.executeJob(job);
        await this.notifyCompletion(job);
      } catch (error) {
        await this.handleFailure(job, error);
      }
    });

    return { jobId, status: 'queued' };
  }
}
```

#### Batch Processing
```typescript
class BatchProcessor {
  private batch: Item[] = [];
  private batchSize = 100;
  private flushInterval = 1000; // 1 second

  async add(item: Item): Promise<void> {
    this.batch.push(item);
    
    if (this.batch.length >= this.batchSize) {
      await this.flush();
    }
  }

  private async flush(): Promise<void> {
    if (this.batch.length === 0) return;

    const items = this.batch.splice(0);
    await this.processBatch(items);
  }
}
```

## Performance Metrics

### Key Performance Indicators

#### Application Metrics
- **Response Time**: p50, p95, p99 percentiles
- **Throughput**: Requests per second
- **Error Rate**: Errors per minute
- **Availability**: Uptime percentage

#### Resource Metrics
- **CPU Usage**: Average and peak
- **Memory Usage**: Heap and non-heap
- **Disk I/O**: Read/write operations
- **Network I/O**: Bandwidth utilization

#### Business Metrics
- **Page Load Time**: Time to interactive
- **Transaction Rate**: Successful transactions/hour
- **Queue Length**: Pending job count
- **Cache Hit Rate**: Cache effectiveness

### Monitoring Implementation

```typescript
class PerformanceMonitor {
  private metrics: MetricsCollector;

  async trackRequest(req: Request, res: Response): Promise<void> {
    const start = process.hrtime.bigint();
    
    res.on('finish', () => {
      const duration = Number(process.hrtime.bigint() - start) / 1e6;
      
      this.metrics.histogram('http_request_duration_ms', duration, {
        method: req.method,
        route: req.route.path,
        status: res.statusCode
      });
    });
  }

  async trackDatabaseQuery(query: string, duration: number): Promise<void> {
    this.metrics.histogram('db_query_duration_ms', duration, {
      query_type: this.getQueryType(query),
      table: this.getTableName(query)
    });
  }
}
```

## Optimization Techniques

### Algorithm Optimization

#### Time Complexity Improvements
```typescript
// O(n²) to O(n log n)
// Before: Nested loops
function findDuplicates(arr: number[]): number[] {
  const duplicates: number[] = [];
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] === arr[j] && !duplicates.includes(arr[i])) {
        duplicates.push(arr[i]);
      }
    }
  }
  return duplicates;
}

// After: Using Set
function findDuplicatesOptimized(arr: number[]): number[] {
  const seen = new Set<number>();
  const duplicates = new Set<number>();
  
  for (const num of arr) {
    if (seen.has(num)) {
      duplicates.add(num);
    } else {
      seen.add(num);
    }
  }
  
  return Array.from(duplicates);
}
```

### Database Optimization

#### Index Strategy
```sql
-- Covering index for common queries
CREATE INDEX idx_users_email_status_created
ON users(email, status, created_at)
INCLUDE (name, last_login);

-- Partial index for specific conditions
CREATE INDEX idx_orders_pending
ON orders(created_at)
WHERE status = 'pending';

-- Expression index for computed values
CREATE INDEX idx_products_lower_name
ON products(LOWER(name));
```

#### Query Rewriting
```sql
-- Avoid N+1 queries
-- Before: Multiple queries
SELECT * FROM users WHERE id = 1;
SELECT * FROM orders WHERE user_id = 1;
SELECT * FROM addresses WHERE user_id = 1;

-- After: Single query with joins
SELECT u.*, o.*, a.*
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
LEFT JOIN addresses a ON u.id = a.user_id
WHERE u.id = 1;
```

## Scalability Patterns

### Horizontal Scaling

#### Load Balancing
```nginx
upstream backend {
    least_conn;  # Least connections algorithm
    
    server backend1.example.com weight=3;
    server backend2.example.com weight=2;
    server backend3.example.com weight=1;
    
    keepalive 32;  # Connection pooling
}
```

#### Service Mesh
```yaml
# Istio configuration for traffic management
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-service
spec:
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: api-service
        subset: v2
      weight: 20  # 20% canary traffic
  - route:
    - destination:
        host: api-service
        subset: v1
      weight: 80
```

### Vertical Scaling

#### Resource Optimization
```yaml
# Kubernetes resource limits
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Best Practices

### Performance Design Principles
1. **Design for failure**: Assume components will fail
2. **Cache aggressively**: But invalidate intelligently
3. **Async by default**: Don't block on I/O
4. **Monitor everything**: You can't optimize what you don't measure
5. **Budget performance**: Set and enforce performance budgets

### Anti-Patterns to Avoid
- Premature optimization
- Over-caching
- Synchronous blocking calls
- Unbounded resource usage
- Missing database indexes

## Tools and Technologies

### Profiling Tools
- APM solutions (New Relic, DataDog)
- Profilers (Chrome DevTools, Java Flight Recorder)
- Load testing (JMeter, k6, Gatling)
- Database analyzers (EXPLAIN, Query Profiler)

### Optimization Libraries
- Caching: Redis, Memcached, Hazelcast
- Message queues: RabbitMQ, Kafka, SQS
- Search: Elasticsearch, Solr
- CDN: CloudFlare, Akamai, Fastly

## Continuous Optimization

### Performance Testing
```typescript
// Automated performance tests
describe('API Performance', () => {
  it('should respond within 100ms', async () => {
    const start = Date.now();
    await api.get('/users');
    const duration = Date.now() - start;
    
    expect(duration).toBeLessThan(100);
  });

  it('should handle 1000 concurrent requests', async () => {
    const results = await loadTest({
      url: 'https://api.example.com/users',
      concurrent: 1000,
      duration: '30s'
    });
    
    expect(results.errors).toBeLessThan(10);
    expect(results.p95).toBeLessThan(200);
  });
});
```

### Optimization Workflow
1. **Baseline**: Establish current performance
2. **Profile**: Identify bottlenecks
3. **Optimize**: Implement improvements
4. **Validate**: Confirm improvements
5. **Monitor**: Track long-term performance