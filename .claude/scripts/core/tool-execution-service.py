#!/usr/bin/env python3
"""
MetaClaude Tool Execution Service (TES)
Secure execution of registered scripts with validation and sandboxing
"""

import json
import os
import sys
import subprocess
import tempfile
import resource
import signal
import time
import argparse
import psutil
import datetime
import traceback
import asyncio
import concurrent.futures
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple, Callable
from dataclasses import dataclass, field
from enum import Enum
import threading
from collections import defaultdict

# Import performance modules
try:
    from .registry_cache import RegistryCache, init_cache, get_cache
    from .job_queue import JobQueue, JobPriority, JobStatus, init_queue, get_queue
    PERF_MODULES_AVAILABLE = True
except ImportError:
    PERF_MODULES_AVAILABLE = False

# Connection pooling for external resources
try:
    import requests
    from urllib3.util.retry import Retry
    from requests.adapters import HTTPAdapter
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False

try:
    import psycopg2
    from psycopg2 import pool
    POSTGRES_AVAILABLE = True
except ImportError:
    POSTGRES_AVAILABLE = False

try:
    import pymongo
    MONGODB_AVAILABLE = True
except ImportError:
    MONGODB_AVAILABLE = False


class SandboxLevel(Enum):
    """Security sandbox levels"""
    MINIMAL = "minimal"      # Basic file I/O, no network
    STANDARD = "standard"    # File I/O with restrictions
    STRICT = "strict"        # Read-only file access
    NETWORK = "network"      # Network access to allowed hosts


class Permission(Enum):
    """Execution permissions"""
    READ_FILE = "read_file"
    WRITE_FILE = "write_file"
    NETWORK = "network"
    ENV_VARS = "env_vars"


class ErrorCategory(Enum):
    """Error categorization for better debugging"""
    TIMEOUT = "timeout"
    VALIDATION = "validation"
    DEPENDENCY = "dependency"
    EXECUTION = "execution"
    PERMISSION = "permission"
    RESOURCE = "resource"
    UNKNOWN = "unknown"


@dataclass
class ScriptArgument:
    """Script argument definition"""
    name: str
    type: str
    required: bool
    description: str
    default: Any = None
    enum: List[str] = None


@dataclass
class RetryInfo:
    """Retry information for errors"""
    is_retryable: bool
    attempts_made: int
    max_attempts: int
    next_retry_delay: Optional[float] = None
    retry_reason: Optional[str] = None


@dataclass
class ErrorDetails:
    """Detailed error information with comprehensive debugging context"""
    category: ErrorCategory
    message: str
    context: Dict[str, Any] = field(default_factory=dict)
    suggestions: List[str] = field(default_factory=list)
    stack_trace: Optional[str] = None
    raw_error: Optional[str] = None
    retry_info: Optional[RetryInfo] = None


@dataclass
class ResourceUsage:
    """Resource usage tracking"""
    start_memory_mb: float
    end_memory_mb: float
    peak_memory_mb: float
    cpu_time_seconds: float
    wall_time_seconds: float


@dataclass
class ExecutionResult:
    """Result of script execution"""
    success: bool
    exit_code: int
    stdout: str
    stderr: str
    outputs: Dict[str, Any]
    execution_time: float
    error: Optional[str] = None
    error_details: Optional[ErrorDetails] = None
    resource_usage: Optional[ResourceUsage] = None
    start_timestamp: Optional[datetime.datetime] = None
    end_timestamp: Optional[datetime.datetime] = None
    retry_count: int = 0


class ConnectionPool:
    """Manage connection pools for various services"""
    
    def __init__(self):
        self.pools = {}
        self.sessions = {}
        self.lock = threading.Lock()
        
        # Initialize HTTP session pool
        if REQUESTS_AVAILABLE:
            self._init_http_pool()
    
    def _init_http_pool(self, pool_size: int = 10, max_retries: int = 3):
        """Initialize HTTP connection pool with retry logic"""
        session = requests.Session()
        
        # Configure retry strategy
        retry_strategy = Retry(
            total=max_retries,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "PUT", "DELETE", "OPTIONS", "TRACE", "POST"]
        )
        
        adapter = HTTPAdapter(
            pool_connections=pool_size,
            pool_maxsize=pool_size,
            max_retries=retry_strategy
        )
        
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        
        self.sessions['http'] = session
    
    def get_http_session(self) -> Optional[requests.Session]:
        """Get HTTP session from pool"""
        return self.sessions.get('http')
    
    def init_postgres_pool(self, **kwargs) -> Optional[Any]:
        """Initialize PostgreSQL connection pool"""
        if not POSTGRES_AVAILABLE:
            return None
        
        with self.lock:
            if 'postgres' not in self.pools:
                self.pools['postgres'] = psycopg2.pool.ThreadedConnectionPool(
                    minconn=kwargs.get('minconn', 1),
                    maxconn=kwargs.get('maxconn', 10),
                    **kwargs
                )
        
        return self.pools['postgres']
    
    def get_postgres_connection(self):
        """Get PostgreSQL connection from pool"""
        pool = self.pools.get('postgres')
        if pool:
            return pool.getconn()
        return None
    
    def put_postgres_connection(self, conn):
        """Return PostgreSQL connection to pool"""
        pool = self.pools.get('postgres')
        if pool and conn:
            pool.putconn(conn)
    
    def init_mongodb_pool(self, connection_string: str, **kwargs):
        """Initialize MongoDB connection pool"""
        if not MONGODB_AVAILABLE:
            return None
        
        with self.lock:
            if 'mongodb' not in self.pools:
                self.pools['mongodb'] = pymongo.MongoClient(
                    connection_string,
                    maxPoolSize=kwargs.get('maxPoolSize', 10),
                    minPoolSize=kwargs.get('minPoolSize', 1),
                    **kwargs
                )
        
        return self.pools['mongodb']
    
    def get_mongodb_client(self):
        """Get MongoDB client from pool"""
        return self.pools.get('mongodb')
    
    def close_all(self):
        """Close all connection pools"""
        with self.lock:
            # Close HTTP sessions
            for session in self.sessions.values():
                session.close()
            
            # Close PostgreSQL pools
            if 'postgres' in self.pools:
                self.pools['postgres'].closeall()
            
            # Close MongoDB connections
            if 'mongodb' in self.pools:
                self.pools['mongodb'].close()
            
            self.pools.clear()
            self.sessions.clear()


class ToolExecutionService:
    """Main service for executing registered tools with performance optimizations"""
    
    def __init__(self, registry_path: str, max_retries: int = 3,
                 enable_cache: bool = True, enable_async: bool = True,
                 cache_size: int = 100, redis_url: Optional[str] = None):
        self.registry_path = Path(registry_path)
        self.scripts_dir = self.registry_path.parent
        self.max_retries = max_retries
        self.base_retry_delay = 1.0  # seconds
        
        # Initialize cache
        self.cache = None
        if enable_cache and PERF_MODULES_AVAILABLE:
            self.cache = init_cache(
                registry_path,
                cache_size=cache_size,
                redis_url=redis_url
            )
        else:
            # Fallback to loading registry directly
            self.registry = self._load_registry()
        
        # Initialize connection pools
        self.connection_pool = ConnectionPool()
        
        # Async execution support
        self.enable_async = enable_async and PERF_MODULES_AVAILABLE
        self.job_queue = None
        self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=10)
        
        # Progress tracking
        self.progress_callbacks: Dict[str, Callable] = {}
        self.execution_stats = defaultdict(lambda: {
            'total_executions': 0,
            'total_failures': 0,
            'avg_execution_time': 0,
            'last_execution': None
        })
        
    def _load_registry(self) -> Dict[str, Any]:
        """Load the script registry"""
        with open(self.registry_path, 'r') as f:
            return json.load(f)
    
    async def init_async_queue(self, concurrency_limit: int = 5):
        """Initialize async job queue"""
        if self.enable_async:
            self.job_queue = await init_queue(
                concurrency_limit=concurrency_limit,
                executor_service=self
            )
    
    def get_script(self, script_id: str) -> Optional[Dict[str, Any]]:
        """Get script metadata by ID with caching"""
        # Use cache if available
        if self.cache:
            return self.cache.get_script(script_id)
        
        # Fallback to direct registry lookup
        for script in self.registry.get('scripts', []):
            if script['id'] == script_id:
                return script
        return None
    
    def get_scripts_by_specialist(self, specialist: str) -> List[Dict[str, Any]]:
        """Get all scripts for a specialist with caching"""
        if self.cache:
            return self.cache.get_scripts_by_specialist(specialist)
        
        # Fallback
        return [
            script for script in self.registry.get('scripts', [])
            if script.get('specialist') == specialist
        ]
    
    def validate_arguments(self, script: Dict[str, Any], provided_args: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        """Validate provided arguments against script definition"""
        arg_definitions = script.get('execution', {}).get('args', [])
        
        # Check required arguments
        for arg_def in arg_definitions:
            arg = ScriptArgument(**arg_def)
            
            if arg.required and arg.name not in provided_args:
                return False, f"Missing required argument: {arg.name}"
            
            if arg.name in provided_args:
                value = provided_args[arg.name]
                
                # Type validation
                if not self._validate_type(value, arg.type):
                    return False, f"Invalid type for {arg.name}: expected {arg.type}"
                
                # Enum validation
                if arg.enum and value not in arg.enum:
                    return False, f"Invalid value for {arg.name}: must be one of {arg.enum}"
        
        # Check for unknown arguments
        known_args = {arg_def['name'] for arg_def in arg_definitions}
        unknown_args = set(provided_args.keys()) - known_args
        if unknown_args:
            return False, f"Unknown arguments: {unknown_args}"
        
        return True, None
    
    def _validate_type(self, value: Any, expected_type: str) -> bool:
        """Validate value type"""
        type_map = {
            'string': str,
            'number': (int, float),
            'boolean': bool,
            'array': list,
            'object': dict
        }
        
        expected = type_map.get(expected_type)
        if expected:
            return isinstance(value, expected)
        return True
    
    def _apply_sandbox(self, sandbox_level: str, permissions: List[str]) -> Dict[str, Any]:
        """Apply sandbox restrictions and return environment"""
        env = os.environ.copy()
        
        # Remove sensitive environment variables
        sensitive_vars = ['AWS_SECRET_ACCESS_KEY', 'GITHUB_TOKEN', 'API_KEY', 'PASSWORD']
        for var in sensitive_vars:
            env.pop(var, None)
            for key in list(env.keys()):
                if any(sensitive in key for sensitive in sensitive_vars):
                    env.pop(key, None)
        
        # Apply sandbox-specific restrictions
        if sandbox_level == SandboxLevel.STRICT.value:
            # Minimal environment for strict sandbox
            env = {
                'PATH': '/usr/bin:/bin',
                'HOME': tempfile.gettempdir(),
                'TMPDIR': tempfile.gettempdir()
            }
        
        # Add allowed environment variables if permission granted
        if Permission.ENV_VARS.value not in permissions:
            # Keep only essential variables
            allowed_vars = ['PATH', 'HOME', 'TMPDIR', 'LANG', 'LC_ALL']
            env = {k: v for k, v in env.items() if k in allowed_vars}
        
        return env
    
    def _set_resource_limits(self, max_memory: str, timeout: int):
        """Set resource limits for the subprocess"""
        # Parse memory limit
        memory_bytes = self._parse_memory_limit(max_memory)
        
        def limit_resources():
            # Set memory limit
            if memory_bytes:
                resource.setrlimit(resource.RLIMIT_AS, (memory_bytes, memory_bytes))
            
            # Set CPU time limit (timeout + buffer)
            cpu_limit = (timeout // 1000) + 10  # Convert ms to seconds, add buffer
            resource.setrlimit(resource.RLIMIT_CPU, (cpu_limit, cpu_limit))
            
            # Set file size limit (100MB)
            file_limit = 100 * 1024 * 1024
            resource.setrlimit(resource.RLIMIT_FSIZE, (file_limit, file_limit))
            
            # Set process limit
            resource.setrlimit(resource.RLIMIT_NPROC, (50, 50))
        
        return limit_resources
    
    def _parse_memory_limit(self, memory_str: str) -> Optional[int]:
        """Parse memory limit string to bytes"""
        if not memory_str:
            return None
        
        units = {
            'B': 1,
            'KB': 1024,
            'MB': 1024 * 1024,
            'GB': 1024 * 1024 * 1024
        }
        
        for unit, multiplier in units.items():
            if memory_str.upper().endswith(unit):
                try:
                    value = float(memory_str[:-len(unit)])
                    return int(value * multiplier)
                except ValueError:
                    pass
        
        return None
    
    def _get_current_memory_usage(self) -> float:
        """Get current memory usage in MB"""
        process = psutil.Process()
        return process.memory_info().rss / (1024 * 1024)
    
    def _get_cpu_times(self) -> float:
        """Get current CPU time in seconds"""
        process = psutil.Process()
        return process.cpu_times().user + process.cpu_times().system
    
    def _create_error_details(self, category: ErrorCategory, message: str, 
                            script: Optional[Dict[str, Any]] = None,
                            exception: Optional[Exception] = None,
                            retry_count: int = 0) -> ErrorDetails:
        """Create detailed error information with context and suggestions"""
        context = {}
        suggestions = []
        
        if script:
            context['script_id'] = script.get('id')
            context['script_path'] = script.get('path')
            context['specialist'] = script.get('specialist')
        
        # Enhanced error-specific context and suggestions
        if category == ErrorCategory.TIMEOUT:
            context['timeout_ms'] = script.get('execution', {}).get('timeout', 30000) if script else None
            suggestions.extend([
                "Increase the timeout value in the script configuration",
                "Optimize the script to run faster by:",
                "  - Reducing data processing size",
                "  - Using batch operations instead of loops",
                "  - Implementing pagination for large datasets",
                "Check for infinite loops or blocking operations",
                "Consider running the script asynchronously",
                "Profile the script to identify performance bottlenecks"
            ])
        
        elif category == ErrorCategory.VALIDATION:
            if 'Missing required argument' in message:
                suggestions.extend([
                    "Provide all required arguments in the correct format",
                    "Use --help flag to see argument documentation",
                    "Check the script registry for argument specifications"
                ])
            elif 'Invalid type' in message:
                suggestions.extend([
                    "Verify the data type matches the expected format",
                    "For arrays, use JSON format: '["item1", "item2"]'",
                    "For objects, use JSON format: '{"key": "value"}'",
                    "For booleans, use: true/false (lowercase)"
                ])
            else:
                suggestions.extend([
                    "Check the argument types and formats",
                    "Verify required arguments are provided",
                    "Review the script's argument definitions in registry.json"
                ])
        
        elif category == ErrorCategory.DEPENDENCY:
            context['missing_file'] = script.get('path') if script else None
            suggestions.extend([
                "Verify the script file exists at the specified path",
                "Check if all required dependencies are installed:",
                "  - For Python: pip install -r requirements.txt",
                "  - For Node.js: npm install",
                "Verify the interpreter version matches requirements",
                "Check file system permissions for the script directory",
                "Run 'validate-specialist.py' to check all dependencies"
            ])
        
        elif category == ErrorCategory.PERMISSION:
            context['required_permissions'] = script.get('execution', {}).get('permissions', []) if script else []
            context['sandbox_level'] = script.get('security', {}).get('sandbox', 'standard') if script else None
            suggestions.extend([
                "Check file permissions with: ls -la <file>",
                "Make script executable with: chmod +x <script>",
                "Verify sandbox settings allow required operations",
                "Review the script's permission requirements in registry.json",
                "Consider adjusting sandbox level if too restrictive",
                "Check parent directory permissions"
            ])
        
        elif category == ErrorCategory.RESOURCE:
            context['memory_limit'] = script.get('security', {}).get('max_memory', '512MB') if script else None
            suggestions.extend([
                "Increase memory limits in the script configuration",
                "Optimize script memory usage by:",
                "  - Processing data in chunks",
                "  - Releasing unused objects explicitly",
                "  - Using generators instead of lists for large datasets",
                "Check for memory leaks using memory profilers",
                "Monitor system resources during execution",
                "Consider using external storage for large datasets"
            ])
        
        elif category == ErrorCategory.EXECUTION:
            if 'exit code' in message:
                suggestions.extend([
                    "Check script error output for specific error details",
                    "Verify all input data is in the expected format",
                    "Check script logs for more information",
                    "Run the script manually to debug the issue",
                    "Ensure all environment variables are properly set"
                ])
        
        elif category == ErrorCategory.UNKNOWN:
            suggestions.extend([
                "Check system logs for more details",
                "Verify the execution environment is properly configured",
                "Try running the script with minimal arguments",
                "Check for system-level issues (disk space, permissions)",
                "Report this error to the MetaClaude team with full context"
            ])
        
        # Capture exception details
        stack_trace = None
        raw_error = None
        if exception:
            stack_trace = traceback.format_exc()
            raw_error = str(exception)
            context['exception_type'] = type(exception).__name__
            context['exception_args'] = str(exception.args)
            
            # Add specific context based on exception type
            if isinstance(exception, subprocess.TimeoutExpired):
                context['command'] = exception.cmd
                context['timeout_seconds'] = exception.timeout
            elif isinstance(exception, MemoryError):
                context['error_type'] = 'memory_exhausted'
            elif isinstance(exception, OSError):
                context['errno'] = exception.errno
                context['strerror'] = exception.strerror
        
        # Create retry info
        retry_info = None
        if self._should_retry(category):
            retry_info = RetryInfo(
                is_retryable=True,
                attempts_made=retry_count,
                max_attempts=self.max_retries,
                next_retry_delay=self.base_retry_delay * (2 ** retry_count) if retry_count < self.max_retries else None,
                retry_reason=self._get_retry_reason(category)
            )
        else:
            retry_info = RetryInfo(
                is_retryable=False,
                attempts_made=retry_count,
                max_attempts=self.max_retries,
                retry_reason="Error category is not retryable"
            )
        
        return ErrorDetails(
            category=category,
            message=message,
            context=context,
            suggestions=suggestions,
            stack_trace=stack_trace,
            raw_error=raw_error,
            retry_info=retry_info
        )
    
    def _should_retry(self, error_category: ErrorCategory) -> bool:
        """Determine if error category is retryable"""
        retryable_categories = {
            ErrorCategory.TIMEOUT,
            ErrorCategory.RESOURCE,
            ErrorCategory.UNKNOWN
        }
        return error_category in retryable_categories
    
    def _get_retry_reason(self, error_category: ErrorCategory) -> str:
        """Get human-readable retry reason"""
        reasons = {
            ErrorCategory.TIMEOUT: "Temporary performance issue or system load",
            ErrorCategory.RESOURCE: "Temporary resource constraint",
            ErrorCategory.UNKNOWN: "Transient error that may resolve on retry",
            ErrorCategory.VALIDATION: "Input validation errors require user correction",
            ErrorCategory.DEPENDENCY: "Missing dependencies must be installed",
            ErrorCategory.PERMISSION: "Permission issues require manual intervention",
            ErrorCategory.EXECUTION: "Script logic errors need debugging"
        }
        return reasons.get(error_category, "Unknown error category")
    
    def register_progress_callback(self, execution_id: str, callback: Callable):
        """Register a progress callback for execution"""
        self.progress_callbacks[execution_id] = callback
    
    def unregister_progress_callback(self, execution_id: str):
        """Unregister a progress callback"""
        self.progress_callbacks.pop(execution_id, None)
    
    async def execute_async(self, script_id: str, arguments: Dict[str, Any],
                           priority: JobPriority = JobPriority.NORMAL,
                           progress_callback: Optional[Callable] = None) -> str:
        """Execute script asynchronously via job queue"""
        if not self.job_queue:
            raise RuntimeError("Async queue not initialized. Call init_async_queue() first.")
        
        # Submit job to queue
        job_id = self.job_queue.submit_job(
            script_id=script_id,
            arguments=arguments,
            priority=priority,
            callback=progress_callback
        )
        
        return job_id
    
    def execute(self, script_id: str, arguments: Dict[str, Any],
                execution_id: Optional[str] = None) -> ExecutionResult:
        """Execute a registered script with given arguments with retry logic"""
        start_time = time.time()
        # Track execution
        execution_id = execution_id or str(time.time())
        
        # Get script metadata first (with caching)
        script = self.get_script(script_id)
        if not script:
            return ExecutionResult(
                success=False,
                exit_code=-1,
                stdout="",
                stderr="",
                outputs={},
                execution_time=0,
                error=f"Script not found: {script_id}",
                error_details=self._create_error_details(
                    ErrorCategory.VALIDATION,
                    f"Script not found: {script_id}",
                    retry_count=0
                ),
                start_timestamp=datetime.datetime.now(),
                end_timestamp=datetime.datetime.now()
            )
        
        # Update execution stats
        self._update_execution_stats(script_id, start_time, False)
        
        # Execute with retry logic
        retry_count = 0
        last_result = None
        
        while retry_count <= self.max_retries:
            result = self._execute_once(script, arguments, retry_count, execution_id)
            last_result = result
            
            # Success or non-retryable error
            if result.success or not result.error_details:
                # Update stats
                self._update_execution_stats(
                    script_id,
                    start_time,
                    result.success,
                    result.execution_time
                )
                return result
            
            # Check if we should retry
            if not self._should_retry(result.error_details.category):
                # Log non-retryable error
                print(f"[RETRY_SKIPPED] Error category '{result.error_details.category.value}' is not retryable", 
                      file=sys.stderr)
                return result
            
            # Check if we've exhausted retries
            if retry_count >= self.max_retries:
                print(f"[RETRY_EXHAUSTED] Maximum retry attempts ({self.max_retries}) reached", 
                      file=sys.stderr)
                return result
            
            # Calculate backoff delay with jitter
            base_delay = self.base_retry_delay * (2 ** retry_count)
            jitter = base_delay * 0.1 * (0.5 - time.time() % 1)  # Add 10% jitter
            delay = base_delay + jitter
            
            # Log retry attempt
            retry_context = {
                'timestamp': datetime.datetime.now().isoformat(),
                'event': 'retry_attempt',
                'script_id': script.get('id', 'unknown'),
                'error_category': result.error_details.category.value,
                'retry_attempt': retry_count + 1,
                'max_retries': self.max_retries,
                'delay_seconds': round(delay, 2),
                'retry_reason': result.error_details.retry_info.retry_reason if result.error_details.retry_info else 'Unknown'
            }
            
            print(f"[RETRY_ATTEMPT] {json.dumps(retry_context)}", file=sys.stderr)
            time.sleep(delay)
            retry_count += 1
        
        return last_result
    
    def _execute_once(self, script: Dict[str, Any], arguments: Dict[str, Any], 
                     retry_count: int, execution_id: Optional[str] = None) -> ExecutionResult:
        """Execute a script once (no retry logic)"""
        start_time = time.time()
        start_timestamp = datetime.datetime.now()
        start_memory = self._get_current_memory_usage()
        start_cpu = self._get_cpu_times()
        
        # Validate arguments
        valid, error = self.validate_arguments(script, arguments)
        if not valid:
            return ExecutionResult(
                success=False,
                exit_code=-1,
                stdout="",
                stderr="",
                outputs={},
                execution_time=0,
                error=error,
                error_details=self._create_error_details(
                    ErrorCategory.VALIDATION,
                    error,
                    script,
                    retry_count=retry_count
                ),
                start_timestamp=start_timestamp,
                end_timestamp=datetime.datetime.now(),
                retry_count=retry_count
            )
        
        # Build command
        script_path = self.scripts_dir / script['path']
        if not script_path.exists():
            error_msg = f"Script file not found: {script_path}"
            return ExecutionResult(
                success=False,
                exit_code=-1,
                stdout="",
                stderr="",
                outputs={},
                execution_time=0,
                error=error_msg,
                error_details=self._create_error_details(
                    ErrorCategory.DEPENDENCY,
                    error_msg,
                    script,
                    retry_count=retry_count
                ),
                start_timestamp=start_timestamp,
                end_timestamp=datetime.datetime.now(),
                retry_count=retry_count
            )
        
        # Check file permissions
        if not os.access(script_path, os.X_OK):
            error_msg = f"Script is not executable: {script_path}"
            return ExecutionResult(
                success=False,
                exit_code=-1,
                stdout="",
                stderr="",
                outputs={},
                execution_time=0,
                error=error_msg,
                error_details=self._create_error_details(
                    ErrorCategory.PERMISSION,
                    error_msg,
                    script,
                    retry_count=retry_count
                ),
                start_timestamp=start_timestamp,
                end_timestamp=datetime.datetime.now(),
                retry_count=retry_count
            )
        
        # Prepare command with arguments
        execution = script.get('execution', {})
        interpreter = execution.get('interpreter', '/bin/bash')
        cmd = [interpreter, str(script_path)]
        
        # Add arguments in order
        for arg_def in execution.get('args', []):
            arg_name = arg_def['name']
            if arg_name in arguments:
                value = arguments[arg_name]
                # Convert boolean to string
                if isinstance(value, bool):
                    value = 'true' if value else 'false'
                cmd.append(str(value))
            elif arg_def.get('default') is not None:
                cmd.append(str(arg_def['default']))
        
        # Apply sandbox
        env = self._apply_sandbox(
            script.get('security', {}).get('sandbox', 'standard'),
            execution.get('permissions', [])
        )
        
        # Set resource limits
        timeout_ms = execution.get('timeout', 30000)
        max_memory = script.get('security', {}).get('max_memory', '512MB')
        preexec_fn = self._set_resource_limits(max_memory, timeout_ms)
        
        # Track peak memory during execution
        peak_memory = start_memory
        
        # Execute script
        try:
            # Enhanced execution lifecycle logging
            script_id = script.get('id', 'unknown')
            specialist = script.get('specialist', 'unknown')
            
            # Log execution start with comprehensive context
            log_context = {
                'timestamp': start_timestamp.isoformat(),
                'event': 'execution_start',
                'script_id': script_id,
                'specialist': specialist,
                'command': ' '.join(cmd),
                'arguments': arguments,
                'timeout_ms': timeout_ms,
                'memory_limit': max_memory,
                'sandbox_level': script.get('security', {}).get('sandbox', 'standard'),
                'retry_attempt': retry_count + 1,
                'max_retries': self.max_retries
            }
            
            print(f"[EXECUTION_START] {json.dumps(log_context)}", file=sys.stderr)
            
            # Run the subprocess
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=env,
                preexec_fn=preexec_fn,
                cwd=self.scripts_dir
            )
            
            # Monitor process with timeout and progress
            timeout_seconds = timeout_ms / 1000
            start_monitor = time.time()
            stdout_data = ""
            stderr_data = ""
            progress_reported = False
            
            while True:
                # Check if process is done
                poll_result = process.poll()
                if poll_result is not None:
                    # Process finished
                    stdout_data, stderr_data = process.communicate()
                    break
                
                # Check timeout
                if time.time() - start_monitor > timeout_seconds:
                    process.kill()
                    process.wait()
                    raise subprocess.TimeoutExpired(cmd, timeout_seconds)
                
                # Track peak memory and report progress
                try:
                    proc_info = psutil.Process(process.pid)
                    proc_memory = proc_info.memory_info().rss / (1024 * 1024)
                    peak_memory = max(peak_memory, proc_memory)
                    
                    # Report progress periodically
                    if execution_id and execution_id in self.progress_callbacks:
                        elapsed = time.time() - start_monitor
                        if not progress_reported or int(elapsed) % 5 == 0:
                            progress = min(90, int(elapsed / timeout_seconds * 100))
                            self._report_progress(
                                execution_id,
                                progress,
                                f"Executing {script.get('name', script_id)}..."
                            )
                            progress_reported = True
                            
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
                
                time.sleep(0.1)  # Small delay to avoid busy waiting
            
            # Calculate resource usage
            end_time = time.time()
            end_timestamp = datetime.datetime.now()
            end_memory = self._get_current_memory_usage()
            end_cpu = self._get_cpu_times()
            
            execution_time = end_time - start_time
            
            resource_usage = ResourceUsage(
                start_memory_mb=start_memory,
                end_memory_mb=end_memory,
                peak_memory_mb=peak_memory,
                cpu_time_seconds=end_cpu - start_cpu,
                wall_time_seconds=execution_time
            )
            
            # Parse outputs if available
            outputs = self._parse_outputs(stdout_data, script.get('outputs', []))
            
            # Check for non-zero exit code
            if process.returncode != 0:
                error_msg = f"Script exited with code {process.returncode}"
                return ExecutionResult(
                    success=False,
                    exit_code=process.returncode,
                    stdout=stdout_data,
                    stderr=stderr_data,
                    outputs=outputs,
                    execution_time=execution_time,
                    error=error_msg,
                    error_details=self._create_error_details(
                        ErrorCategory.EXECUTION,
                        error_msg,
                        script,
                        retry_count=retry_count
                    ),
                    resource_usage=resource_usage,
                    start_timestamp=start_timestamp,
                    end_timestamp=end_timestamp,
                    retry_count=retry_count
                )
            
            # Log successful completion
            log_context = {
                'timestamp': end_timestamp.isoformat(),
                'event': 'execution_complete',
                'script_id': script_id,
                'specialist': specialist,
                'success': True,
                'exit_code': process.returncode,
                'execution_time_seconds': execution_time,
                'memory_delta_mb': end_memory - start_memory,
                'peak_memory_mb': peak_memory,
                'cpu_time_seconds': resource_usage.cpu_time_seconds,
                'retry_attempt': retry_count + 1,
                'outputs_count': len(outputs)
            }
            
            print(f"[EXECUTION_COMPLETE] {json.dumps(log_context)}", file=sys.stderr)
            
            # Success
            return ExecutionResult(
                success=True,
                exit_code=process.returncode,
                stdout=stdout_data,
                stderr=stderr_data,
                outputs=outputs,
                execution_time=execution_time,
                resource_usage=resource_usage,
                start_timestamp=start_timestamp,
                end_timestamp=end_timestamp,
                retry_count=retry_count
            )
            
        except subprocess.TimeoutExpired as e:
            end_timestamp = datetime.datetime.now()
            error_msg = f"Script execution timed out after {timeout_ms}ms"
            return ExecutionResult(
                success=False,
                exit_code=-1,
                stdout="",
                stderr="",
                outputs={},
                execution_time=timeout_ms / 1000,
                error=error_msg,
                error_details=self._create_error_details(
                    ErrorCategory.TIMEOUT,
                    error_msg,
                    script,
                    e,
                    retry_count=retry_count
                ),
                resource_usage=ResourceUsage(
                    start_memory_mb=start_memory,
                    end_memory_mb=self._get_current_memory_usage(),
                    peak_memory_mb=peak_memory,
                    cpu_time_seconds=self._get_cpu_times() - start_cpu,
                    wall_time_seconds=timeout_ms / 1000
                ),
                start_timestamp=start_timestamp,
                end_timestamp=end_timestamp,
                retry_count=retry_count
            )
            
        except MemoryError as e:
            end_timestamp = datetime.datetime.now()
            error_msg = f"Script exceeded memory limit of {max_memory}"
            
            # Log memory error
            log_context = {
                'timestamp': end_timestamp.isoformat(),
                'event': 'execution_failed',
                'script_id': script_id,
                'specialist': specialist,
                'error_category': 'resource',
                'error_type': 'memory_exceeded',
                'memory_limit': max_memory,
                'peak_memory_mb': peak_memory,
                'retry_attempt': retry_count + 1
            }
            
            print(f"[EXECUTION_FAILED] {json.dumps(log_context)}", file=sys.stderr)
            
            return ExecutionResult(
                success=False,
                exit_code=-1,
                stdout="",
                stderr="",
                outputs={},
                execution_time=time.time() - start_time,
                error=error_msg,
                error_details=self._create_error_details(
                    ErrorCategory.RESOURCE,
                    error_msg,
                    script,
                    e,
                    retry_count=retry_count
                ),
                start_timestamp=start_timestamp,
                end_timestamp=end_timestamp,
                retry_count=retry_count
            )
            
        except Exception as e:
            end_timestamp = datetime.datetime.now()
            error_msg = f"Unexpected execution error: {str(e)}"
            
            # Determine specific error category based on exception type
            error_category = ErrorCategory.UNKNOWN
            if isinstance(e, (FileNotFoundError, ImportError, ModuleNotFoundError)):
                error_category = ErrorCategory.DEPENDENCY
                error_msg = f"Dependency error: {str(e)}"
            elif isinstance(e, (PermissionError, OSError)) and hasattr(e, 'errno') and e.errno == 13:
                error_category = ErrorCategory.PERMISSION
                error_msg = f"Permission denied: {str(e)}"
            elif isinstance(e, (ValueError, TypeError, KeyError)):
                error_category = ErrorCategory.VALIDATION
                error_msg = f"Validation error: {str(e)}"
            
            # Log unexpected error
            log_context = {
                'timestamp': end_timestamp.isoformat(),
                'event': 'execution_failed',
                'script_id': script_id,
                'specialist': specialist,
                'error_category': error_category.value,
                'error_type': type(e).__name__,
                'error_message': str(e),
                'retry_attempt': retry_count + 1
            }
            
            print(f"[EXECUTION_FAILED] {json.dumps(log_context)}", file=sys.stderr)
            
            return ExecutionResult(
                success=False,
                exit_code=-1,
                stdout="",
                stderr="",
                outputs={},
                execution_time=time.time() - start_time,
                error=error_msg,
                error_details=self._create_error_details(
                    error_category,
                    error_msg,
                    script,
                    e,
                    retry_count=retry_count
                ),
                start_timestamp=start_timestamp,
                end_timestamp=end_timestamp,
                retry_count=retry_count
            )
    
    def _parse_outputs(self, stdout: str, output_definitions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Parse script outputs based on definitions"""
        outputs = {}
        
        # Try to parse as JSON first
        try:
            json_output = json.loads(stdout.strip())
            if isinstance(json_output, dict):
                # Map to defined outputs
                for output_def in output_definitions:
                    name = output_def['name']
                    if name in json_output:
                        outputs[name] = json_output[name]
                return outputs
        except json.JSONDecodeError:
            pass
        
        # Fallback: parse key-value pairs
        for line in stdout.strip().split('\n'):
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()
                
                # Try to convert to appropriate type
                for output_def in output_definitions:
                    if output_def['name'] == key:
                        outputs[key] = self._convert_value(value, output_def['type'])
                        break
        
        return outputs
    
    def _convert_value(self, value: str, target_type: str) -> Any:
        """Convert string value to target type"""
        if target_type == 'boolean':
            return value.lower() in ('true', '1', 'yes')
        elif target_type == 'number':
            try:
                return int(value)
            except ValueError:
                try:
                    return float(value)
                except ValueError:
                    return value
        elif target_type == 'array':
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value.split(',')
        elif target_type == 'object':
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return {'value': value}
        else:
            return value
    
    def _report_progress(self, execution_id: str, percentage: int, message: str):
        """Report execution progress"""
        if execution_id in self.progress_callbacks:
            try:
                callback = self.progress_callbacks[execution_id]
                callback(execution_id, percentage, message)
            except Exception as e:
                logging.error(f"Progress callback error: {e}")
    
    def _update_execution_stats(self, script_id: str, start_time: float,
                               success: bool, execution_time: Optional[float] = None):
        """Update execution statistics"""
        stats = self.execution_stats[script_id]
        stats['total_executions'] += 1
        
        if not success:
            stats['total_failures'] += 1
        
        if execution_time:
            # Calculate rolling average
            prev_avg = stats['avg_execution_time']
            total = stats['total_executions']
            stats['avg_execution_time'] = (prev_avg * (total - 1) + execution_time) / total
        
        stats['last_execution'] = datetime.datetime.now().isoformat()
    
    def get_execution_stats(self, script_id: Optional[str] = None) -> Dict[str, Any]:
        """Get execution statistics"""
        if script_id:
            return dict(self.execution_stats.get(script_id, {}))
        return dict(self.execution_stats)
    
    def get_cache_stats(self) -> Optional[Dict[str, Any]]:
        """Get cache statistics"""
        if self.cache:
            return self.cache.get_stats()
        return None
    
    def get_connection_pool_stats(self) -> Dict[str, Any]:
        """Get connection pool statistics"""
        stats = {
            'http_session_active': 'http' in self.connection_pool.sessions,
            'postgres_pool_active': 'postgres' in self.connection_pool.pools,
            'mongodb_pool_active': 'mongodb' in self.connection_pool.pools
        }
        return stats
    
    def close(self):
        """Clean up resources"""
        # Close cache
        if self.cache:
            self.cache.close()
        
        # Close connection pools
        self.connection_pool.close_all()
        
        # Shutdown executor
        self.executor.shutdown(wait=True)


def main():
    """Command-line interface for TES"""
    parser = argparse.ArgumentParser(description='Execute registered MetaClaude scripts')
    parser.add_argument('script_id', help='Script ID from the registry')
    parser.add_argument('--registry', default=None, help='Path to registry.json')
    parser.add_argument('--arg', action='append', help='Script arguments in key=value format')
    parser.add_argument('--json', action='store_true', help='Output result as JSON')
    parser.add_argument('--async', action='store_true', help='Execute asynchronously')
    parser.add_argument('--priority', choices=['high', 'normal', 'low'], default='normal',
                       help='Job priority for async execution')
    parser.add_argument('--no-cache', action='store_true', help='Disable registry caching')
    parser.add_argument('--redis', help='Redis URL for distributed caching')
    parser.add_argument('--stats', action='store_true', help='Show execution statistics')
    
    args = parser.parse_args()
    
    # Find registry
    if args.registry:
        registry_path = args.registry
    else:
        # Default location
        script_dir = Path(__file__).parent.parent
        registry_path = script_dir / 'registry.json'
    
    # Parse arguments
    script_args = {}
    if args.arg:
        for arg in args.arg:
            if '=' in arg:
                key, value = arg.split('=', 1)
                # Try to parse as JSON for complex types
                try:
                    script_args[key] = json.loads(value)
                except json.JSONDecodeError:
                    script_args[key] = value
    
    # Initialize service
    tes = ToolExecutionService(
        registry_path,
        enable_cache=not args.no_cache,
        redis_url=args.redis
    )
    
    # Show stats if requested
    if args.stats:
        print("Execution Statistics:")
        stats = tes.get_execution_stats(args.script_id)
        print(json.dumps(stats, indent=2))
        
        if not args.no_cache:
            print("\nCache Statistics:")
            cache_stats = tes.get_cache_stats()
            if cache_stats:
                print(json.dumps(cache_stats, indent=2))
        
        sys.exit(0)
    
    # Execute
    if args.async:
        # Async execution
        import asyncio
        
        async def run_async():
            await tes.init_async_queue()
            
            # Map priority
            priority_map = {
                'high': JobPriority.HIGH,
                'normal': JobPriority.NORMAL,
                'low': JobPriority.LOW
            }
            
            job_id = await tes.execute_async(
                args.script_id,
                script_args,
                priority=priority_map[args.priority]
            )
            
            print(f"Job submitted: {job_id}")
            print("Use job queue API to monitor progress")
            
            # Cleanup
            if tes.job_queue:
                await tes.job_queue.stop()
        
        asyncio.run(run_async())
    else:
        # Sync execution
        result = tes.execute(args.script_id, script_args)
    
    # Output result
    if args.json:
        output = {
            'success': result.success,
            'exit_code': result.exit_code,
            'outputs': result.outputs,
            'execution_time': result.execution_time,
            'error': result.error,
            'retry_count': result.retry_count
        }
        
        # Add timestamps
        if result.start_timestamp:
            output['start_timestamp'] = result.start_timestamp.isoformat()
        if result.end_timestamp:
            output['end_timestamp'] = result.end_timestamp.isoformat()
        
        # Add comprehensive error details
        if result.error_details:
            output['error_details'] = {
                'category': result.error_details.category.value,
                'message': result.error_details.message,
                'context': result.error_details.context,
                'raw_error': result.error_details.raw_error,
                'suggestions': result.error_details.suggestions
            }
            
            # Add retry info
            if result.error_details.retry_info:
                output['error_details']['retry_info'] = {
                    'is_retryable': result.error_details.retry_info.is_retryable,
                    'attempts_made': result.error_details.retry_info.attempts_made,
                    'max_attempts': result.error_details.retry_info.max_attempts,
                    'next_retry_delay': result.error_details.retry_info.next_retry_delay,
                    'retry_reason': result.error_details.retry_info.retry_reason
                }
            
            if result.error_details.stack_trace:
                output['error_details']['stack_trace'] = result.error_details.stack_trace
        
        # Add resource usage
        if result.resource_usage:
            output['resource_usage'] = {
                'start_memory_mb': result.resource_usage.start_memory_mb,
                'end_memory_mb': result.resource_usage.end_memory_mb,
                'peak_memory_mb': result.resource_usage.peak_memory_mb,
                'cpu_time_seconds': result.resource_usage.cpu_time_seconds,
                'wall_time_seconds': result.resource_usage.wall_time_seconds
            }
        
        print(json.dumps(output, indent=2))
    else:
        if result.success:
            print(result.stdout, end='')
            if result.outputs:
                print("\nOutputs:")
                for key, value in result.outputs.items():
                    print(f"  {key}: {value}")
        else:
            print(f"Error: {result.error or 'Script failed'}", file=sys.stderr)
            if result.stderr:
                print(f"Script error output:\n{result.stderr}", file=sys.stderr)
            
            # Print comprehensive error details and suggestions
            if result.error_details:
                print(f"\nError Category: {result.error_details.category.value}", file=sys.stderr)
                
                if result.error_details.raw_error:
                    print(f"Raw Error: {result.error_details.raw_error}", file=sys.stderr)
                
                if result.error_details.context:
                    print("\nError Context:", file=sys.stderr)
                    for key, value in result.error_details.context.items():
                        print(f"  {key}: {value}", file=sys.stderr)
                
                if result.error_details.retry_info:
                    print("\nRetry Information:", file=sys.stderr)
                    print(f"  Retryable: {result.error_details.retry_info.is_retryable}", file=sys.stderr)
                    print(f"  Attempts: {result.error_details.retry_info.attempts_made}/{result.error_details.retry_info.max_attempts}", file=sys.stderr)
                    if result.error_details.retry_info.retry_reason:
                        print(f"  Reason: {result.error_details.retry_info.retry_reason}", file=sys.stderr)
                
                if result.error_details.suggestions:
                    print("\nSuggestions for resolution:", file=sys.stderr)
                    for i, suggestion in enumerate(result.error_details.suggestions, 1):
                        print(f"  {i}. {suggestion}", file=sys.stderr)
            
            sys.exit(result.exit_code)
    
    # Cleanup
    tes.close()


if __name__ == '__main__':
    main()