#!/usr/bin/env python3
"""
Async Job Queue for MetaClaude Script Execution
Priority-based job queue with progress tracking and graceful shutdown
"""

import asyncio
import json
import uuid
import time
import signal
import logging
import pickle
from pathlib import Path
from typing import Dict, Any, Optional, List, Callable, Union
from dataclasses import dataclass, field, asdict
from datetime import datetime
from enum import Enum, auto
from collections import defaultdict
import threading
from concurrent.futures import ThreadPoolExecutor
import queue


class JobPriority(Enum):
    """Job priority levels"""
    HIGH = 1
    NORMAL = 2
    LOW = 3


class JobStatus(Enum):
    """Job execution status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    RETRYING = "retrying"


@dataclass
class JobProgress:
    """Job progress information"""
    current: int = 0
    total: int = 100
    message: str = ""
    percentage: float = 0.0
    
    def update(self, current: int, total: Optional[int] = None, message: Optional[str] = None):
        """Update progress"""
        self.current = current
        if total is not None:
            self.total = total
        if message is not None:
            self.message = message
        self.percentage = (self.current / self.total * 100) if self.total > 0 else 0


@dataclass
class JobResult:
    """Job execution result"""
    success: bool
    data: Any = None
    error: Optional[str] = None
    execution_time: float = 0.0
    retry_count: int = 0


@dataclass
class Job:
    """Job definition"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    script_id: str = ""
    arguments: Dict[str, Any] = field(default_factory=dict)
    priority: JobPriority = JobPriority.NORMAL
    status: JobStatus = JobStatus.PENDING
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    progress: JobProgress = field(default_factory=JobProgress)
    result: Optional[JobResult] = None
    error: Optional[str] = None
    retry_count: int = 0
    max_retries: int = 3
    callback_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        data = asdict(self)
        data['priority'] = self.priority.value
        data['status'] = self.status.value
        data['created_at'] = self.created_at.isoformat()
        data['started_at'] = self.started_at.isoformat() if self.started_at else None
        data['completed_at'] = self.completed_at.isoformat() if self.completed_at else None
        return data
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Job':
        """Create from dictionary"""
        job = cls()
        
        # Handle enums
        if 'priority' in data:
            job.priority = JobPriority(data['priority'])
        if 'status' in data:
            job.status = JobStatus(data['status'])
        
        # Handle dates
        if 'created_at' in data and data['created_at']:
            job.created_at = datetime.fromisoformat(data['created_at'])
        if 'started_at' in data and data['started_at']:
            job.started_at = datetime.fromisoformat(data['started_at'])
        if 'completed_at' in data and data['completed_at']:
            job.completed_at = datetime.fromisoformat(data['completed_at'])
        
        # Copy other fields
        for field in ['id', 'script_id', 'arguments', 'error', 'retry_count', 
                      'max_retries', 'callback_id', 'metadata']:
            if field in data:
                setattr(job, field, data[field])
        
        # Handle nested objects
        if 'progress' in data:
            job.progress = JobProgress(**data['progress'])
        if 'result' in data and data['result']:
            job.result = JobResult(**data['result'])
        
        return job


class JobStore:
    """Persistent job storage"""
    
    def __init__(self, storage_path: Path):
        self.storage_path = storage_path
        self.storage_path.mkdir(parents=True, exist_ok=True)
        self.lock = threading.Lock()
    
    def save_job(self, job: Job):
        """Save job to disk"""
        with self.lock:
            job_file = self.storage_path / f"{job.id}.json"
            with open(job_file, 'w') as f:
                json.dump(job.to_dict(), f, indent=2)
    
    def load_job(self, job_id: str) -> Optional[Job]:
        """Load job from disk"""
        with self.lock:
            job_file = self.storage_path / f"{job_id}.json"
            if job_file.exists():
                try:
                    with open(job_file, 'r') as f:
                        data = json.load(f)
                    return Job.from_dict(data)
                except Exception as e:
                    logging.error(f"Failed to load job {job_id}: {e}")
            return None
    
    def delete_job(self, job_id: str):
        """Delete job from disk"""
        with self.lock:
            job_file = self.storage_path / f"{job_id}.json"
            if job_file.exists():
                job_file.unlink()
    
    def list_jobs(self) -> List[Job]:
        """List all stored jobs"""
        with self.lock:
            jobs = []
            for job_file in self.storage_path.glob("*.json"):
                try:
                    with open(job_file, 'r') as f:
                        data = json.load(f)
                    jobs.append(Job.from_dict(data))
                except Exception as e:
                    logging.error(f"Failed to load job from {job_file}: {e}")
            return jobs
    
    def cleanup_completed(self, older_than_hours: int = 24):
        """Clean up old completed jobs"""
        cutoff_time = datetime.now().timestamp() - (older_than_hours * 3600)
        
        with self.lock:
            for job_file in self.storage_path.glob("*.json"):
                try:
                    # Check modification time
                    if job_file.stat().st_mtime < cutoff_time:
                        with open(job_file, 'r') as f:
                            data = json.load(f)
                        
                        # Only delete completed/failed jobs
                        status = data.get('status')
                        if status in [JobStatus.COMPLETED.value, JobStatus.FAILED.value]:
                            job_file.unlink()
                            logging.info(f"Cleaned up old job: {job_file.stem}")
                
                except Exception as e:
                    logging.error(f"Error during cleanup: {e}")


class PriorityQueue:
    """Thread-safe priority queue"""
    
    def __init__(self):
        self.queues = {
            JobPriority.HIGH: queue.Queue(),
            JobPriority.NORMAL: queue.Queue(),
            JobPriority.LOW: queue.Queue()
        }
        self.size = 0
        self.lock = threading.Lock()
    
    def put(self, job: Job):
        """Add job to queue"""
        with self.lock:
            self.queues[job.priority].put(job)
            self.size += 1
    
    def get(self, timeout: Optional[float] = None) -> Optional[Job]:
        """Get next job by priority"""
        end_time = time.time() + timeout if timeout else None
        
        while True:
            # Try each priority level
            for priority in JobPriority:
                try:
                    remaining_timeout = None
                    if end_time:
                        remaining_timeout = max(0, end_time - time.time())
                        if remaining_timeout <= 0:
                            return None
                    
                    job = self.queues[priority].get_nowait()
                    with self.lock:
                        self.size -= 1
                    return job
                
                except queue.Empty:
                    continue
            
            # No jobs available
            if timeout is None:
                time.sleep(0.01)
            else:
                remaining = end_time - time.time()
                if remaining <= 0:
                    return None
                time.sleep(min(0.01, remaining))
    
    def qsize(self) -> int:
        """Get total queue size"""
        with self.lock:
            return self.size
    
    def empty(self) -> bool:
        """Check if queue is empty"""
        return self.qsize() == 0


class JobQueue:
    """Main async job queue system"""
    
    def __init__(self,
                 concurrency_limit: int = 5,
                 storage_path: Optional[Path] = None,
                 executor_service=None):
        
        self.concurrency_limit = concurrency_limit
        self.storage_path = storage_path or Path.home() / ".metaclaude" / "jobs"
        self.executor_service = executor_service
        
        # Job tracking
        self.jobs: Dict[str, Job] = {}
        self.job_lock = threading.RLock()
        
        # Queue
        self.queue = PriorityQueue()
        
        # Storage
        self.store = JobStore(self.storage_path)
        
        # Progress callbacks
        self.progress_callbacks: Dict[str, Callable] = {}
        
        # Workers
        self.workers: List[asyncio.Task] = []
        self.running = False
        self.shutdown_event = asyncio.Event()
        
        # Stats
        self.stats = {
            'total_submitted': 0,
            'total_completed': 0,
            'total_failed': 0,
            'current_running': 0
        }
        
        # Thread pool for sync execution
        self.thread_pool = ThreadPoolExecutor(max_workers=concurrency_limit)
        
        # Load persisted jobs
        self._load_persisted_jobs()
    
    def submit_job(self,
                   script_id: str,
                   arguments: Dict[str, Any],
                   priority: JobPriority = JobPriority.NORMAL,
                   callback: Optional[Callable] = None,
                   metadata: Optional[Dict[str, Any]] = None) -> str:
        """Submit a new job"""
        job = Job(
            script_id=script_id,
            arguments=arguments,
            priority=priority,
            metadata=metadata or {}
        )
        
        # Register callback
        if callback:
            callback_id = str(uuid.uuid4())
            self.progress_callbacks[callback_id] = callback
            job.callback_id = callback_id
        
        # Track job
        with self.job_lock:
            self.jobs[job.id] = job
            self.stats['total_submitted'] += 1
        
        # Persist job
        self.store.save_job(job)
        
        # Queue job
        self.queue.put(job)
        
        logging.info(f"Job submitted: {job.id} (priority: {priority.name})")
        
        return job.id
    
    def get_job_status(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job status"""
        with self.job_lock:
            job = self.jobs.get(job_id)
            if not job:
                # Try loading from storage
                job = self.store.load_job(job_id)
            
            if job:
                return {
                    'id': job.id,
                    'status': job.status.value,
                    'progress': {
                        'current': job.progress.current,
                        'total': job.progress.total,
                        'percentage': job.progress.percentage,
                        'message': job.progress.message
                    },
                    'created_at': job.created_at.isoformat(),
                    'started_at': job.started_at.isoformat() if job.started_at else None,
                    'completed_at': job.completed_at.isoformat() if job.completed_at else None,
                    'result': asdict(job.result) if job.result else None,
                    'error': job.error,
                    'retry_count': job.retry_count
                }
        
        return None
    
    def cancel_job(self, job_id: str) -> bool:
        """Cancel a pending job"""
        with self.job_lock:
            job = self.jobs.get(job_id)
            if job and job.status == JobStatus.PENDING:
                job.status = JobStatus.CANCELLED
                job.completed_at = datetime.now()
                self.store.save_job(job)
                logging.info(f"Job cancelled: {job_id}")
                return True
        
        return False
    
    def get_queue_stats(self) -> Dict[str, Any]:
        """Get queue statistics"""
        with self.job_lock:
            status_counts = defaultdict(int)
            for job in self.jobs.values():
                status_counts[job.status.value] += 1
            
            return {
                'queue_size': self.queue.qsize(),
                'concurrency_limit': self.concurrency_limit,
                'stats': self.stats,
                'status_counts': dict(status_counts),
                'active_workers': len(self.workers)
            }
    
    async def start(self):
        """Start the job queue"""
        if self.running:
            return
        
        self.running = True
        self.shutdown_event.clear()
        
        # Start workers
        for i in range(self.concurrency_limit):
            worker = asyncio.create_task(self._worker(f"worker-{i}"))
            self.workers.append(worker)
        
        logging.info(f"Job queue started with {self.concurrency_limit} workers")
    
    async def stop(self, graceful: bool = True):
        """Stop the job queue"""
        if not self.running:
            return
        
        logging.info("Stopping job queue...")
        self.running = False
        self.shutdown_event.set()
        
        if graceful:
            # Wait for workers to finish current jobs
            await asyncio.gather(*self.workers, return_exceptions=True)
        else:
            # Cancel all workers
            for worker in self.workers:
                worker.cancel()
        
        self.workers.clear()
        
        # Persist remaining jobs
        self._persist_pending_jobs()
        
        # Shutdown thread pool
        self.thread_pool.shutdown(wait=graceful)
        
        logging.info("Job queue stopped")
    
    async def _worker(self, worker_id: str):
        """Worker coroutine"""
        logging.info(f"Worker {worker_id} started")
        
        while self.running:
            try:
                # Get next job
                job = await asyncio.get_event_loop().run_in_executor(
                    None, self.queue.get, 1.0
                )
                
                if not job:
                    continue
                
                # Skip cancelled jobs
                if job.status == JobStatus.CANCELLED:
                    continue
                
                # Update job status
                job.status = JobStatus.RUNNING
                job.started_at = datetime.now()
                
                with self.job_lock:
                    self.stats['current_running'] += 1
                
                self.store.save_job(job)
                
                # Execute job
                await self._execute_job(job)
                
                with self.job_lock:
                    self.stats['current_running'] -= 1
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logging.error(f"Worker {worker_id} error: {e}")
        
        logging.info(f"Worker {worker_id} stopped")
    
    async def _execute_job(self, job: Job):
        """Execute a single job"""
        start_time = time.time()
        
        try:
            # Update progress callback
            await self._update_progress(job, 0, 100, "Starting execution...")
            
            # Execute script
            if self.executor_service:
                # Use provided executor service
                result = await asyncio.get_event_loop().run_in_executor(
                    self.thread_pool,
                    self._execute_script,
                    job
                )
            else:
                # Simulate execution
                result = await self._simulate_execution(job)
            
            # Update job result
            job.status = JobStatus.COMPLETED
            job.completed_at = datetime.now()
            job.result = result
            
            with self.job_lock:
                self.stats['total_completed'] += 1
            
            # Final progress update
            await self._update_progress(job, 100, 100, "Completed")
            
            logging.info(f"Job completed: {job.id}")
            
        except Exception as e:
            # Handle failure
            job.error = str(e)
            
            # Check retry
            if job.retry_count < job.max_retries:
                job.retry_count += 1
                job.status = JobStatus.RETRYING
                logging.warning(f"Job {job.id} failed, retrying ({job.retry_count}/{job.max_retries})")
                
                # Re-queue with delay
                await asyncio.sleep(2 ** job.retry_count)  # Exponential backoff
                job.status = JobStatus.PENDING
                self.queue.put(job)
            else:
                job.status = JobStatus.FAILED
                job.completed_at = datetime.now()
                
                with self.job_lock:
                    self.stats['total_failed'] += 1
                
                logging.error(f"Job failed: {job.id} - {e}")
        
        finally:
            # Save final state
            self.store.save_job(job)
            
            # Cleanup callback
            if job.callback_id:
                self.progress_callbacks.pop(job.callback_id, None)
    
    def _execute_script(self, job: Job) -> JobResult:
        """Execute script using tool execution service"""
        if not self.executor_service:
            raise RuntimeError("No executor service configured")
        
        result = self.executor_service.execute(job.script_id, job.arguments)
        
        return JobResult(
            success=result.success,
            data=result.outputs,
            error=result.error,
            execution_time=result.execution_time,
            retry_count=result.retry_count
        )
    
    async def _simulate_execution(self, job: Job) -> JobResult:
        """Simulate script execution for testing"""
        # Simulate work with progress updates
        total_steps = 10
        for i in range(total_steps):
            await asyncio.sleep(0.5)
            progress = int((i + 1) / total_steps * 100)
            await self._update_progress(
                job, i + 1, total_steps,
                f"Processing step {i + 1}/{total_steps}"
            )
        
        return JobResult(
            success=True,
            data={'message': f'Simulated execution of {job.script_id}'},
            execution_time=5.0
        )
    
    async def _update_progress(self, job: Job, current: int, total: int, message: str):
        """Update job progress and notify callback"""
        job.progress.update(current, total, message)
        
        # Notify callback
        if job.callback_id and job.callback_id in self.progress_callbacks:
            callback = self.progress_callbacks[job.callback_id]
            try:
                await asyncio.get_event_loop().run_in_executor(
                    None, callback, job.id, job.progress
                )
            except Exception as e:
                logging.error(f"Progress callback error: {e}")
    
    def _load_persisted_jobs(self):
        """Load persisted jobs on startup"""
        jobs = self.store.list_jobs()
        pending_count = 0
        
        for job in jobs:
            # Re-queue pending and retrying jobs
            if job.status in [JobStatus.PENDING, JobStatus.RETRYING]:
                job.status = JobStatus.PENDING  # Reset to pending
                self.jobs[job.id] = job
                self.queue.put(job)
                pending_count += 1
            
            # Track other jobs
            elif job.status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
                self.jobs[job.id] = job
        
        if pending_count > 0:
            logging.info(f"Loaded {pending_count} pending jobs from storage")
    
    def _persist_pending_jobs(self):
        """Persist all pending jobs"""
        with self.job_lock:
            for job in self.jobs.values():
                if job.status in [JobStatus.PENDING, JobStatus.RUNNING]:
                    # Reset running jobs to pending
                    if job.status == JobStatus.RUNNING:
                        job.status = JobStatus.PENDING
                    self.store.save_job(job)


# Global queue instance
_global_queue: Optional[JobQueue] = None


async def init_queue(**kwargs) -> JobQueue:
    """Initialize global queue instance"""
    global _global_queue
    _global_queue = JobQueue(**kwargs)
    await _global_queue.start()
    return _global_queue


def get_queue() -> Optional[JobQueue]:
    """Get global queue instance"""
    return _global_queue


async def close_queue(graceful: bool = True):
    """Close global queue instance"""
    global _global_queue
    if _global_queue:
        await _global_queue.stop(graceful)
        _global_queue = None


if __name__ == "__main__":
    # Example usage and testing
    import argparse
    
    parser = argparse.ArgumentParser(description="Job Queue Testing")
    parser.add_argument("--test", action="store_true", help="Run tests")
    parser.add_argument("--workers", type=int, default=3, help="Number of workers")
    
    args = parser.parse_args()
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    async def progress_callback(job_id: str, progress: JobProgress):
        """Example progress callback"""
        print(f"Job {job_id}: {progress.percentage:.1f}% - {progress.message}")
    
    async def run_tests():
        """Run job queue tests"""
        # Initialize queue
        queue = await init_queue(concurrency_limit=args.workers)
        
        print(f"Job queue started with {args.workers} workers")
        
        # Submit test jobs
        job_ids = []
        
        # High priority job
        job_id = queue.submit_job(
            "test-script-1",
            {"arg1": "value1"},
            priority=JobPriority.HIGH,
            callback=progress_callback,
            metadata={"type": "test"}
        )
        job_ids.append(job_id)
        print(f"Submitted high priority job: {job_id}")
        
        # Normal priority jobs
        for i in range(3):
            job_id = queue.submit_job(
                f"test-script-{i+2}",
                {"index": i},
                priority=JobPriority.NORMAL,
                callback=progress_callback
            )
            job_ids.append(job_id)
            print(f"Submitted normal priority job: {job_id}")
        
        # Low priority job
        job_id = queue.submit_job(
            "test-script-5",
            {"arg1": "low"},
            priority=JobPriority.LOW,
            callback=progress_callback
        )
        job_ids.append(job_id)
        print(f"Submitted low priority job: {job_id}")
        
        # Monitor jobs
        print("\nMonitoring jobs...")
        all_completed = False
        
        while not all_completed:
            await asyncio.sleep(2)
            
            # Check job statuses
            statuses = []
            for job_id in job_ids:
                status = queue.get_job_status(job_id)
                if status:
                    statuses.append(status['status'])
            
            # Print queue stats
            stats = queue.get_queue_stats()
            print(f"\nQueue stats: {json.dumps(stats, indent=2)}")
            
            # Check if all completed
            all_completed = all(
                status in ['completed', 'failed', 'cancelled']
                for status in statuses
            )
        
        print("\nAll jobs completed!")
        
        # Show final results
        for job_id in job_ids:
            status = queue.get_job_status(job_id)
            if status:
                print(f"\nJob {job_id}:")
                print(f"  Status: {status['status']}")
                print(f"  Result: {status.get('result')}")
                print(f"  Error: {status.get('error')}")
        
        # Cleanup
        await close_queue()
    
    # Run async main
    if args.test:
        asyncio.run(run_tests())
    else:
        print("Use --test to run job queue tests")