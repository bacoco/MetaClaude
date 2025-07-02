#!/usr/bin/env python3
"""
MetaClaude Monitoring Integration
Integrates TES with execution logging and metrics collection
"""

import os
import sys
import importlib.util
from pathlib import Path
from typing import Dict, Any

# Add parent directories to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Load modules with hyphens in names
def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

# Get base directory
base_dir = Path(__file__).parent.parent

# Load TES module
tes_module = load_module('tool_execution_service', 
                        base_dir / 'core' / 'tool-execution-service.py')
ToolExecutionService = tes_module.ToolExecutionService
ExecutionResult = tes_module.ExecutionResult

# Load monitoring modules  
logger_module = load_module('execution_logger',
                           base_dir / 'monitoring' / 'execution-logger.py')
ExecutionLogger = logger_module.ExecutionLogger

metrics_module = load_module('metrics_collector',
                            base_dir / 'monitoring' / 'metrics-collector.py')
MetricsCollector = metrics_module.MetricsCollector


class MonitoredToolExecutionService(ToolExecutionService):
    """Enhanced TES with integrated monitoring"""
    
    def __init__(self, registry_path: str, 
                 enable_logging: bool = True,
                 enable_metrics: bool = True,
                 statsd_host: str = None):
        """
        Initialize monitored TES
        
        Args:
            registry_path: Path to script registry
            enable_logging: Enable execution logging
            enable_metrics: Enable metrics collection
            statsd_host: StatsD server host for metrics
        """
        super().__init__(registry_path)
        
        self.enable_logging = enable_logging
        self.enable_metrics = enable_metrics
        
        # Initialize monitoring components
        if self.enable_logging:
            self.logger = ExecutionLogger()
        
        if self.enable_metrics:
            self.metrics = MetricsCollector(statsd_host=statsd_host)
    
    def execute(self, script_id: str, arguments: Dict[str, Any],
               session_id: str = None, correlation_id: str = None) -> ExecutionResult:
        """Execute script with monitoring"""
        # Get script metadata for logging
        script = self.get_script(script_id)
        specialist = script.get('specialist', 'unknown') if script else 'unknown'
        
        # Execute the script
        result = super().execute(script_id, arguments)
        
        # Log execution
        if self.enable_logging and script:
            self.logger.log_execution(
                script_id=script_id,
                specialist=specialist,
                inputs=arguments,
                result=result,
                session_id=session_id,
                correlation_id=correlation_id
            )
        
        # Record metrics
        if self.enable_metrics and script:
            self.metrics.record_execution(
                script_id=script_id,
                specialist=specialist,
                result=result
            )
        
        return result
    
    def get_execution_stats(self, script_id: str = None, 
                          specialist: str = None) -> Dict[str, Any]:
        """Get execution statistics"""
        if not self.enable_logging:
            return {}
        
        return self.logger.get_statistics(
            group_by='script_id' if script_id else 'specialist'
        )
    
    def get_metrics_report(self, period_minutes: int = 60) -> Dict[str, Any]:
        """Get metrics report"""
        if not self.enable_metrics:
            return {}
        
        return self.metrics.generate_report(period_minutes=period_minutes)
    
    def export_prometheus_metrics(self) -> str:
        """Export metrics in Prometheus format"""
        if not self.enable_metrics:
            return ""
        
        return self.metrics.export_prometheus()
    
    def shutdown(self):
        """Shutdown monitoring components"""
        if self.enable_logging:
            self.logger.shutdown()
        
        if self.enable_metrics:
            self.metrics.shutdown()


# Convenience function for creating monitored TES instance
def create_monitored_tes(registry_path: str = None, **kwargs) -> MonitoredToolExecutionService:
    """
    Create a monitored TES instance with sensible defaults
    
    Args:
        registry_path: Path to registry (defaults to standard location)
        **kwargs: Additional arguments for MonitoredToolExecutionService
    
    Returns:
        MonitoredToolExecutionService instance
    """
    if registry_path is None:
        # Default location
        script_dir = Path(__file__).parent.parent
        registry_path = script_dir / 'registry.json'
    
    return MonitoredToolExecutionService(registry_path, **kwargs)


# Example usage and testing
if __name__ == '__main__':
    import json
    import time
    
    # Create monitored TES
    tes = create_monitored_tes()
    
    # Example: Execute a script
    print("Testing monitored execution...")
    
    # Simulate some executions
    test_scripts = [
        ('validate_api_schema', {'schema_file': 'test.yaml', 'api_url': 'http://example.com'}),
        ('generate_test_cases', {'spec_file': 'spec.md', 'framework': 'pytest'}),
        ('optimize_database_query', {'query': 'SELECT * FROM users', 'database': 'postgres'})
    ]
    
    for script_id, args in test_scripts:
        print(f"\nExecuting {script_id}...")
        
        # Check if script exists
        script = tes.get_script(script_id)
        if script:
            result = tes.execute(script_id, args, session_id='test-session-123')
            
            if result.success:
                print(f"  Success! Duration: {result.execution_time:.2f}s")
            else:
                print(f"  Failed: {result.error}")
                if result.error_details:
                    print(f"  Category: {result.error_details.category.value}")
                    print(f"  Suggestions:")
                    for suggestion in result.error_details.suggestions:
                        print(f"    - {suggestion}")
        else:
            print(f"  Script not found: {script_id}")
        
        # Small delay between executions
        time.sleep(0.5)
    
    # Show statistics
    print("\n\nExecution Statistics:")
    stats = tes.get_execution_stats()
    print(json.dumps(stats, indent=2))
    
    # Show metrics report
    print("\n\nMetrics Report:")
    report = tes.get_metrics_report(period_minutes=5)
    print(json.dumps(report, indent=2))
    
    # Export Prometheus metrics
    print("\n\nPrometheus Metrics:")
    print(tes.export_prometheus_metrics())
    
    # Shutdown
    tes.shutdown()
    print("\n\nMonitoring shutdown complete.")