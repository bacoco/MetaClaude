#!/usr/bin/env python3
"""
Test script for MetaClaude performance optimizations
Demonstrates cache, async execution, and connection pooling
"""

import asyncio
import json
import time
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from registry_cache import RegistryCache, init_cache
from job_queue import JobQueue, JobPriority, init_queue
from tool_execution_service import ToolExecutionService


async def test_cache_performance():
    """Test registry cache performance"""
    print("\n=== Testing Registry Cache Performance ===")
    
    # Initialize cache
    registry_path = Path(__file__).parent.parent / "registry.json"
    cache = init_cache(
        registry_path,
        cache_size=100,
        cache_memory_mb=50,
        enable_watching=True
    )
    
    # Test script lookup performance
    script_id = "data-yaml-to-json"
    
    # Cold lookup (cache miss)
    start = time.time()
    script = cache.get_script(script_id)
    cold_time = time.time() - start
    print(f"Cold lookup: {cold_time*1000:.2f}ms")
    
    # Warm lookups (cache hits)
    times = []
    for _ in range(1000):
        start = time.time()
        script = cache.get_script(script_id)
        times.append(time.time() - start)
    
    avg_time = sum(times) / len(times)
    print(f"Warm lookup average (1000 calls): {avg_time*1000:.4f}ms")
    print(f"Speedup: {cold_time/avg_time:.1f}x")
    
    # Test specialist lookup
    specialist = "data-processor"
    start = time.time()
    scripts = cache.get_scripts_by_specialist(specialist)
    print(f"\nSpecialist lookup: {(time.time()-start)*1000:.2f}ms ({len(scripts)} scripts)")
    
    # Show cache stats
    stats = cache.get_stats()
    print(f"\nCache Statistics:")
    print(json.dumps(stats['lru_cache'], indent=2))
    
    cache.close()


async def test_async_execution():
    """Test async job queue execution"""
    print("\n=== Testing Async Job Execution ===")
    
    # Initialize service
    registry_path = Path(__file__).parent.parent / "registry.json"
    tes = ToolExecutionService(
        registry_path,
        enable_cache=True,
        enable_async=True
    )
    
    # Initialize async queue
    await tes.init_async_queue(concurrency_limit=3)
    
    # Progress callback
    def progress_callback(job_id: str, progress):
        print(f"  Job {job_id[:8]}: {progress.percentage:.0f}% - {progress.message}")
    
    # Submit multiple jobs with different priorities
    job_ids = []
    
    # High priority job
    job_id = await tes.execute_async(
        "data-yaml-to-json",
        {"input": "test.yaml", "output": "test.json"},
        priority=JobPriority.HIGH,
        progress_callback=progress_callback
    )
    job_ids.append(("HIGH", job_id))
    print(f"Submitted HIGH priority job: {job_id}")
    
    # Normal priority jobs
    for i in range(3):
        job_id = await tes.execute_async(
            "monitoring-metrics-collector",
            {"interval": 60},
            priority=JobPriority.NORMAL,
            progress_callback=progress_callback
        )
        job_ids.append(("NORMAL", job_id))
        print(f"Submitted NORMAL priority job: {job_id}")
    
    # Low priority job
    job_id = await tes.execute_async(
        "data-yaml-to-json",
        {"input": "large.yaml", "output": "large.json"},
        priority=JobPriority.LOW,
        progress_callback=progress_callback
    )
    job_ids.append(("LOW", job_id))
    print(f"Submitted LOW priority job: {job_id}")
    
    # Monitor execution
    print("\nMonitoring job execution...")
    await asyncio.sleep(2)
    
    # Check queue stats
    if tes.job_queue:
        stats = tes.job_queue.get_queue_stats()
        print(f"\nQueue Statistics:")
        print(json.dumps(stats, indent=2))
    
    # Wait a bit for jobs to complete
    await asyncio.sleep(5)
    
    # Check final status
    print("\nFinal Job Status:")
    for priority, job_id in job_ids:
        if tes.job_queue:
            status = tes.job_queue.get_job_status(job_id)
            if status:
                print(f"  {priority} {job_id[:8]}: {status['status']}")
    
    # Cleanup
    if tes.job_queue:
        await tes.job_queue.stop(graceful=True)
    tes.close()


def test_sync_execution_with_stats():
    """Test synchronous execution with statistics"""
    print("\n=== Testing Sync Execution with Stats ===")
    
    # Initialize service
    registry_path = Path(__file__).parent.parent / "registry.json"
    tes = ToolExecutionService(
        registry_path,
        enable_cache=True
    )
    
    # Execute a script multiple times
    script_id = "data-yaml-to-json"
    
    print(f"Executing {script_id} multiple times...")
    
    for i in range(3):
        start = time.time()
        
        # Create test arguments
        arguments = {
            "input": f"test{i}.yaml",
            "output": f"test{i}.json"
        }
        
        # Execute with progress tracking
        execution_id = f"test-exec-{i}"
        
        def progress_callback(exec_id, percentage, message):
            print(f"  [{exec_id}] {percentage}% - {message}")
        
        tes.register_progress_callback(execution_id, progress_callback)
        
        result = tes.execute(script_id, arguments, execution_id=execution_id)
        
        elapsed = time.time() - start
        
        print(f"  Execution {i+1}: {'Success' if result.success else 'Failed'} ({elapsed:.2f}s)")
        
        if result.error:
            print(f"    Error: {result.error}")
        
        tes.unregister_progress_callback(execution_id)
    
    # Show execution statistics
    print(f"\nExecution Statistics for {script_id}:")
    stats = tes.get_execution_stats(script_id)
    print(json.dumps(stats, indent=2))
    
    # Show cache statistics
    print(f"\nCache Statistics:")
    cache_stats = tes.get_cache_stats()
    if cache_stats:
        print(json.dumps(cache_stats['lru_cache'], indent=2))
    
    # Show connection pool stats
    print(f"\nConnection Pool Statistics:")
    pool_stats = tes.get_connection_pool_stats()
    print(json.dumps(pool_stats, indent=2))
    
    tes.close()


def test_connection_pooling():
    """Test connection pooling functionality"""
    print("\n=== Testing Connection Pooling ===")
    
    from tool_execution_service import ConnectionPool, REQUESTS_AVAILABLE
    
    pool = ConnectionPool()
    
    if REQUESTS_AVAILABLE:
        # Test HTTP session pooling
        session = pool.get_http_session()
        if session:
            print("HTTP session pool initialized successfully")
            
            # Make a test request
            try:
                response = session.get("https://httpbin.org/delay/1", timeout=5)
                print(f"Test request status: {response.status_code}")
            except Exception as e:
                print(f"Test request failed: {e}")
    else:
        print("requests library not available, skipping HTTP pool test")
    
    # Show pool stats
    print("\nConnection pools initialized:")
    if 'http' in pool.sessions:
        print("  - HTTP session pool: Active")
    if 'postgres' in pool.pools:
        print("  - PostgreSQL pool: Active")
    if 'mongodb' in pool.pools:
        print("  - MongoDB pool: Active")
    
    pool.close_all()
    print("\nAll connection pools closed")


async def run_all_tests():
    """Run all performance tests"""
    print("MetaClaude Performance Optimization Tests")
    print("=" * 50)
    
    # Test cache performance
    await test_cache_performance()
    
    # Test connection pooling
    test_connection_pooling()
    
    # Test sync execution with stats
    test_sync_execution_with_stats()
    
    # Test async execution
    await test_async_execution()
    
    print("\n" + "=" * 50)
    print("All tests completed!")


if __name__ == "__main__":
    # Run all tests
    asyncio.run(run_all_tests())