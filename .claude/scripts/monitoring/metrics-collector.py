#!/usr/bin/env python3
"""
MetaClaude Metrics Collector
Collects and exports execution metrics in various formats
"""

import json
import time
import socket
import threading
import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from collections import defaultdict, deque
import statistics


@dataclass
class Metric:
    """Individual metric data point"""
    name: str
    value: float
    timestamp: float
    tags: Dict[str, str]
    metric_type: str  # counter, gauge, histogram, summary


class MetricsCollector:
    """Collects and aggregates execution metrics"""
    
    def __init__(self,
                 retention_minutes: int = 60,
                 aggregation_interval: int = 60,
                 statsd_host: str = None,
                 statsd_port: int = 8125):
        """
        Initialize metrics collector
        
        Args:
            retention_minutes: How long to keep metrics in memory
            aggregation_interval: Seconds between aggregation cycles
            statsd_host: StatsD server host (optional)
            statsd_port: StatsD server port
        """
        self.retention_minutes = retention_minutes
        self.aggregation_interval = aggregation_interval
        
        # Metrics storage
        self.metrics = defaultdict(lambda: deque(maxlen=retention_minutes))
        self.counters = defaultdict(int)
        self.gauges = defaultdict(float)
        self.histograms = defaultdict(list)
        
        # Alert thresholds
        self.alert_thresholds = {
            'error_rate_percent': 10.0,  # Alert if error rate exceeds 10%
            'p95_duration_seconds': 30.0,  # Alert if p95 duration exceeds 30s
            'memory_peak_mb': 1024.0,  # Alert if peak memory exceeds 1GB
            'execution_rate_drop_percent': 50.0,  # Alert if execution rate drops by 50%
        }
        self.alerts = []  # Active alerts
        self.alert_callbacks = []  # Functions to call on new alerts
        
        # StatsD configuration
        self.statsd_host = statsd_host
        self.statsd_port = statsd_port
        self.statsd_socket = None
        if self.statsd_host:
            self.statsd_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        
        # Aggregation thread
        self.running = True
        self.aggregation_thread = threading.Thread(target=self._aggregation_loop, daemon=True)
        self.aggregation_thread.start()
        
        # Lock for thread safety
        self.lock = threading.Lock()
    
    def _aggregation_loop(self):
        """Background thread for periodic aggregation"""
        while self.running:
            time.sleep(self.aggregation_interval)
            self._aggregate_metrics()
            self.check_alerts()  # Check for alerts after aggregation
    
    def _aggregate_metrics(self):
        """Aggregate histogram metrics into summaries"""
        with self.lock:
            current_time = time.time()
            
            # Process histograms
            for key, values in list(self.histograms.items()):
                if not values:
                    continue
                
                # Calculate percentiles
                sorted_values = sorted(values)
                count = len(values)
                
                summary = {
                    'count': count,
                    'sum': sum(values),
                    'min': sorted_values[0],
                    'max': sorted_values[-1],
                    'mean': statistics.mean(values),
                    'p50': sorted_values[int(count * 0.5)],
                    'p90': sorted_values[int(count * 0.9)],
                    'p95': sorted_values[int(count * 0.95)],
                    'p99': sorted_values[int(count * 0.99)] if count > 100 else sorted_values[-1]
                }
                
                # Store summary
                metric_name = f"{key}_summary"
                self.metrics[metric_name].append({
                    'timestamp': current_time,
                    'value': summary,
                    'type': 'summary'
                })
                
                # Clear histogram for next interval
                self.histograms[key] = []
    
    def increment_counter(self, name: str, value: float = 1.0, tags: Dict[str, str] = None):
        """Increment a counter metric"""
        with self.lock:
            key = self._make_key(name, tags)
            self.counters[key] += value
            
            # Send to StatsD if configured
            if self.statsd_socket:
                self._send_statsd(f"{key}:{value}|c")
    
    def set_gauge(self, name: str, value: float, tags: Dict[str, str] = None):
        """Set a gauge metric"""
        with self.lock:
            key = self._make_key(name, tags)
            self.gauges[key] = value
            
            # Send to StatsD if configured
            if self.statsd_socket:
                self._send_statsd(f"{key}:{value}|g")
    
    def record_histogram(self, name: str, value: float, tags: Dict[str, str] = None):
        """Record a value in a histogram"""
        with self.lock:
            key = self._make_key(name, tags)
            self.histograms[key].append(value)
            
            # Send to StatsD if configured  
            if self.statsd_socket:
                self._send_statsd(f"{key}:{value}|h")
    
    def record_execution(self, script_id: str, specialist: str, result: Any):
        """Record metrics from a script execution result"""
        # Basic execution counter
        self.increment_counter('metaclaude.executions.total', tags={
            'script_id': script_id,
            'specialist': specialist
        })
        
        # Success/failure counters
        if result.success:
            self.increment_counter('metaclaude.executions.success', tags={
                'script_id': script_id,
                'specialist': specialist
            })
        else:
            error_category = 'unknown'
            if result.error_details:
                error_category = result.error_details.category.value
            
            self.increment_counter('metaclaude.executions.failure', tags={
                'script_id': script_id,
                'specialist': specialist,
                'error_category': error_category
            })
        
        # Duration histogram
        self.record_histogram('metaclaude.execution.duration_seconds', 
                            result.execution_time,
                            tags={
                                'script_id': script_id,
                                'specialist': specialist
                            })
        
        # Resource usage metrics
        if result.resource_usage:
            self.record_histogram('metaclaude.resource.memory_peak_mb',
                                result.resource_usage.peak_memory_mb,
                                tags={
                                    'script_id': script_id,
                                    'specialist': specialist
                                })
            
            self.record_histogram('metaclaude.resource.cpu_time_seconds',
                                result.resource_usage.cpu_time_seconds,
                                tags={
                                    'script_id': script_id,
                                    'specialist': specialist
                                })
        
        # Retry metrics
        if result.retry_count > 0:
            self.increment_counter('metaclaude.executions.retries', 
                                 value=result.retry_count,
                                 tags={
                                     'script_id': script_id,
                                     'specialist': specialist
                                 })
    
    def _make_key(self, name: str, tags: Dict[str, str] = None) -> str:
        """Create metric key from name and tags"""
        if not tags:
            return name
        
        tag_str = ','.join(f"{k}={v}" for k, v in sorted(tags.items()))
        return f"{name},{tag_str}"
    
    def _send_statsd(self, message: str):
        """Send metric to StatsD server"""
        if self.statsd_socket and self.statsd_host:
            try:
                self.statsd_socket.sendto(
                    message.encode('utf-8'),
                    (self.statsd_host, self.statsd_port)
                )
            except Exception:
                # Silently ignore StatsD errors
                pass
    
    def export_prometheus(self) -> str:
        """Export metrics in Prometheus format"""
        lines = []
        timestamp = int(time.time() * 1000)
        
        with self.lock:
            # Export counters
            for key, value in self.counters.items():
                metric_name, tags = self._parse_key(key)
                labels = self._format_prometheus_labels(tags)
                lines.append(f"{metric_name}_total{labels} {value} {timestamp}")
            
            # Export gauges
            for key, value in self.gauges.items():
                metric_name, tags = self._parse_key(key)
                labels = self._format_prometheus_labels(tags)
                lines.append(f"{metric_name}{labels} {value} {timestamp}")
            
            # Export summaries from aggregated metrics
            for key, values in self.metrics.items():
                if values and values[-1].get('type') == 'summary':
                    metric_name, tags = self._parse_key(key.replace('_summary', ''))
                    labels = self._format_prometheus_labels(tags)
                    summary = values[-1]['value']
                    
                    lines.append(f"{metric_name}_count{labels} {summary['count']} {timestamp}")
                    lines.append(f"{metric_name}_sum{labels} {summary['sum']} {timestamp}")
                    lines.append(f"{metric_name}_min{labels} {summary['min']} {timestamp}")
                    lines.append(f"{metric_name}_max{labels} {summary['max']} {timestamp}")
                    
                    for percentile in ['p50', 'p90', 'p95', 'p99']:
                        if percentile in summary:
                            quantile = percentile[1:] 
                            lines.append(f"{metric_name}{{quantile=\"0.{quantile}\"{labels[:-1]}}} {summary[percentile]} {timestamp}")
        
        return '\n'.join(lines)
    
    def _parse_key(self, key: str) -> tuple:
        """Parse metric key into name and tags"""
        parts = key.split(',', 1)
        name = parts[0]
        tags = {}
        
        if len(parts) > 1:
            for tag in parts[1].split(','):
                if '=' in tag:
                    k, v = tag.split('=', 1)
                    tags[k] = v
        
        return name, tags
    
    def _format_prometheus_labels(self, tags: Dict[str, str]) -> str:
        """Format tags as Prometheus labels"""
        if not tags:
            return ""
        
        labels = ','.join(f'{k}="{v}"' for k, v in sorted(tags.items()))
        return f"{{{labels}}}"
    
    def get_current_metrics(self) -> Dict[str, Any]:
        """Get current metric values"""
        with self.lock:
            return {
                'counters': dict(self.counters),
                'gauges': dict(self.gauges),
                'histogram_counts': {k: len(v) for k, v in self.histograms.items()},
                'summaries': {
                    k: v[-1]['value'] if v else None 
                    for k, v in self.metrics.items() 
                    if k.endswith('_summary')
                }
            }
    
    def generate_report(self, period_minutes: int = 60) -> Dict[str, Any]:
        """Generate a metrics report for the specified period"""
        cutoff_time = time.time() - (period_minutes * 60)
        report = {
            'period_minutes': period_minutes,
            'generated_at': datetime.datetime.now().isoformat(),
            'execution_stats': {},
            'performance_stats': {},
            'error_analysis': {},
            'resource_usage': {}
        }
        
        with self.lock:
            # Execution statistics
            total_executions = 0
            successful_executions = 0
            failed_executions = 0
            
            for key, value in self.counters.items():
                if 'executions.total' in key:
                    total_executions += value
                elif 'executions.success' in key:
                    successful_executions += value
                elif 'executions.failure' in key:
                    failed_executions += value
            
            report['execution_stats'] = {
                'total': total_executions,
                'successful': successful_executions,
                'failed': failed_executions,
                'success_rate': successful_executions / total_executions if total_executions > 0 else 0
            }
            
            # Performance statistics from summaries
            duration_summaries = {}
            for key, values in self.metrics.items():
                if 'duration_seconds_summary' in key and values:
                    _, tags = self._parse_key(key.replace('_summary', ''))
                    specialist = tags.get('specialist', 'unknown')
                    
                    if specialist not in duration_summaries:
                        duration_summaries[specialist] = []
                    
                    duration_summaries[specialist].append(values[-1]['value'])
            
            for specialist, summaries in duration_summaries.items():
                if summaries:
                    latest = summaries[-1]
                    report['performance_stats'][specialist] = {
                        'avg_duration': latest['mean'],
                        'p50_duration': latest['p50'],
                        'p95_duration': latest['p95'],
                        'max_duration': latest['max']
                    }
            
            # Error analysis
            error_counts = defaultdict(int)
            for key, value in self.counters.items():
                if 'executions.failure' in key:
                    _, tags = self._parse_key(key)
                    error_category = tags.get('error_category', 'unknown')
                    error_counts[error_category] += value
            
            report['error_analysis'] = dict(error_counts)
            
            # Resource usage statistics
            memory_summaries = {}
            cpu_summaries = {}
            
            for key, values in self.metrics.items():
                if 'memory_peak_mb_summary' in key and values:
                    _, tags = self._parse_key(key.replace('_summary', ''))
                    specialist = tags.get('specialist', 'unknown')
                    memory_summaries[specialist] = values[-1]['value']
                
                elif 'cpu_time_seconds_summary' in key and values:
                    _, tags = self._parse_key(key.replace('_summary', ''))
                    specialist = tags.get('specialist', 'unknown')
                    cpu_summaries[specialist] = values[-1]['value']
            
            for specialist in set(list(memory_summaries.keys()) + list(cpu_summaries.keys())):
                report['resource_usage'][specialist] = {}
                
                if specialist in memory_summaries:
                    report['resource_usage'][specialist]['memory'] = {
                        'avg_peak_mb': memory_summaries[specialist]['mean'],
                        'max_peak_mb': memory_summaries[specialist]['max']
                    }
                
                if specialist in cpu_summaries:
                    report['resource_usage'][specialist]['cpu'] = {
                        'avg_cpu_seconds': cpu_summaries[specialist]['mean'],
                        'max_cpu_seconds': cpu_summaries[specialist]['max']
                    }
        
        return report
    
    def check_alerts(self) -> List[Dict[str, Any]]:
        """Check for alert conditions and return new alerts"""
        new_alerts = []
        current_time = datetime.datetime.now()
        
        with self.lock:
            # Check error rate
            total_executions = sum(v for k, v in self.counters.items() if 'executions.total' in k)
            failed_executions = sum(v for k, v in self.counters.items() if 'executions.failure' in k)
            
            if total_executions > 0:
                error_rate = (failed_executions / total_executions) * 100
                if error_rate > self.alert_thresholds['error_rate_percent']:
                    alert = {
                        'timestamp': current_time.isoformat(),
                        'type': 'error_rate_high',
                        'severity': 'warning' if error_rate < 25 else 'critical',
                        'message': f'Error rate is {error_rate:.1f}% (threshold: {self.alert_thresholds["error_rate_percent"]}%)',
                        'value': error_rate,
                        'threshold': self.alert_thresholds['error_rate_percent']
                    }
                    new_alerts.append(alert)
            
            # Check p95 duration for each specialist
            for key, values in self.metrics.items():
                if 'duration_seconds_summary' in key and values:
                    _, tags = self._parse_key(key.replace('_summary', ''))
                    specialist = tags.get('specialist', 'unknown')
                    latest_summary = values[-1]['value']
                    p95 = latest_summary.get('p95', 0)
                    
                    if p95 > self.alert_thresholds['p95_duration_seconds']:
                        alert = {
                            'timestamp': current_time.isoformat(),
                            'type': 'duration_high',
                            'severity': 'warning',
                            'message': f'{specialist} p95 duration is {p95:.1f}s (threshold: {self.alert_thresholds["p95_duration_seconds"]}s)',
                            'value': p95,
                            'threshold': self.alert_thresholds['p95_duration_seconds'],
                            'specialist': specialist
                        }
                        new_alerts.append(alert)
            
            # Check memory usage
            for key, values in self.metrics.items():
                if 'memory_peak_mb_summary' in key and values:
                    _, tags = self._parse_key(key.replace('_summary', ''))
                    specialist = tags.get('specialist', 'unknown')
                    latest_summary = values[-1]['value']
                    max_memory = latest_summary.get('max', 0)
                    
                    if max_memory > self.alert_thresholds['memory_peak_mb']:
                        alert = {
                            'timestamp': current_time.isoformat(),
                            'type': 'memory_high',
                            'severity': 'warning' if max_memory < 2048 else 'critical',
                            'message': f'{specialist} peak memory is {max_memory:.1f}MB (threshold: {self.alert_thresholds["memory_peak_mb"]}MB)',
                            'value': max_memory,
                            'threshold': self.alert_thresholds['memory_peak_mb'],
                            'specialist': specialist
                        }
                        new_alerts.append(alert)
        
        # Store new alerts and trigger callbacks
        if new_alerts:
            self.alerts.extend(new_alerts)
            # Keep only last 100 alerts
            self.alerts = self.alerts[-100:]
            
            # Trigger callbacks
            for callback in self.alert_callbacks:
                try:
                    callback(new_alerts)
                except Exception:
                    pass
        
        return new_alerts
    
    def set_alert_threshold(self, metric: str, value: float):
        """Set alert threshold for a metric"""
        if metric in self.alert_thresholds:
            self.alert_thresholds[metric] = value
    
    def register_alert_callback(self, callback):
        """Register a callback function for alerts"""
        self.alert_callbacks.append(callback)
    
    def get_alerts(self, since: datetime.datetime = None) -> List[Dict[str, Any]]:
        """Get alerts since specified time"""
        if since is None:
            return self.alerts.copy()
        
        since_iso = since.isoformat()
        return [a for a in self.alerts if a['timestamp'] >= since_iso]
    
    def shutdown(self):
        """Shutdown the metrics collector"""
        self.running = False
        self.aggregation_thread.join(timeout=5)
        
        if self.statsd_socket:
            self.statsd_socket.close()


def main():
    """Command-line interface for metrics"""
    import argparse
    
    parser = argparse.ArgumentParser(description='MetaClaude metrics collector')
    parser.add_argument('--prometheus', action='store_true', 
                       help='Export metrics in Prometheus format')
    parser.add_argument('--report', action='store_true',
                       help='Generate metrics report')
    parser.add_argument('--period', type=int, default=60,
                       help='Report period in minutes')
    parser.add_argument('--json', action='store_true',
                       help='Output as JSON')
    parser.add_argument('--current', action='store_true',
                       help='Show current metric values')
    
    args = parser.parse_args()
    
    # Create metrics collector
    collector = MetricsCollector()
    
    # Load some sample data for demonstration
    # In production, this would be populated by TES
    
    if args.prometheus:
        print(collector.export_prometheus())
    
    elif args.report:
        report = collector.generate_report(period_minutes=args.period)
        
        if args.json:
            print(json.dumps(report, indent=2))
        else:
            print(f"Metrics Report - Period: {report['period_minutes']} minutes")
            print(f"Generated at: {report['generated_at']}")
            print("\nExecution Statistics:")
            stats = report['execution_stats']
            print(f"  Total: {stats['total']}")
            print(f"  Successful: {stats['successful']} ({stats['success_rate']*100:.1f}%)")
            print(f"  Failed: {stats['failed']}")
            
            if report['performance_stats']:
                print("\nPerformance by Specialist:")
                for specialist, perf in report['performance_stats'].items():
                    print(f"  {specialist}:")
                    print(f"    Avg Duration: {perf['avg_duration']:.2f}s")
                    print(f"    P95 Duration: {perf['p95_duration']:.2f}s")
            
            if report['error_analysis']:
                print("\nError Analysis:")
                for category, count in report['error_analysis'].items():
                    print(f"  {category}: {count}")
            
            if report['resource_usage']:
                print("\nResource Usage by Specialist:")
                for specialist, resources in report['resource_usage'].items():
                    print(f"  {specialist}:")
                    if 'memory' in resources:
                        print(f"    Avg Peak Memory: {resources['memory']['avg_peak_mb']:.1f}MB")
                    if 'cpu' in resources:
                        print(f"    Avg CPU Time: {resources['cpu']['avg_cpu_seconds']:.2f}s")
    
    elif args.current:
        metrics = collector.get_current_metrics()
        
        if args.json:
            print(json.dumps(metrics, indent=2))
        else:
            print("Current Metrics:")
            print(f"\nCounters: {len(metrics['counters'])}")
            for key, value in list(metrics['counters'].items())[:10]:
                print(f"  {key}: {value}")
            
            print(f"\nGauges: {len(metrics['gauges'])}")
            for key, value in list(metrics['gauges'].items())[:10]:
                print(f"  {key}: {value}")
            
            print(f"\nHistograms: {len(metrics['histogram_counts'])}")
            for key, count in list(metrics['histogram_counts'].items())[:10]:
                print(f"  {key}: {count} values")
    
    collector.shutdown()


if __name__ == '__main__':
    main()