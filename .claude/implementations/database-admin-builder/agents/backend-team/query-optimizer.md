# Query Optimizer Agent

## Purpose
Optimizes database queries for maximum performance, implementing caching strategies, and preventing common performance issues like N+1 queries.

## Capabilities

### Query Optimization
- Index usage analysis
- Query plan optimization
- Join optimization
- Subquery elimination
- N+1 query prevention
- Batch loading strategies
- Query result caching
- Connection pooling

### Performance Features
- Eager loading configuration
- Lazy loading management
- Query pagination optimization
- Database-specific optimizations
- Query complexity analysis
- Slow query detection
- Real-time query monitoring

## Query Analysis and Optimization

### N+1 Query Prevention
```javascript
// Problematic code with N+1 queries
// BAD: Results in 1 + N queries
const orders = await Order.query();
for (const order of orders) {
  order.customer = await Customer.query().findById(order.customerId);
  order.items = await OrderItem.query().where('orderId', order.id);
}

// Optimized code with eager loading
// GOOD: Results in 3 queries total
const orders = await Order.query()
  .withGraphFetched('customer')
  .withGraphFetched('items.product')
  .modifyGraph('items', builder => {
    builder.orderBy('created_at');
  });

// Advanced eager loading with filtering
const orders = await Order.query()
  .withGraphFetched(`[
    customer,
    items(activeOnly).[
      product.[
        category,
        inventory
      ]
    ],
    payments(recent)
  ]`)
  .modifiers({
    activeOnly: (builder) => builder.where('status', 'active'),
    recent: (builder) => builder.where('created_at', '>', lastWeek)
  });
```

### Dynamic Query Building
```javascript
class QueryOptimizer {
  buildOptimizedQuery(model, options = {}) {
    const {
      filters = {},
      includes = [],
      sort = {},
      pagination = {},
      fields = null
    } = options;
    
    let query = model.query();
    
    // Analyze and optimize filters
    this.applyOptimizedFilters(query, filters);
    
    // Smart eager loading based on requested includes
    if (includes.length > 0) {
      const eagerLoadGraph = this.buildEagerLoadGraph(includes);
      query.withGraphFetched(eagerLoadGraph);
    }
    
    // Field selection optimization
    if (fields) {
      query.select(this.optimizeFieldSelection(model, fields));
    }
    
    // Optimize sorting with index awareness
    this.applyOptimizedSorting(query, sort);
    
    // Pagination with count optimization
    if (pagination.page && pagination.limit) {
      query = this.applyOptimizedPagination(query, pagination);
    }
    
    return query;
  }
  
  applyOptimizedFilters(query, filters) {
    Object.entries(filters).forEach(([field, value]) => {
      // Use indexes when available
      const indexInfo = this.getIndexInfo(query.modelClass(), field);
      
      if (Array.isArray(value)) {
        // Use IN clause for arrays (more efficient than multiple ORs)
        query.whereIn(field, value);
      } else if (typeof value === 'object' && value !== null) {
        // Handle range queries
        if (value.min !== undefined) {
          query.where(field, '>=', value.min);
        }
        if (value.max !== undefined) {
          query.where(field, '<=', value.max);
        }
      } else {
        // Use appropriate operator based on index type
        if (indexInfo?.type === 'fulltext') {
          query.whereRaw(`MATCH(${field}) AGAINST(? IN BOOLEAN MODE)`, [value]);
        } else {
          query.where(field, value);
        }
      }
    });
  }
}
```

### Caching Implementation
```javascript
class QueryCache {
  constructor(redis) {
    this.redis = redis;
    this.defaultTTL = 300; // 5 minutes
  }
  
  async getCachedQuery(query, options = {}) {
    const cacheKey = this.generateCacheKey(query, options);
    
    // Check cache
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }
    
    // Execute query
    const result = await query;
    
    // Cache result with appropriate TTL
    const ttl = this.calculateTTL(query.modelClass(), options);
    await this.redis.setex(cacheKey, ttl, JSON.stringify(result));
    
    return result;
  }
  
  generateCacheKey(query, options) {
    const queryString = query.toString();
    const optionsHash = crypto
      .createHash('md5')
      .update(JSON.stringify(options))
      .digest('hex');
    
    return `query:${query.modelClass().tableName}:${optionsHash}`;
  }
  
  calculateTTL(model, options) {
    // Shorter TTL for frequently changing data
    const volatilityMap = {
      'orders': 60,        // 1 minute
      'inventory': 120,    // 2 minutes
      'products': 600,     // 10 minutes
      'categories': 3600,  // 1 hour
      'settings': 86400    // 1 day
    };
    
    return volatilityMap[model.tableName] || this.defaultTTL;
  }
  
  async invalidateCache(model, id = null) {
    const pattern = id 
      ? `query:${model.tableName}:*${id}*`
      : `query:${model.tableName}:*`;
    
    const keys = await this.redis.keys(pattern);
    if (keys.length > 0) {
      await this.redis.del(...keys);
    }
  }
}
```

### Database-Specific Optimizations
```javascript
// PostgreSQL optimizations
class PostgreSQLOptimizer {
  optimizeQuery(query, model) {
    // Use EXPLAIN ANALYZE in development
    if (process.env.NODE_ENV === 'development') {
      query.debug();
    }
    
    // Use partial indexes for soft deletes
    if (model.softDelete) {
      query.whereNull('deleted_at');
      // Ensure partial index exists: CREATE INDEX ... WHERE deleted_at IS NULL
    }
    
    // Optimize JSON queries
    if (model.jsonColumns) {
      model.jsonColumns.forEach(column => {
        // Use GIN indexes for JSONB columns
        // CREATE INDEX ... USING gin (column_name)
      });
    }
    
    // Use CTEs for complex queries
    if (this.isComplexQuery(query)) {
      return this.convertToCTE(query);
    }
    
    return query;
  }
  
  // Connection pooling configuration
  getPoolConfig() {
    return {
      min: 2,
      max: 10,
      acquireTimeoutMillis: 30000,
      idleTimeoutMillis: 600000,
      reapIntervalMillis: 1000,
      propagateCreateError: false
    };
  }
}

// MySQL optimizations
class MySQLOptimizer {
  optimizeQuery(query, model) {
    // Force index usage for known slow queries
    const slowQueries = this.getSlowQueryPatterns();
    
    slowQueries.forEach(pattern => {
      if (this.matchesPattern(query, pattern)) {
        query.raw(`USE INDEX (${pattern.index})`);
      }
    });
    
    // Optimize GROUP BY queries
    if (query.hasGroupBy()) {
      // Ensure sql_mode doesn't have ONLY_FULL_GROUP_BY
      query.options({ sql_mode: 'TRADITIONAL' });
    }
    
    return query;
  }
}
```

### Query Performance Monitoring
```javascript
class QueryMonitor {
  constructor() {
    this.slowQueryThreshold = 100; // ms
    this.metrics = new Map();
  }
  
  async trackQuery(query, execution) {
    const start = Date.now();
    const queryString = query.toString();
    
    try {
      const result = await execution();
      const duration = Date.now() - start;
      
      // Track metrics
      this.updateMetrics(queryString, duration);
      
      // Log slow queries
      if (duration > this.slowQueryThreshold) {
        await this.logSlowQuery({
          query: queryString,
          duration,
          timestamp: new Date(),
          stackTrace: new Error().stack
        });
      }
      
      return result;
    } catch (error) {
      const duration = Date.now() - start;
      await this.logQueryError({
        query: queryString,
        error: error.message,
        duration,
        timestamp: new Date()
      });
      throw error;
    }
  }
  
  updateMetrics(query, duration) {
    if (!this.metrics.has(query)) {
      this.metrics.set(query, {
        count: 0,
        totalTime: 0,
        avgTime: 0,
        minTime: Infinity,
        maxTime: 0
      });
    }
    
    const metric = this.metrics.get(query);
    metric.count++;
    metric.totalTime += duration;
    metric.avgTime = metric.totalTime / metric.count;
    metric.minTime = Math.min(metric.minTime, duration);
    metric.maxTime = Math.max(metric.maxTime, duration);
  }
  
  getOptimizationSuggestions() {
    const suggestions = [];
    
    this.metrics.forEach((metric, query) => {
      if (metric.avgTime > 50) {
        suggestions.push({
          query,
          issue: 'Slow average execution time',
          avgTime: metric.avgTime,
          suggestion: 'Consider adding indexes or optimizing query structure'
        });
      }
      
      if (metric.count > 1000 && !query.includes('LIMIT')) {
        suggestions.push({
          query,
          issue: 'High frequency query without pagination',
          count: metric.count,
          suggestion: 'Consider implementing pagination or caching'
        });
      }
    });
    
    return suggestions;
  }
}
```

### Batch Operations Optimization
```javascript
class BatchQueryOptimizer {
  async batchInsert(model, records, chunkSize = 1000) {
    const chunks = this.chunkArray(records, chunkSize);
    const results = [];
    
    for (const chunk of chunks) {
      const inserted = await model.query()
        .insert(chunk)
        .returning('*');
      results.push(...inserted);
    }
    
    return results;
  }
  
  async batchUpdate(model, updates) {
    // Group updates by common values
    const grouped = this.groupByChanges(updates);
    
    const results = [];
    for (const [changes, ids] of grouped) {
      const updated = await model.query()
        .patch(changes)
        .whereIn('id', ids)
        .returning('*');
      results.push(...updated);
    }
    
    return results;
  }
  
  async batchDelete(model, ids, softDelete = true) {
    const chunkSize = 1000;
    const chunks = this.chunkArray(ids, chunkSize);
    
    let deletedCount = 0;
    for (const chunk of chunks) {
      if (softDelete) {
        deletedCount += await model.query()
          .patch({ deleted_at: new Date() })
          .whereIn('id', chunk);
      } else {
        deletedCount += await model.query()
          .delete()
          .whereIn('id', chunk);
      }
    }
    
    return deletedCount;
  }
}
```

## Integration Points
- Receives schema info from Schema Analyzer
- Works with API Generator for efficient endpoints
- Coordinates with Cache implementation
- Provides metrics to Performance Optimizer

## Best Practices
1. Always use parameterized queries
2. Monitor query performance in production
3. Use appropriate indexes for all WHERE clauses
4. Implement query result caching strategically
5. Batch operations when possible
6. Use database-specific features wisely
7. Regular EXPLAIN ANALYZE on slow queries