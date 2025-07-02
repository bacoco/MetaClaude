#!/usr/bin/env python3
"""
Test script to demonstrate monitoring capabilities
"""

import sys
import time
import json
import importlib.util
from pathlib import Path

# Add parent directories to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Load module with hyphen in name
def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

# Load monitoring integration
base_dir = Path(__file__).parent.parent
monitoring_integration = load_module('monitoring_integration', 
                                   base_dir / 'core' / 'monitoring-integration.py')
MonitoredToolExecutionService = monitoring_integration.MonitoredToolExecutionService


def test_monitoring():
    """Test and demonstrate monitoring features"""
    print("MetaClaude Monitoring Test")
    print("=" * 50)
    
    # Create monitored TES instance
    print("\n1. Creating monitored TES instance...")
    registry_path = create_test_registry()
    tes = MonitoredToolExecutionService(
        registry_path=str(registry_path),
        enable_logging=True,
        enable_metrics=True
    )
    print("   ✓ TES initialized with monitoring enabled")
    
    # Set up alert callback to show alerts in real-time
    alerts_received = []
    def alert_callback(alerts):
        for alert in alerts:
            print(f"\n   🚨 ALERT: {alert['message']}")
            alerts_received.append(alert)
    
    if hasattr(tes, 'metrics'):
        tes.metrics.register_alert_callback(alert_callback)
        # Set lower thresholds for testing
        tes.metrics.set_alert_threshold('error_rate_percent', 5.0)
        tes.metrics.set_alert_threshold('p95_duration_seconds', 0.1)
    
    # Test scenarios
    test_cases = [
        {
            'name': 'Successful Execution',
            'script_id': 'echo_test',
            'args': {'message': 'Hello, MetaClaude!'},
            'should_succeed': True
        },
        {
            'name': 'Validation Error',
            'script_id': 'echo_test',
            'args': {},  # Missing required argument
            'should_succeed': False
        },
        {
            'name': 'Non-existent Script',
            'script_id': 'non_existent_script',
            'args': {},
            'should_succeed': False
        },
        {
            'name': 'Script with Output',
            'script_id': 'json_output_test',
            'args': {'data': {'key': 'value'}},
            'should_succeed': True
        }
    ]
    
    print("\n2. Running test executions...")
    
    for i, test in enumerate(test_cases, 1):
        print(f"\n   Test {i}: {test['name']}")
        print(f"   Script: {test['script_id']}")
        print(f"   Args: {test['args']}")
        
        # Execute
        result = tes.execute(
            test['script_id'],
            test['args'],
            session_id='test-session',
            correlation_id=f'test-{i}'
        )
        
        # Show results
        if result.success:
            print(f"   ✓ Success! Duration: {result.execution_time:.3f}s")
            if result.outputs:
                print(f"   Outputs: {result.outputs}")
        else:
            print(f"   ✗ Failed: {result.error}")
            if result.error_details:
                print(f"   Category: {result.error_details.category.value}")
                print(f"   Suggestions:")
                for suggestion in result.error_details.suggestions[:2]:
                    print(f"     - {suggestion}")
        
        # Show resource usage if available
        if result.resource_usage:
            print(f"   Resources: Memory {result.resource_usage.peak_memory_mb:.1f}MB, "
                  f"CPU {result.resource_usage.cpu_time_seconds:.3f}s")
        
        # Small delay between tests
        time.sleep(0.5)
    
    # Show statistics
    print("\n3. Execution Statistics:")
    if hasattr(tes, 'logger'):
        stats = tes.logger.get_statistics()
        
        total = stats.get('total_executions', 0)
        successful = stats.get('successful_executions', 0)
        failed = stats.get('failed_executions', 0)
        
        print(f"   Total Executions: {total}")
        print(f"   Successful: {successful}")
        print(f"   Failed: {failed}")
        
        if stats.get('groups'):
            print("\n   By Script:")
            for script_id, script_stats in stats['groups'].items():
                print(f"     {script_id}:")
                print(f"       Count: {script_stats['count']}")
                print(f"       Success Rate: {script_stats['success_rate']*100:.1f}%")
                print(f"       Avg Duration: {script_stats['average_duration']:.3f}s")
    
    # Show metrics report
    print("\n4. Metrics Report (last 5 minutes):")
    if hasattr(tes, 'metrics'):
        report = tes.metrics.generate_report(period_minutes=5)
        
        if report.get('execution_stats'):
            exec_stats = report['execution_stats']
            print(f"   Success Rate: {exec_stats.get('success_rate', 0)*100:.1f}%")
        
        if report.get('error_analysis'):
            print("\n   Error Analysis:")
            for category, count in report['error_analysis'].items():
                print(f"     {category}: {count}")
        
        # Check for alerts
        print("\n   Active Alerts:")
        alerts = tes.metrics.get_alerts()
        if alerts:
            for alert in alerts[-5:]:  # Show last 5 alerts
                print(f"     [{alert['severity']}] {alert['message']}")
        else:
            print("     No alerts triggered")
    
    # Export Prometheus metrics
    print("\n5. Prometheus Metrics Sample:")
    if hasattr(tes, 'metrics'):
        prometheus_metrics = tes.metrics.export_prometheus()
        if prometheus_metrics:
            # Show first few lines
            lines = prometheus_metrics.split('\n')[:5]
            for line in lines:
                print(f"   {line}")
            if len(prometheus_metrics.split('\n')) > 5:
                print(f"   ... ({len(prometheus_metrics.split('\n')) - 5} more lines)")
    
    # Query logs
    print("\n6. Recent Execution Logs:")
    if hasattr(tes, 'logger'):
        recent_logs = tes.logger.query(limit=5)
        for log in recent_logs:
            status = "SUCCESS" if log.success else "FAILED"
            print(f"   [{log.timestamp}] {status} {log.script_id} ({log.duration_seconds:.3f}s)")
    
    # Shutdown
    print("\n7. Shutting down monitoring...")
    if hasattr(tes, 'logger'):
        tes.logger.shutdown()
    if hasattr(tes, 'metrics'):
        tes.metrics.shutdown()
    print("   ✓ Monitoring shutdown complete")
    
    # Summary of alerts received
    if alerts_received:
        print(f"\n8. Summary: {len(alerts_received)} alerts triggered during test")
    
    print("\n" + "=" * 50)
    print("Monitoring test complete!")
    print("\nTo view the web dashboard, run: ./monitoring/dashboard.py")
    print("To view terminal dashboard, run: ./monitoring/dashboard-terminal.py")
    print("To query logs, run: ./monitoring/execution-logger.py --help")
    print("To export metrics, run: ./monitoring/metrics-collector.py --prometheus")


# Create some test scripts in the registry for demonstration
def create_test_registry():
    """Create a test registry with sample scripts"""
    registry = {
        "version": "1.0",
        "scripts": [
            {
                "id": "echo_test",
                "name": "Echo Test",
                "description": "Simple echo script for testing",
                "specialist": "test",
                "path": "test/echo.sh",
                "execution": {
                    "interpreter": "/bin/bash",
                    "timeout": 5000,
                    "args": [
                        {
                            "name": "message",
                            "type": "string",
                            "required": True,
                            "description": "Message to echo"
                        }
                    ]
                },
                "security": {
                    "sandbox": "minimal",
                    "max_memory": "256MB"
                }
            },
            {
                "id": "json_output_test",
                "name": "JSON Output Test",
                "description": "Script that produces JSON output",
                "specialist": "test",
                "path": "test/json_output.py",
                "execution": {
                    "interpreter": "/usr/bin/python3",
                    "timeout": 5000,
                    "args": [
                        {
                            "name": "data",
                            "type": "object",
                            "required": True,
                            "description": "Data to process"
                        }
                    ]
                },
                "outputs": [
                    {
                        "name": "processed",
                        "type": "object",
                        "description": "Processed data"
                    },
                    {
                        "name": "timestamp",
                        "type": "string",
                        "description": "Processing timestamp"
                    }
                ],
                "security": {
                    "sandbox": "standard",
                    "max_memory": "512MB"
                }
            }
        ]
    }
    
    # Write test registry
    registry_path = Path(__file__).parent.parent / 'test_registry.json'
    with open(registry_path, 'w') as f:
        json.dump(registry, f, indent=2)
    
    # Create test scripts directory
    test_dir = Path(__file__).parent.parent / 'test'
    test_dir.mkdir(exist_ok=True)
    
    # Create echo script
    echo_script = test_dir / 'echo.sh'
    echo_script.write_text('''#!/bin/bash
message="$1"
echo "Echo: $message"
exit 0
''')
    echo_script.chmod(0o755)
    
    # Create JSON output script
    json_script = test_dir / 'json_output.py'
    json_script.write_text('''#!/usr/bin/env python3
import sys
import json
from datetime import datetime

data = json.loads(sys.argv[1])
output = {
    "processed": data,
    "timestamp": datetime.now().isoformat()
}
print(json.dumps(output))
''')
    json_script.chmod(0o755)
    
    return registry_path


if __name__ == '__main__':
    # Create test registry if needed
    test_registry = Path(__file__).parent.parent / 'test_registry.json'
    if not test_registry.exists():
        print("Creating test registry...")
        create_test_registry()
    
    # Run monitoring test
    test_monitoring()