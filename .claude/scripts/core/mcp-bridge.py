#!/usr/bin/env python3
"""
MCP Bridge for Global Script Registry
Bridges between TES (Tool Execution System) and MCP (Model Context Protocol) tools
"""

import json
import subprocess
import sys
import os
import logging
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass
from enum import Enum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('mcp-bridge')


class ToolType(Enum):
    """Enumeration of tool types"""
    MCP = "mcp"
    TES = "tes"
    HYBRID = "hybrid"


@dataclass
class ToolRegistration:
    """Represents a registered tool"""
    name: str
    type: ToolType
    mcp_server: Optional[str] = None
    tes_path: Optional[str] = None
    description: str = ""
    parameters: Dict[str, Any] = None


class MCPBridge:
    """Main bridge class between TES and MCP"""
    
    def __init__(self, registry_path: str = "~/.claude/registry.json"):
        self.registry_path = os.path.expanduser(registry_path)
        self.registry: Dict[str, ToolRegistration] = {}
        self.load_registry()
        
    def load_registry(self) -> None:
        """Load tool registry from disk"""
        if os.path.exists(self.registry_path):
            try:
                with open(self.registry_path, 'r') as f:
                    data = json.load(f)
                    for name, tool_data in data.items():
                        self.registry[name] = ToolRegistration(
                            name=name,
                            type=ToolType(tool_data.get('type', 'tes')),
                            mcp_server=tool_data.get('mcp_server'),
                            tes_path=tool_data.get('tes_path'),
                            description=tool_data.get('description', ''),
                            parameters=tool_data.get('parameters', {})
                        )
                logger.info(f"Loaded {len(self.registry)} tools from registry")
            except Exception as e:
                logger.error(f"Failed to load registry: {e}")
                
    def save_registry(self) -> None:
        """Save tool registry to disk"""
        os.makedirs(os.path.dirname(self.registry_path), exist_ok=True)
        try:
            data = {}
            for name, tool in self.registry.items():
                data[name] = {
                    'type': tool.type.value,
                    'mcp_server': tool.mcp_server,
                    'tes_path': tool.tes_path,
                    'description': tool.description,
                    'parameters': tool.parameters or {}
                }
            with open(self.registry_path, 'w') as f:
                json.dump(data, f, indent=2)
            logger.info("Registry saved successfully")
        except Exception as e:
            logger.error(f"Failed to save registry: {e}")
    
    def register_mcp_tool(self, name: str, server: str, description: str = "") -> bool:
        """Register an MCP tool in the global registry"""
        try:
            # Verify MCP server exists
            result = subprocess.run(
                ['npx', '@modelcontextprotocol/cli', 'list'],
                capture_output=True,
                text=True
            )
            
            if server not in result.stdout:
                logger.error(f"MCP server '{server}' not found")
                return False
                
            # Get tool info from MCP
            tool_info = self._get_mcp_tool_info(server, name)
            
            self.registry[name] = ToolRegistration(
                name=name,
                type=ToolType.MCP,
                mcp_server=server,
                description=description or tool_info.get('description', ''),
                parameters=tool_info.get('parameters', {})
            )
            
            self.save_registry()
            logger.info(f"Registered MCP tool: {name} from server: {server}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to register MCP tool: {e}")
            return False
    
    def _get_mcp_tool_info(self, server: str, tool: str) -> Dict[str, Any]:
        """Get detailed information about an MCP tool"""
        try:
            result = subprocess.run(
                ['npx', '@modelcontextprotocol/cli', 'describe', server, tool],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                return json.loads(result.stdout)
            else:
                logger.warning(f"Could not get info for tool {tool} on server {server}")
                return {}
                
        except Exception as e:
            logger.error(f"Error getting tool info: {e}")
            return {}
    
    def execute_tool(self, name: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a tool (MCP or TES) with unified interface"""
        if name not in self.registry:
            return {
                'success': False,
                'error': f"Tool '{name}' not found in registry"
            }
            
        tool = self.registry[name]
        
        try:
            if tool.type == ToolType.MCP:
                return self._execute_mcp_tool(tool, parameters)
            elif tool.type == ToolType.TES:
                return self._execute_tes_tool(tool, parameters)
            else:
                return {
                    'success': False,
                    'error': f"Unknown tool type: {tool.type}"
                }
                
        except Exception as e:
            logger.error(f"Tool execution failed: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def _execute_mcp_tool(self, tool: ToolRegistration, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute an MCP tool"""
        cmd = [
            'npx', '@modelcontextprotocol/cli', 
            'call', tool.mcp_server, tool.name,
            '--params', json.dumps(parameters)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            try:
                output = json.loads(result.stdout)
                return {
                    'success': True,
                    'output': output,
                    'format': 'mcp'
                }
            except json.JSONDecodeError:
                return {
                    'success': True,
                    'output': result.stdout,
                    'format': 'text'
                }
        else:
            return {
                'success': False,
                'error': result.stderr
            }
    
    def _execute_tes_tool(self, tool: ToolRegistration, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a TES tool"""
        if not tool.tes_path or not os.path.exists(tool.tes_path):
            return {
                'success': False,
                'error': f"TES tool path not found: {tool.tes_path}"
            }
            
        # Prepare environment with parameters
        env = os.environ.copy()
        for key, value in parameters.items():
            env[f'TES_PARAM_{key.upper()}'] = str(value)
            
        result = subprocess.run(
            [tool.tes_path],
            capture_output=True,
            text=True,
            env=env
        )
        
        return {
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr if result.returncode != 0 else None,
            'format': 'tes'
        }
    
    def map_output_to_tes(self, output: Dict[str, Any]) -> str:
        """Map MCP tool output to TES format"""
        if output.get('format') == 'tes':
            return output.get('output', '')
            
        # Convert MCP structured output to TES text format
        if output.get('format') == 'mcp':
            mcp_output = output.get('output', {})
            lines = []
            
            # Add status line
            lines.append(f"STATUS: {'SUCCESS' if output.get('success') else 'FAILED'}")
            
            # Add structured data
            if isinstance(mcp_output, dict):
                for key, value in mcp_output.items():
                    lines.append(f"{key.upper()}: {value}")
            else:
                lines.append(f"OUTPUT: {mcp_output}")
                
            return '\n'.join(lines)
            
        return output.get('output', '')
    
    def list_tools(self, tool_type: Optional[ToolType] = None) -> List[Dict[str, Any]]:
        """List all registered tools"""
        tools = []
        for name, tool in self.registry.items():
            if tool_type is None or tool.type == tool_type:
                tools.append({
                    'name': name,
                    'type': tool.type.value,
                    'server': tool.mcp_server,
                    'path': tool.tes_path,
                    'description': tool.description
                })
        return tools


def main():
    """Main entry point for CLI usage"""
    import argparse
    
    parser = argparse.ArgumentParser(description='MCP Bridge for Global Script Registry')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Register command
    register_parser = subparsers.add_parser('register', help='Register a new tool')
    register_parser.add_argument('name', help='Tool name')
    register_parser.add_argument('--mcp-server', help='MCP server name')
    register_parser.add_argument('--tes-path', help='TES tool path')
    register_parser.add_argument('--description', help='Tool description')
    
    # Execute command
    exec_parser = subparsers.add_parser('execute', help='Execute a tool')
    exec_parser.add_argument('name', help='Tool name')
    exec_parser.add_argument('--params', type=json.loads, default={}, help='Parameters as JSON')
    exec_parser.add_argument('--tes-format', action='store_true', help='Output in TES format')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List tools')
    list_parser.add_argument('--type', choices=['mcp', 'tes', 'hybrid'], help='Filter by type')
    
    args = parser.parse_args()
    
    bridge = MCPBridge()
    
    if args.command == 'register':
        if args.mcp_server:
            success = bridge.register_mcp_tool(
                args.name, 
                args.mcp_server,
                args.description or ""
            )
        elif args.tes_path:
            # Register TES tool
            bridge.registry[args.name] = ToolRegistration(
                name=args.name,
                type=ToolType.TES,
                tes_path=args.tes_path,
                description=args.description or ""
            )
            bridge.save_registry()
            success = True
        else:
            print("Error: Must specify either --mcp-server or --tes-path")
            sys.exit(1)
            
        sys.exit(0 if success else 1)
        
    elif args.command == 'execute':
        result = bridge.execute_tool(args.name, args.params)
        
        if args.tes_format:
            print(bridge.map_output_to_tes(result))
        else:
            print(json.dumps(result, indent=2))
            
        sys.exit(0 if result.get('success') else 1)
        
    elif args.command == 'list':
        tool_type = ToolType(args.type) if args.type else None
        tools = bridge.list_tools(tool_type)
        
        for tool in tools:
            print(f"{tool['name']} ({tool['type']})")
            if tool['description']:
                print(f"  {tool['description']}")
            if tool['server']:
                print(f"  MCP Server: {tool['server']}")
            if tool['path']:
                print(f"  TES Path: {tool['path']}")
            print()
            
    else:
        parser.print_help()


if __name__ == '__main__':
    main()