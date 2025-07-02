#!/usr/bin/env python3
"""
MetaClaude Monitoring Dashboard
Simple terminal-based dashboard for monitoring script executions
"""

import os
import sys
import time
import datetime
import curses
from pathlib import Path
from typing import Dict, List, Any

# Add parent directories to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from monitoring.execution_logger import ExecutionLogger, LogLevel
from monitoring.metrics_collector import MetricsCollector


class MonitoringDashboard:
    """Terminal-based monitoring dashboard"""
    
    def __init__(self):
        self.logger = ExecutionLogger()
        self.metrics = MetricsCollector()
        self.refresh_interval = 5  # seconds
        self.running = True
    
    def run(self):
        """Run the dashboard with curses"""
        try:
            curses.wrapper(self._main_loop)
        except KeyboardInterrupt:
            pass
    
    def _main_loop(self, stdscr):
        """Main dashboard loop"""
        # Configure curses
        curses.curs_set(0)  # Hide cursor
        stdscr.nodelay(1)   # Non-blocking input
        stdscr.timeout(100) # Refresh every 100ms
        
        # Color pairs
        curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)
        curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK)
        curses.init_pair(4, curses.COLOR_CYAN, curses.COLOR_BLACK)
        
        last_refresh = 0
        
        while self.running:
            # Check for quit key
            key = stdscr.getch()
            if key == ord('q') or key == ord('Q'):
                break
            
            # Refresh data periodically
            current_time = time.time()
            if current_time - last_refresh >= self.refresh_interval:
                self._refresh_display(stdscr)
                last_refresh = current_time
            
            # Small delay to reduce CPU usage
            time.sleep(0.1)
    
    def _refresh_display(self, stdscr):
        """Refresh the dashboard display"""
        stdscr.clear()
        height, width = stdscr.getmaxyx()
        
        # Header
        header = "MetaClaude Monitoring Dashboard"
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        stdscr.addstr(0, 0, header, curses.A_BOLD)
        stdscr.addstr(0, width - len(timestamp) - 1, timestamp)
        stdscr.addstr(1, 0, "=" * (width - 1))
        
        # Get current data
        stats = self.logger.get_statistics(
            start_date=datetime.datetime.now() - datetime.timedelta(hours=1)
        )
        metrics = self.metrics.get_current_metrics()
        recent_logs = self.logger.query(
            start_date=datetime.datetime.now() - datetime.timedelta(minutes=5),
            limit=10
        )
        
        row = 3
        
        # Overall statistics
        stdscr.addstr(row, 0, "Overall Statistics (Last Hour)", curses.A_BOLD)
        row += 1
        
        total = stats.get('total_executions', 0)
        successful = stats.get('successful_executions', 0)
        failed = stats.get('failed_executions', 0)
        success_rate = (successful / total * 100) if total > 0 else 0
        
        stdscr.addstr(row, 2, f"Total Executions: {total}")
        row += 1
        
        # Success count with color
        success_color = curses.color_pair(1) if success_rate >= 90 else curses.color_pair(3)
        stdscr.addstr(row, 2, f"Successful: {successful} ({success_rate:.1f}%)", success_color)
        row += 1
        
        # Failed count with color
        fail_color = curses.color_pair(2) if failed > 0 else curses.color_pair(1)
        stdscr.addstr(row, 2, f"Failed: {failed}", fail_color)
        row += 2
        
        # Top scripts by execution count
        if stats.get('groups'):
            stdscr.addstr(row, 0, "Top Scripts by Execution Count", curses.A_BOLD)
            row += 1
            
            # Sort by execution count
            sorted_scripts = sorted(
                stats['groups'].items(),
                key=lambda x: x[1]['count'],
                reverse=True
            )[:5]
            
            for script_id, script_stats in sorted_scripts:
                count = script_stats['count']
                success_rate = script_stats['success_rate'] * 100
                avg_duration = script_stats['average_duration']
                
                color = curses.color_pair(1) if success_rate >= 90 else curses.color_pair(3)
                stdscr.addstr(row, 2, f"{script_id[:30]:30} ", curses.color_pair(4))
                stdscr.addstr(row, 33, f"Count: {count:4d} ", color)
                stdscr.addstr(row, 47, f"Success: {success_rate:5.1f}% ", color)
                stdscr.addstr(row, 63, f"Avg: {avg_duration:6.2f}s")
                row += 1
            
            row += 1
        
        # Current metrics
        if metrics.get('counters'):
            stdscr.addstr(row, 0, "Active Metrics", curses.A_BOLD)
            row += 1
            
            # Show some key metrics
            counter_count = len(metrics['counters'])
            gauge_count = len(metrics['gauges'])
            histogram_count = len(metrics['histogram_counts'])
            
            stdscr.addstr(row, 2, f"Counters: {counter_count}")
            stdscr.addstr(row, 20, f"Gauges: {gauge_count}")
            stdscr.addstr(row, 35, f"Histograms: {histogram_count}")
            row += 2
        
        # Recent executions
        if recent_logs and row < height - 5:
            stdscr.addstr(row, 0, "Recent Executions", curses.A_BOLD)
            row += 1
            
            for log in recent_logs[:min(5, height - row - 2)]:
                # Format timestamp
                ts = datetime.datetime.fromisoformat(log.timestamp)
                time_str = ts.strftime("%H:%M:%S")
                
                # Determine color based on status
                if log.success:
                    color = curses.color_pair(1)
                    status = "SUCCESS"
                else:
                    color = curses.color_pair(2)
                    status = "FAILED "
                
                # Display log entry
                script_display = f"{log.script_id[:20]:20}"
                duration_str = f"{log.duration_seconds:6.2f}s"
                
                stdscr.addstr(row, 2, time_str)
                stdscr.addstr(row, 11, status, color)
                stdscr.addstr(row, 19, script_display, curses.color_pair(4))
                stdscr.addstr(row, 40, duration_str)
                
                if not log.success and log.error_category:
                    stdscr.addstr(row, 50, f"[{log.error_category}]", curses.color_pair(3))
                
                row += 1
        
        # Footer
        footer_row = height - 2
        stdscr.addstr(footer_row, 0, "-" * (width - 1))
        stdscr.addstr(footer_row + 1, 0, "Press 'q' to quit | Refreshes every 5 seconds")
        
        stdscr.refresh()


def main():
    """Run the monitoring dashboard"""
    import argparse
    
    parser = argparse.ArgumentParser(description='MetaClaude monitoring dashboard')
    parser.add_argument('--text', action='store_true',
                       help='Show text-based output instead of dashboard')
    
    args = parser.parse_args()
    
    if args.text:
        # Simple text output
        logger = ExecutionLogger()
        metrics = MetricsCollector()
        
        while True:
            os.system('clear' if os.name == 'posix' else 'cls')
            
            print("MetaClaude Monitoring - Text Mode")
            print("=" * 50)
            
            # Get stats
            stats = logger.get_statistics(
                start_date=datetime.datetime.now() - datetime.timedelta(hours=1)
            )
            
            print(f"\nLast Hour Statistics:")
            print(f"  Total Executions: {stats.get('total_executions', 0)}")
            print(f"  Successful: {stats.get('successful_executions', 0)}")
            print(f"  Failed: {stats.get('failed_executions', 0)}")
            
            # Recent logs
            recent = logger.query(
                start_date=datetime.datetime.now() - datetime.timedelta(minutes=5),
                limit=5
            )
            
            print(f"\nRecent Executions:")
            for log in recent:
                status = "OK" if log.success else "FAIL"
                print(f"  [{log.timestamp}] {status} {log.script_id} ({log.duration_seconds:.2f}s)")
            
            print("\nPress Ctrl+C to quit...")
            
            try:
                time.sleep(5)
            except KeyboardInterrupt:
                break
    else:
        # Run curses dashboard
        dashboard = MonitoringDashboard()
        dashboard.run()


if __name__ == '__main__':
    main()