#!/usr/bin/env python3
"""
MetaClaude Execution Logger
Logs all script executions with structured data for analysis and debugging
"""

import json
import os
import sys
import logging
import datetime
import gzip
import shutil
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from enum import Enum
import threading
from queue import Queue
import time


class LogLevel(Enum):
    """Log levels for execution events"""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARN = "WARN"
    ERROR = "ERROR"


@dataclass
class ExecutionLogEntry:
    """Structured log entry for script execution"""
    timestamp: str
    level: LogLevel
    script_id: str
    specialist: str
    user: str
    inputs: Dict[str, Any]
    outputs: Dict[str, Any]
    duration_seconds: float
    success: bool
    exit_code: int
    error_category: Optional[str] = None
    error_message: Optional[str] = None
    error_details: Optional[Dict[str, Any]] = None
    resource_usage: Optional[Dict[str, Any]] = None
    retry_count: int = 0
    session_id: Optional[str] = None
    correlation_id: Optional[str] = None
    
    def to_json(self) -> str:
        """Convert to JSON string"""
        data = asdict(self)
        data['level'] = self.level.value
        return json.dumps(data)


class ExecutionLogger:
    """Handles logging of all script executions"""
    
    def __init__(self, log_dir: str = None, 
                 rotation_size_mb: int = 100,
                 retention_days: int = 30,
                 async_logging: bool = True):
        """
        Initialize the execution logger
        
        Args:
            log_dir: Directory to store logs (default: .claude/logs/executions)
            rotation_size_mb: Max size before rotation (default: 100MB)
            retention_days: Days to keep old logs (default: 30)
            async_logging: Use async logging for performance (default: True)
        """
        if log_dir is None:
            # Default to .claude/logs/executions in project root
            script_dir = Path(__file__).parent.parent.parent
            log_dir = script_dir / 'logs' / 'executions'
        
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        self.rotation_size_bytes = rotation_size_mb * 1024 * 1024
        self.retention_days = retention_days
        self.async_logging = async_logging
        
        # Current log file
        self.current_log_file = self._get_current_log_file()
        
        # Async logging queue and thread
        if self.async_logging:
            self.log_queue = Queue()
            self.writer_thread = threading.Thread(target=self._log_writer_thread, daemon=True)
            self.writer_thread.start()
        
        # Initialize Python logger for internal errors
        self.logger = logging.getLogger('ExecutionLogger')
        handler = logging.FileHandler(self.log_dir / 'logger-errors.log')
        handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.ERROR)
    
    def _get_current_log_file(self) -> Path:
        """Get the current log file path"""
        date_str = datetime.datetime.now().strftime('%Y-%m-%d')
        return self.log_dir / f'executions-{date_str}.jsonl'
    
    def _rotate_if_needed(self):
        """Check if log rotation is needed and perform it"""
        if not self.current_log_file.exists():
            return
        
        file_size = self.current_log_file.stat().st_size
        if file_size >= self.rotation_size_bytes:
            # Rotate the file
            timestamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
            rotated_name = f"{self.current_log_file.stem}-{timestamp}.jsonl"
            rotated_path = self.log_dir / rotated_name
            
            # Move current file
            shutil.move(str(self.current_log_file), str(rotated_path))
            
            # Compress the rotated file
            self._compress_file(rotated_path)
    
    def _compress_file(self, file_path: Path):
        """Compress a log file with gzip"""
        gz_path = file_path.with_suffix('.jsonl.gz')
        
        try:
            with open(file_path, 'rb') as f_in:
                with gzip.open(gz_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            
            # Remove original file after successful compression
            file_path.unlink()
        except Exception as e:
            self.logger.error(f"Failed to compress {file_path}: {e}")
    
    def _cleanup_old_logs(self):
        """Remove logs older than retention period"""
        cutoff_date = datetime.datetime.now() - datetime.timedelta(days=self.retention_days)
        
        for log_file in self.log_dir.glob('executions-*.jsonl*'):
            # Extract date from filename
            try:
                date_str = log_file.stem.split('-')[1]
                file_date = datetime.datetime.strptime(date_str, '%Y%m%d')
                
                if file_date < cutoff_date:
                    log_file.unlink()
            except (ValueError, IndexError):
                # Skip files that don't match expected pattern
                continue
    
    def _log_writer_thread(self):
        """Background thread for async logging"""
        while True:
            try:
                # Get log entry from queue (block with timeout)
                entry = self.log_queue.get(timeout=1)
                
                if entry is None:  # Shutdown signal
                    break
                
                self._write_log_entry(entry)
                
            except Exception:
                # Queue timeout, continue
                continue
    
    def _write_log_entry(self, entry: ExecutionLogEntry):
        """Write a log entry to file"""
        try:
            # Check if we need to switch to a new day's log
            new_log_file = self._get_current_log_file()
            if new_log_file != self.current_log_file:
                self.current_log_file = new_log_file
                self._cleanup_old_logs()
            
            # Check if rotation is needed
            self._rotate_if_needed()
            
            # Append entry to log file
            with open(self.current_log_file, 'a') as f:
                f.write(entry.to_json() + '\n')
                
        except Exception as e:
            self.logger.error(f"Failed to write log entry: {e}")
    
    def log(self, entry: ExecutionLogEntry):
        """Log an execution entry"""
        if self.async_logging:
            self.log_queue.put(entry)
        else:
            self._write_log_entry(entry)
    
    def log_execution(self,
                     script_id: str,
                     specialist: str,
                     inputs: Dict[str, Any],
                     result: Any,  # ExecutionResult from TES
                     user: str = None,
                     session_id: str = None,
                     correlation_id: str = None):
        """
        Log a script execution from TES result
        
        Args:
            script_id: ID of the executed script
            specialist: Specialist that owns the script
            inputs: Input arguments to the script
            result: ExecutionResult from TES
            user: User who executed the script
            session_id: Session identifier
            correlation_id: Correlation ID for tracking related executions
        """
        # Determine log level based on result
        if result.success:
            level = LogLevel.INFO
        elif result.error_details and result.error_details.category == 'timeout':
            level = LogLevel.WARN
        else:
            level = LogLevel.ERROR
        
        # Extract resource usage
        resource_usage = None
        if result.resource_usage:
            resource_usage = {
                'start_memory_mb': result.resource_usage.start_memory_mb,
                'end_memory_mb': result.resource_usage.end_memory_mb,
                'peak_memory_mb': result.resource_usage.peak_memory_mb,
                'cpu_time_seconds': result.resource_usage.cpu_time_seconds,
                'wall_time_seconds': result.resource_usage.wall_time_seconds
            }
        
        # Extract error details
        error_details = None
        error_category = None
        if result.error_details:
            error_category = result.error_details.category.value
            error_details = {
                'context': result.error_details.context,
                'suggestions': result.error_details.suggestions
            }
        
        # Create log entry
        entry = ExecutionLogEntry(
            timestamp=result.start_timestamp.isoformat() if result.start_timestamp else datetime.datetime.now().isoformat(),
            level=level,
            script_id=script_id,
            specialist=specialist,
            user=user or os.getenv('USER', 'unknown'),
            inputs=inputs,
            outputs=result.outputs,
            duration_seconds=result.execution_time,
            success=result.success,
            exit_code=result.exit_code,
            error_category=error_category,
            error_message=result.error,
            error_details=error_details,
            resource_usage=resource_usage,
            retry_count=result.retry_count,
            session_id=session_id,
            correlation_id=correlation_id
        )
        
        self.log(entry)
    
    def query(self,
             start_date: datetime.datetime = None,
             end_date: datetime.datetime = None,
             script_id: str = None,
             specialist: str = None,
             user: str = None,
             success: Optional[bool] = None,
             level: Optional[LogLevel] = None,
             limit: int = 1000) -> List[ExecutionLogEntry]:
        """
        Query execution logs with filters
        
        Args:
            start_date: Start date for query (default: today)
            end_date: End date for query (default: now)
            script_id: Filter by script ID
            specialist: Filter by specialist
            user: Filter by user
            success: Filter by success status
            level: Filter by log level
            limit: Maximum number of results
        
        Returns:
            List of matching log entries
        """
        if start_date is None:
            start_date = datetime.datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        if end_date is None:
            end_date = datetime.datetime.now()
        
        results = []
        
        # Iterate through log files in date range
        current_date = start_date.date()
        while current_date <= end_date.date():
            log_file = self.log_dir / f'executions-{current_date}.jsonl'
            
            if log_file.exists():
                results.extend(self._query_file(
                    log_file, script_id, specialist, user, success, level, limit - len(results)
                ))
            
            # Also check compressed files
            for gz_file in self.log_dir.glob(f'executions-{current_date}-*.jsonl.gz'):
                results.extend(self._query_compressed_file(
                    gz_file, script_id, specialist, user, success, level, limit - len(results)
                ))
            
            if len(results) >= limit:
                break
            
            current_date += datetime.timedelta(days=1)
        
        return results[:limit]
    
    def _query_file(self, file_path: Path, script_id: str, specialist: str,
                   user: str, success: Optional[bool], level: Optional[LogLevel],
                   limit: int) -> List[ExecutionLogEntry]:
        """Query a single log file"""
        results = []
        
        try:
            with open(file_path, 'r') as f:
                for line in f:
                    if len(results) >= limit:
                        break
                    
                    try:
                        data = json.loads(line.strip())
                        
                        # Apply filters
                        if script_id and data.get('script_id') != script_id:
                            continue
                        if specialist and data.get('specialist') != specialist:
                            continue
                        if user and data.get('user') != user:
                            continue
                        if success is not None and data.get('success') != success:
                            continue
                        if level and data.get('level') != level.value:
                            continue
                        
                        # Convert to ExecutionLogEntry
                        data['level'] = LogLevel(data['level'])
                        entry = ExecutionLogEntry(**data)
                        results.append(entry)
                        
                    except (json.JSONDecodeError, KeyError, ValueError):
                        # Skip malformed entries
                        continue
        
        except Exception as e:
            self.logger.error(f"Failed to query file {file_path}: {e}")
        
        return results
    
    def _query_compressed_file(self, file_path: Path, script_id: str, specialist: str,
                             user: str, success: Optional[bool], level: Optional[LogLevel],
                             limit: int) -> List[ExecutionLogEntry]:
        """Query a compressed log file"""
        results = []
        
        try:
            with gzip.open(file_path, 'rt') as f:
                for line in f:
                    if len(results) >= limit:
                        break
                    
                    try:
                        data = json.loads(line.strip())
                        
                        # Apply filters (same as _query_file)
                        if script_id and data.get('script_id') != script_id:
                            continue
                        if specialist and data.get('specialist') != specialist:
                            continue
                        if user and data.get('user') != user:
                            continue
                        if success is not None and data.get('success') != success:
                            continue
                        if level and data.get('level') != level.value:
                            continue
                        
                        # Convert to ExecutionLogEntry
                        data['level'] = LogLevel(data['level'])
                        entry = ExecutionLogEntry(**data)
                        results.append(entry)
                        
                    except (json.JSONDecodeError, KeyError, ValueError):
                        continue
        
        except Exception as e:
            self.logger.error(f"Failed to query compressed file {file_path}: {e}")
        
        return results
    
    def get_statistics(self,
                      start_date: datetime.datetime = None,
                      end_date: datetime.datetime = None,
                      group_by: str = 'script_id') -> Dict[str, Any]:
        """
        Get execution statistics
        
        Args:
            start_date: Start date for statistics
            end_date: End date for statistics  
            group_by: Group statistics by 'script_id', 'specialist', or 'user'
        
        Returns:
            Dictionary with statistics
        """
        entries = self.query(start_date=start_date, end_date=end_date, limit=10000)
        
        stats = {
            'total_executions': len(entries),
            'successful_executions': sum(1 for e in entries if e.success),
            'failed_executions': sum(1 for e in entries if not e.success),
            'total_duration_seconds': sum(e.duration_seconds for e in entries),
            'average_duration_seconds': sum(e.duration_seconds for e in entries) / len(entries) if entries else 0,
            'groups': {}
        }
        
        # Group statistics
        groups = {}
        for entry in entries:
            key = getattr(entry, group_by, 'unknown')
            if key not in groups:
                groups[key] = {
                    'count': 0,
                    'success_count': 0,
                    'total_duration': 0,
                    'errors': {}
                }
            
            groups[key]['count'] += 1
            if entry.success:
                groups[key]['success_count'] += 1
            else:
                error_cat = entry.error_category or 'unknown'
                groups[key]['errors'][error_cat] = groups[key]['errors'].get(error_cat, 0) + 1
            
            groups[key]['total_duration'] += entry.duration_seconds
        
        # Calculate success rates and averages
        for key, group in groups.items():
            group['success_rate'] = group['success_count'] / group['count'] if group['count'] > 0 else 0
            group['average_duration'] = group['total_duration'] / group['count'] if group['count'] > 0 else 0
        
        stats['groups'] = groups
        
        return stats
    
    def shutdown(self):
        """Shutdown the logger (for async mode)"""
        if self.async_logging:
            self.log_queue.put(None)  # Signal to stop
            self.writer_thread.join(timeout=5)


def main():
    """Command-line interface for querying logs"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Query MetaClaude execution logs')
    parser.add_argument('--start-date', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end-date', help='End date (YYYY-MM-DD)')
    parser.add_argument('--script-id', help='Filter by script ID')
    parser.add_argument('--specialist', help='Filter by specialist')
    parser.add_argument('--user', help='Filter by user')
    parser.add_argument('--success', action='store_true', help='Show only successful executions')
    parser.add_argument('--failed', action='store_true', help='Show only failed executions')
    parser.add_argument('--level', choices=['DEBUG', 'INFO', 'WARN', 'ERROR'], help='Filter by log level')
    parser.add_argument('--stats', action='store_true', help='Show statistics instead of logs')
    parser.add_argument('--group-by', choices=['script_id', 'specialist', 'user'], 
                       default='script_id', help='Group statistics by field')
    parser.add_argument('--limit', type=int, default=100, help='Maximum number of results')
    parser.add_argument('--json', action='store_true', help='Output as JSON')
    
    args = parser.parse_args()
    
    # Parse dates
    start_date = None
    end_date = None
    if args.start_date:
        start_date = datetime.datetime.strptime(args.start_date, '%Y-%m-%d')
    if args.end_date:
        end_date = datetime.datetime.strptime(args.end_date, '%Y-%m-%d').replace(
            hour=23, minute=59, second=59
        )
    
    # Create logger instance
    logger = ExecutionLogger()
    
    if args.stats:
        # Show statistics
        stats = logger.get_statistics(
            start_date=start_date,
            end_date=end_date,
            group_by=args.group_by
        )
        
        if args.json:
            print(json.dumps(stats, indent=2))
        else:
            print(f"Total Executions: {stats['total_executions']}")
            print(f"Successful: {stats['successful_executions']} ({stats['successful_executions']/stats['total_executions']*100:.1f}%)")
            print(f"Failed: {stats['failed_executions']} ({stats['failed_executions']/stats['total_executions']*100:.1f}%)")
            print(f"Average Duration: {stats['average_duration_seconds']:.2f}s")
            print(f"\nGrouped by {args.group_by}:")
            
            for key, group in stats['groups'].items():
                print(f"\n  {key}:")
                print(f"    Executions: {group['count']}")
                print(f"    Success Rate: {group['success_rate']*100:.1f}%")
                print(f"    Avg Duration: {group['average_duration']:.2f}s")
                if group['errors']:
                    print(f"    Errors: {dict(group['errors'])}")
    else:
        # Query logs
        success_filter = None
        if args.success:
            success_filter = True
        elif args.failed:
            success_filter = False
        
        level_filter = LogLevel(args.level) if args.level else None
        
        entries = logger.query(
            start_date=start_date,
            end_date=end_date,
            script_id=args.script_id,
            specialist=args.specialist,
            user=args.user,
            success=success_filter,
            level=level_filter,
            limit=args.limit
        )
        
        if args.json:
            # Output as JSON array
            print(json.dumps([asdict(e) for e in entries], indent=2))
        else:
            # Output as formatted text
            for entry in entries:
                status = "SUCCESS" if entry.success else "FAILED"
                print(f"[{entry.timestamp}] {entry.level.value} {status} {entry.script_id} " 
                     f"({entry.specialist}) - {entry.duration_seconds:.2f}s")
                
                if not entry.success and entry.error_message:
                    print(f"  Error: {entry.error_message}")
                    if entry.error_category:
                        print(f"  Category: {entry.error_category}")
                
                if entry.resource_usage:
                    peak_mem = entry.resource_usage.get('peak_memory_mb', 0)
                    cpu_time = entry.resource_usage.get('cpu_time_seconds', 0)
                    print(f"  Resources: Peak Memory: {peak_mem:.1f}MB, CPU Time: {cpu_time:.2f}s")


if __name__ == '__main__':
    main()