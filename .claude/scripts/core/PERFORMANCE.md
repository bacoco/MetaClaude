# MetaClaude Performance Optimizations

This directory contains high-performance components for the MetaClaude Global Script Registry.

## Components

### 1. Registry Cache (`registry-cache.py`)

**Features:**
- **In-memory LRU cache** with configurable size (default 100 entries)
- **File watching** for automatic cache invalidation on registry changes
- **Thread-safe operations** for concurrent access
- **Optional Redis backend** for distributed deployments
- **Comprehensive statistics** tracking (hits, misses, evictions)

**Usage:**
```python
from registry_cache import init_cache

# Initialize with local cache only
cache = init_cache("registry.json", cache_size=100)

# Initialize with Redis backend
cache = init_cache("registry.json", redis_url="redis://localhost:6379")

# Get script with caching
script = cache.get_script("script-id")

# Get statistics
stats = cache.get_stats()
```

### 2. Job Queue (`job-queue.py`)

**Features:**
- **Async job queue** with configurable concurrency
- **Priority queue support** (HIGH, NORMAL, LOW)
- **Progress tracking** with callback support
- **Job persistence** for graceful shutdowns
- **Automatic retry** with exponential backoff

**Usage:**
```python
from job_queue import init_queue, JobPriority

# Initialize queue
queue = await init_queue(concurrency_limit=5)

# Submit job
job_id = queue.submit_job(
    script_id="my-script",
    arguments={"arg": "value"},
    priority=JobPriority.HIGH,
    callback=progress_callback
)

# Check status
status = queue.get_job_status(job_id)
```

### 3. Enhanced Tool Execution Service

**Features:**
- **Integrated registry cache** for fast script lookups
- **Async execution support** via job queue
- **Connection pooling** for databases and APIs
- **Progress reporting** for long-running scripts
- **Execution statistics** tracking

**Usage:**
```python
from tool_execution_service import ToolExecutionService

# Initialize with optimizations
tes = ToolExecutionService(
    "registry.json",
    enable_cache=True,
    enable_async=True,
    redis_url="redis://localhost:6379"
)

# Async execution
job_id = await tes.execute_async(
    "script-id",
    {"arg": "value"},
    priority=JobPriority.HIGH
)

# Sync execution with progress
result = tes.execute("script-id", {"arg": "value"})
```

## Performance Benefits

### Cache Performance
- **Cold lookup**: ~5-10ms (file read + parsing)
- **Warm lookup**: ~0.01ms (memory access)
- **Speedup**: 500-1000x for cached lookups

### Async Execution
- **Concurrent jobs**: Up to concurrency limit
- **Job scheduling**: Priority-based with < 1ms overhead
- **Progress updates**: Real-time without blocking execution

### Connection Pooling
- **HTTP requests**: Reuse connections, automatic retries
- **Database queries**: Connection reuse, reduced latency
- **Resource efficiency**: Controlled connection limits

## Configuration Options

### Environment Variables
```bash
# Redis configuration
REDIS_URL=redis://localhost:6379

# Cache settings
CACHE_SIZE=200
CACHE_MEMORY_MB=100

# Job queue settings
JOB_CONCURRENCY=10
JOB_STORAGE_PATH=/var/metaclaude/jobs
```

### Programmatic Configuration
```python
# Full configuration example
tes = ToolExecutionService(
    registry_path="registry.json",
    max_retries=3,
    enable_cache=True,
    enable_async=True,
    cache_size=200,
    redis_url="redis://localhost:6379"
)

# Initialize async queue
await tes.init_async_queue(concurrency_limit=10)

# Configure connection pools
tes.connection_pool.init_postgres_pool(
    host="localhost",
    database="metaclaude",
    minconn=1,
    maxconn=20
)
```

## Monitoring and Statistics

### Cache Statistics
```python
stats = cache.get_stats()
# Returns: hits, misses, evictions, hit_rate, memory_usage
```

### Queue Statistics
```python
stats = queue.get_queue_stats()
# Returns: queue_size, running_jobs, completed_jobs, failed_jobs
```

### Execution Statistics
```python
stats = tes.get_execution_stats("script-id")
# Returns: total_executions, failures, avg_execution_time
```

## Best Practices

1. **Enable caching** for all read-heavy workloads
2. **Use async execution** for long-running or parallel tasks
3. **Set appropriate priorities** to ensure critical tasks run first
4. **Monitor statistics** to identify bottlenecks
5. **Configure connection pools** based on workload
6. **Use Redis backend** for distributed deployments
7. **Implement progress callbacks** for user feedback

## Testing

Run the performance test suite:
```bash
python test-performance.py
```

This will test:
- Cache performance and hit rates
- Async job queue execution
- Connection pooling
- Statistics collection