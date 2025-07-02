#!/usr/bin/env python3
"""
MetaClaude Web Dashboard
Web-based monitoring dashboard with real-time updates via WebSocket
"""

import os
import sys
import json
import time
import datetime
import threading
import asyncio
import websockets
from pathlib import Path
from typing import Dict, List, Any, Optional
from http.server import HTTPServer, SimpleHTTPRequestHandler
import socket

# Add parent directories to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from monitoring.execution_logger import ExecutionLogger, LogLevel
from monitoring.metrics_collector import MetricsCollector


class DashboardWebServer(SimpleHTTPRequestHandler):
    """HTTP server for serving the dashboard HTML"""
    
    def __init__(self, *args, dashboard_html: str = None, **kwargs):
        self.dashboard_html = dashboard_html
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.dashboard_html.encode())
        else:
            self.send_error(404)
    
    def log_message(self, format, *args):
        """Suppress access logs"""
        pass


class WebDashboard:
    """Web-based monitoring dashboard with WebSocket support"""
    
    def __init__(self, http_port: int = 8080, ws_port: int = 8081):
        self.http_port = http_port
        self.ws_port = ws_port
        self.logger = ExecutionLogger()
        self.metrics = MetricsCollector()
        
        # Register alert callback
        self.metrics.register_alert_callback(self._on_alert)
        
        # WebSocket clients
        self.clients = set()
        self.running = True
        
        # Update interval
        self.update_interval = 5  # seconds
        
        # Generate dashboard HTML
        self.dashboard_html = self._generate_dashboard_html()
        
        # Alert queue for real-time notifications
        self.alert_queue = asyncio.Queue()
    
    def _on_alert(self, alerts: List[Dict[str, Any]]):
        """Callback for new alerts"""
        # Add alerts to queue for websocket broadcast
        for alert in alerts:
            try:
                asyncio.run_coroutine_threadsafe(
                    self.alert_queue.put(alert),
                    self.ws_loop
                )
            except:
                pass
    
    def _generate_dashboard_html(self) -> str:
        """Generate the dashboard HTML with embedded CSS and JavaScript"""
        return f"""<!DOCTYPE html>
<html>
<head>
    <title>MetaClaude Monitoring Dashboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{ 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            color: #333;
            line-height: 1.6;
        }}
        .header {{
            background: #2c3e50;
            color: white;
            padding: 1rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        .container {{ padding: 1rem; max-width: 1400px; margin: 0 auto; }}
        .metrics-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }}
        .metric-card {{
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        .metric-title {{ 
            font-size: 0.9rem;
            color: #666;
            margin-bottom: 0.5rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }}
        .metric-value {{ 
            font-size: 2rem;
            font-weight: bold;
            color: #2c3e50;
        }}
        .metric-subtitle {{ 
            font-size: 0.85rem;
            color: #999;
            margin-top: 0.25rem;
        }}
        .success {{ color: #27ae60; }}
        .warning {{ color: #f39c12; }}
        .error {{ color: #e74c3c; }}
        .section {{
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 1rem;
        }}
        .section-title {{
            font-size: 1.25rem;
            margin-bottom: 1rem;
            color: #2c3e50;
            border-bottom: 2px solid #ecf0f1;
            padding-bottom: 0.5rem;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
        }}
        th, td {{
            text-align: left;
            padding: 0.75rem;
            border-bottom: 1px solid #ecf0f1;
        }}
        th {{
            background: #f8f9fa;
            font-weight: 600;
            color: #666;
            font-size: 0.9rem;
        }}
        .status-badge {{
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 12px;
            font-size: 0.8rem;
            font-weight: 500;
        }}
        .status-success {{ background: #d4edda; color: #155724; }}
        .status-error {{ background: #f8d7da; color: #721c24; }}
        .status-warning {{ background: #fff3cd; color: #856404; }}
        .alert-box {{
            padding: 1rem;
            border-radius: 4px;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}
        .alert-warning {{ background: #fff3cd; border-left: 4px solid #f39c12; }}
        .alert-critical {{ background: #f8d7da; border-left: 4px solid #e74c3c; }}
        .connection-status {{
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: rgba(255,255,255,0.1);
            border-radius: 20px;
        }}
        .connection-dot {{
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #95a5a6;
        }}
        .connection-dot.connected {{ background: #27ae60; }}
        .chart-container {{
            height: 300px;
            position: relative;
        }}
        .loading {{
            text-align: center;
            padding: 2rem;
            color: #999;
        }}
        .timestamp {{
            color: #666;
            font-size: 0.85rem;
        }}
        @keyframes pulse {{
            0% {{ opacity: 1; }}
            50% {{ opacity: 0.5; }}
            100% {{ opacity: 1; }}
        }}
        .updating {{ animation: pulse 1s infinite; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>MetaClaude Monitoring Dashboard</h1>
        <div class="connection-status">
            <div class="connection-dot" id="connectionDot"></div>
            <span id="connectionText">Connecting...</span>
        </div>
    </div>
    
    <div class="container">
        <!-- Summary Metrics -->
        <div class="metrics-grid" id="summaryMetrics">
            <div class="metric-card">
                <div class="metric-title">Total Executions</div>
                <div class="metric-value" id="totalExecutions">-</div>
                <div class="metric-subtitle">Last hour</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Success Rate</div>
                <div class="metric-value" id="successRate">-</div>
                <div class="metric-subtitle">Last hour</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Average Duration</div>
                <div class="metric-value" id="avgDuration">-</div>
                <div class="metric-subtitle">All scripts</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Active Alerts</div>
                <div class="metric-value" id="activeAlerts">0</div>
                <div class="metric-subtitle">Current</div>
            </div>
        </div>
        
        <!-- Alerts Section -->
        <div class="section" id="alertsSection" style="display: none;">
            <h2 class="section-title">Active Alerts</h2>
            <div id="alertsList"></div>
        </div>
        
        <!-- Top Scripts -->
        <div class="section">
            <h2 class="section-title">Top Scripts by Execution Count</h2>
            <table id="topScriptsTable">
                <thead>
                    <tr>
                        <th>Script ID</th>
                        <th>Specialist</th>
                        <th>Count</th>
                        <th>Success Rate</th>
                        <th>Avg Duration</th>
                        <th>P95 Duration</th>
                    </tr>
                </thead>
                <tbody id="topScriptsBody">
                    <tr><td colspan="6" class="loading">Loading...</td></tr>
                </tbody>
            </table>
        </div>
        
        <!-- Recent Executions -->
        <div class="section">
            <h2 class="section-title">Recent Executions</h2>
            <table id="recentExecutionsTable">
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>Script</th>
                        <th>Specialist</th>
                        <th>Status</th>
                        <th>Duration</th>
                        <th>Error</th>
                    </tr>
                </thead>
                <tbody id="recentExecutionsBody">
                    <tr><td colspan="6" class="loading">Loading...</td></tr>
                </tbody>
            </table>
        </div>
        
        <!-- Error Analysis -->
        <div class="section">
            <h2 class="section-title">Error Analysis</h2>
            <div id="errorAnalysis">
                <div class="loading">Loading...</div>
            </div>
        </div>
    </div>
    
    <script>
        // WebSocket connection
        let ws = null;
        let reconnectInterval = null;
        const wsUrl = 'ws://localhost:{self.ws_port}';
        
        // Connect to WebSocket
        function connect() {{
            ws = new WebSocket(wsUrl);
            
            ws.onopen = () => {{
                console.log('WebSocket connected');
                document.getElementById('connectionDot').classList.add('connected');
                document.getElementById('connectionText').textContent = 'Connected';
                
                // Clear reconnect interval
                if (reconnectInterval) {{
                    clearInterval(reconnectInterval);
                    reconnectInterval = null;
                }}
            }};
            
            ws.onmessage = (event) => {{
                const data = JSON.parse(event.data);
                updateDashboard(data);
            }};
            
            ws.onclose = () => {{
                console.log('WebSocket disconnected');
                document.getElementById('connectionDot').classList.remove('connected');
                document.getElementById('connectionText').textContent = 'Disconnected';
                
                // Attempt to reconnect
                if (!reconnectInterval) {{
                    reconnectInterval = setInterval(connect, 5000);
                }}
            }};
            
            ws.onerror = (error) => {{
                console.error('WebSocket error:', error);
            }};
        }}
        
        // Update dashboard with new data
        function updateDashboard(data) {{
            // Update summary metrics
            if (data.summary) {{
                document.getElementById('totalExecutions').textContent = data.summary.total_executions || '0';
                
                const successRate = data.summary.success_rate || 0;
                const rateElement = document.getElementById('successRate');
                rateElement.textContent = successRate.toFixed(1) + '%';
                rateElement.className = 'metric-value ' + (successRate >= 90 ? 'success' : successRate >= 70 ? 'warning' : 'error');
                
                document.getElementById('avgDuration').textContent = (data.summary.avg_duration || 0).toFixed(2) + 's';
            }}
            
            // Update alerts
            if (data.alerts) {{
                const alertsList = document.getElementById('alertsList');
                const alertsSection = document.getElementById('alertsSection');
                const activeAlerts = document.getElementById('activeAlerts');
                
                activeAlerts.textContent = data.alerts.length;
                activeAlerts.className = 'metric-value ' + (data.alerts.length > 0 ? 'error' : 'success');
                
                if (data.alerts.length > 0) {{
                    alertsSection.style.display = 'block';
                    alertsList.innerHTML = data.alerts.map(alert => `
                        <div class="alert-box alert-${{alert.severity}}">
                            <div>
                                <strong>${{alert.message}}</strong>
                                <div class="timestamp">${{new Date(alert.timestamp).toLocaleString()}}</div>
                            </div>
                        </div>
                    `).join('');
                }} else {{
                    alertsSection.style.display = 'none';
                }}
            }}
            
            // Update top scripts
            if (data.top_scripts) {{
                const tbody = document.getElementById('topScriptsBody');
                tbody.innerHTML = data.top_scripts.map(script => `
                    <tr>
                        <td>${{script.script_id}}</td>
                        <td>${{script.specialist}}</td>
                        <td>${{script.count}}</td>
                        <td class="${{script.success_rate >= 90 ? 'success' : script.success_rate >= 70 ? 'warning' : 'error'}}">${{script.success_rate.toFixed(1)}}%</td>
                        <td>${{script.avg_duration.toFixed(2)}}s</td>
                        <td>${{script.p95_duration ? script.p95_duration.toFixed(2) + 's' : '-'}}</td>
                    </tr>
                `).join('') || '<tr><td colspan="6" class="loading">No data</td></tr>';
            }}
            
            // Update recent executions
            if (data.recent_executions) {{
                const tbody = document.getElementById('recentExecutionsBody');
                tbody.innerHTML = data.recent_executions.map(exec => {{
                    const time = new Date(exec.timestamp).toLocaleTimeString();
                    const statusClass = exec.success ? 'success' : 'error';
                    const statusText = exec.success ? 'Success' : 'Failed';
                    
                    return `
                        <tr>
                            <td>${{time}}</td>
                            <td>${{exec.script_id}}</td>
                            <td>${{exec.specialist}}</td>
                            <td><span class="status-badge status-${{statusClass}}">${{statusText}}</span></td>
                            <td>${{exec.duration.toFixed(2)}}s</td>
                            <td>${{exec.error || '-'}}</td>
                        </tr>
                    `;
                }}).join('') || '<tr><td colspan="6" class="loading">No recent executions</td></tr>';
            }}
            
            // Update error analysis
            if (data.error_analysis) {{
                const errorDiv = document.getElementById('errorAnalysis');
                const errors = Object.entries(data.error_analysis);
                
                if (errors.length > 0) {{
                    errorDiv.innerHTML = '<table><thead><tr><th>Error Category</th><th>Count</th></tr></thead><tbody>' +
                        errors.map(([category, count]) => `
                            <tr>
                                <td>${{category}}</td>
                                <td>${{count}}</td>
                            </tr>
                        `).join('') +
                        '</tbody></table>';
                }} else {{
                    errorDiv.innerHTML = '<div class="loading">No errors recorded</div>';
                }}
            }}
        }}
        
        // Initialize connection
        connect();
    </script>
</body>
</html>"""
    
    async def websocket_handler(self, websocket, path):
        """Handle WebSocket connections"""
        # Register client
        self.clients.add(websocket)
        try:
            # Send initial data
            await websocket.send(json.dumps(self._get_dashboard_data()))
            
            # Keep connection alive and send updates
            while True:
                try:
                    # Wait for either a message or timeout
                    message = await asyncio.wait_for(
                        websocket.recv(), 
                        timeout=self.update_interval
                    )
                except asyncio.TimeoutError:
                    # Send periodic update
                    if websocket.open:
                        await websocket.send(json.dumps(self._get_dashboard_data()))
                except websockets.exceptions.ConnectionClosed:
                    break
        finally:
            # Unregister client
            self.clients.discard(websocket)
    
    async def alert_broadcaster(self):
        """Broadcast alerts to all connected clients"""
        while self.running:
            try:
                # Wait for alerts with timeout
                alert = await asyncio.wait_for(
                    self.alert_queue.get(),
                    timeout=1.0
                )
                
                # Broadcast to all clients
                if self.clients:
                    alert_data = json.dumps({
                        'type': 'alert',
                        'alert': alert
                    })
                    
                    # Send to all connected clients
                    disconnected = set()
                    for client in self.clients:
                        try:
                            await client.send(alert_data)
                        except:
                            disconnected.add(client)
                    
                    # Remove disconnected clients
                    self.clients -= disconnected
                    
            except asyncio.TimeoutError:
                continue
    
    def _get_dashboard_data(self) -> Dict[str, Any]:
        """Get current dashboard data"""
        # Get statistics
        stats = self.logger.get_statistics(
            start_date=datetime.datetime.now() - datetime.timedelta(hours=1)
        )
        
        # Get recent executions
        recent_logs = self.logger.query(
            start_date=datetime.datetime.now() - datetime.timedelta(minutes=10),
            limit=20
        )
        
        # Get current metrics
        metrics_data = self.metrics.get_current_metrics()
        report = self.metrics.generate_report(period_minutes=60)
        
        # Get recent alerts
        recent_alerts = self.metrics.get_alerts(
            since=datetime.datetime.now() - datetime.timedelta(hours=1)
        )
        
        # Prepare top scripts data
        top_scripts = []
        if stats.get('groups'):
            for script_id, script_stats in sorted(
                stats['groups'].items(),
                key=lambda x: x[1]['count'],
                reverse=True
            )[:10]:
                # Extract specialist from script_id if present
                parts = script_id.split(',')
                script_name = parts[0]
                specialist = 'unknown'
                
                for part in parts[1:]:
                    if 'specialist=' in part:
                        specialist = part.split('=')[1]
                
                # Get performance metrics
                perf_data = report['performance_stats'].get(specialist, {})
                
                top_scripts.append({
                    'script_id': script_name,
                    'specialist': specialist,
                    'count': script_stats['count'],
                    'success_rate': script_stats['success_rate'] * 100,
                    'avg_duration': script_stats['average_duration'],
                    'p95_duration': perf_data.get('p95_duration')
                })
        
        # Prepare recent executions data
        recent_executions = []
        for log in recent_logs:
            recent_executions.append({
                'timestamp': log.timestamp,
                'script_id': log.script_id,
                'specialist': log.specialist,
                'success': log.success,
                'duration': log.duration_seconds,
                'error': log.error_category if not log.success else None
            })
        
        return {
            'summary': {
                'total_executions': stats.get('total_executions', 0),
                'success_rate': (stats.get('successful_executions', 0) / stats.get('total_executions', 1)) * 100 if stats.get('total_executions', 0) > 0 else 0,
                'avg_duration': stats.get('average_duration_seconds', 0)
            },
            'alerts': recent_alerts,
            'top_scripts': top_scripts,
            'recent_executions': recent_executions,
            'error_analysis': report.get('error_analysis', {})
        }
    
    def run_http_server(self):
        """Run the HTTP server in a separate thread"""
        handler = lambda *args, **kwargs: DashboardWebServer(
            *args, 
            dashboard_html=self.dashboard_html, 
            **kwargs
        )
        
        with HTTPServer(('', self.http_port), handler) as httpd:
            print(f"HTTP server running on http://localhost:{self.http_port}")
            httpd.serve_forever()
    
    async def run_websocket_server(self):
        """Run the WebSocket server"""
        # Store the event loop for alert callbacks
        self.ws_loop = asyncio.get_running_loop()
        
        # Start alert broadcaster
        broadcaster_task = asyncio.create_task(self.alert_broadcaster())
        
        # Start WebSocket server
        async with websockets.serve(self.websocket_handler, 'localhost', self.ws_port):
            print(f"WebSocket server running on ws://localhost:{self.ws_port}")
            await asyncio.Future()  # Run forever
    
    def run(self):
        """Run the dashboard servers"""
        # Start HTTP server in a thread
        http_thread = threading.Thread(target=self.run_http_server, daemon=True)
        http_thread.start()
        
        # Run WebSocket server in main thread
        try:
            asyncio.run(self.run_websocket_server())
        except KeyboardInterrupt:
            print("\nShutting down dashboard...")
            self.running = False
            self.metrics.shutdown()


def main():
    """Run the web dashboard"""
    import argparse
    
    parser = argparse.ArgumentParser(description='MetaClaude web monitoring dashboard')
    parser.add_argument('--http-port', type=int, default=8080,
                       help='HTTP server port (default: 8080)')
    parser.add_argument('--ws-port', type=int, default=8081,
                       help='WebSocket server port (default: 8081)')
    
    args = parser.parse_args()
    
    # Check if ports are available
    for port in [args.http_port, args.ws_port]:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('localhost', port))
        sock.close()
        if result == 0:
            print(f"Error: Port {port} is already in use")
            sys.exit(1)
    
    print(f"Starting MetaClaude Web Dashboard...")
    print(f"HTTP server: http://localhost:{args.http_port}")
    print(f"WebSocket server: ws://localhost:{args.ws_port}")
    print("\nPress Ctrl+C to stop\n")
    
    dashboard = WebDashboard(http_port=args.http_port, ws_port=args.ws_port)
    dashboard.run()


if __name__ == '__main__':
    main()