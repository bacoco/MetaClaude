# Tool Builder Integration Guide

## Overview

This guide covers how to integrate the Tool Builder specialist with other MetaClaude components and how other specialists can request and use dynamically generated tools.

## Integration Architecture

### Component Overview
```
┌─────────────────────────────────────────────────────────────┐
│                    MetaClaude Framework                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Other     │  │    Tool     │  │   Tool      │        │
│  │ Specialists │◄─┤   Builder   ├─►│  Registry   │        │
│  └─────────────┘  └──────┬──────┘  └─────────────┘        │
│                          │                                   │
│  ┌─────────────────────────────────────────────┐           │
│  │            Tool Builder Agents              │           │
│  │  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐  │           │
│  │  │Analyst│ │Design │ │ Code  │ │Validate│  │           │
│  │  └───────┘ └───────┘ └───────┘ └───────┘  │           │
│  └─────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## Integration Points

### 1. Tool Request Interface

#### Request Format
```python
from metaclaude.tool_builder import ToolBuilderClient

# Initialize client
tool_builder = ToolBuilderClient()

# Request a new tool
tool_request = {
    "name": "json_to_csv_converter",
    "type": "data_processor",
    "description": "Convert JSON data to CSV format with custom mapping",
    "inputs": [
        {
            "name": "json_data",
            "type": "dict|list",
            "description": "Input JSON data"
        },
        {
            "name": "mapping",
            "type": "dict",
            "description": "Field mapping configuration",
            "optional": True
        }
    ],
    "outputs": [
        {
            "name": "csv_content",
            "type": "string",
            "description": "Generated CSV content"
        }
    ],
    "requirements": {
        "performance": "Process 1MB JSON in <1 second",
        "error_handling": "Graceful handling of malformed JSON"
    }
}

# Submit request
response = tool_builder.request_tool(tool_request)
print(f"Tool request ID: {response.request_id}")
print(f"Estimated completion: {response.estimated_time}")
```

#### Async Request Handling
```python
import asyncio

async def request_tool_async():
    tool_builder = ToolBuilderClient()
    
    # Submit async request
    task = await tool_builder.request_tool_async(tool_request)
    
    # Wait for completion with progress updates
    async for progress in task.progress():
        print(f"Status: {progress.stage} - {progress.percentage}%")
    
    # Get the completed tool
    tool = await task.result()
    print(f"Tool created: {tool.name} v{tool.version}")
```

### 2. Tool Registry Integration

#### Accessing Generated Tools
```python
from metaclaude.tools import ToolRegistry

# Get tool registry instance
registry = ToolRegistry()

# Find a tool
tool = registry.find_tool("json_to_csv_converter")

# Use the tool
result = tool.execute(
    json_data={"name": "John", "age": 30},
    mapping={"name": "Name", "age": "Age"}
)
print(result.csv_content)
```

#### Tool Discovery
```python
# Search for tools by capability
data_processors = registry.search_tools(
    category="data_processor",
    tags=["json", "csv"]
)

# Get tool suggestions based on context
suggestions = registry.suggest_tools(
    task="Convert customer data from API response to spreadsheet"
)
```

### 3. Framework Integration

#### Update tool-usage-matrix.md
```python
# Automatic registration handled by Tool Integrator
# Manual registration if needed
from metaclaude.tool_builder.integrator import ToolIntegrator

integrator = ToolIntegrator()
integrator.register_tool(
    tool_path="/generated-tools/python/json_to_csv_converter",
    metadata={
        "category": "data_processing",
        "tags": ["json", "csv", "converter"],
        "performance": "high",
        "reliability": "production"
    }
)
```

#### Update tool-suggestion-patterns.md
```yaml
# Automatically added pattern
pattern:
  trigger: "convert.*json.*csv"
  tool: "json_to_csv_converter"
  confidence: 0.95
  context:
    - data_transformation
    - file_conversion
```

## Integration Patterns

### 1. Synchronous Tool Creation
```python
class DataProcessingSpecialist:
    def __init__(self):
        self.tool_builder = ToolBuilderClient()
        self.tool_cache = {}
    
    def process_data(self, data_format, target_format):
        # Check if tool exists
        tool_name = f"{data_format}_to_{target_format}_converter"
        
        if tool_name not in self.tool_cache:
            # Request tool creation
            tool = self.tool_builder.request_tool_sync({
                "name": tool_name,
                "type": "converter",
                # ... tool specification
            })
            self.tool_cache[tool_name] = tool
        
        # Use the tool
        return self.tool_cache[tool_name].execute(data)
```

### 2. Batch Tool Creation
```python
async def create_tool_suite():
    tool_builder = ToolBuilderClient()
    
    # Define multiple tools
    tool_specs = [
        {"name": "api_client", "type": "wrapper"},
        {"name": "data_validator", "type": "validator"},
        {"name": "report_generator", "type": "generator"}
    ]
    
    # Create tools in parallel
    tasks = [tool_builder.request_tool_async(spec) for spec in tool_specs]
    tools = await asyncio.gather(*tasks)
    
    return tools
```

### 3. Tool Enhancement Request
```python
# Request enhancement for existing tool
enhancement_request = {
    "tool_name": "json_to_csv_converter",
    "version": "1.0.0",
    "enhancement_type": "performance",
    "description": "Add streaming support for large files",
    "requirements": {
        "memory_limit": "100MB",
        "streaming": True
    }
}

enhanced_tool = tool_builder.enhance_tool(enhancement_request)
```

## Event Integration

### Tool Creation Events
```python
from metaclaude.events import EventBus

# Subscribe to tool creation events
event_bus = EventBus()

@event_bus.on("tool.created")
def on_tool_created(event):
    print(f"New tool available: {event.tool_name}")
    # Update local tool cache
    # Notify dependent systems

@event_bus.on("tool.validation.failed")
def on_validation_failed(event):
    print(f"Tool validation failed: {event.reason}")
    # Handle failure
```

### Progress Monitoring
```python
# Monitor tool creation progress
@event_bus.on("tool.progress")
def on_progress(event):
    stages = {
        "requirements": "Analyzing requirements",
        "design": "Designing architecture",
        "generation": "Generating code",
        "validation": "Testing and validating",
        "integration": "Integrating tool"
    }
    print(f"{stages.get(event.stage, event.stage)}: {event.percentage}%")
```

## API Reference

### ToolBuilderClient
```python
class ToolBuilderClient:
    def request_tool(self, specification: dict) -> ToolResponse:
        """Request synchronous tool creation."""
    
    async def request_tool_async(self, specification: dict) -> ToolTask:
        """Request asynchronous tool creation."""
    
    def enhance_tool(self, enhancement: dict) -> Tool:
        """Request tool enhancement."""
    
    def get_status(self, request_id: str) -> RequestStatus:
        """Get status of tool creation request."""
```

### ToolRegistry
```python
class ToolRegistry:
    def find_tool(self, name: str, version: str = None) -> Tool:
        """Find a specific tool by name and optional version."""
    
    def search_tools(self, **criteria) -> List[Tool]:
        """Search tools by various criteria."""
    
    def suggest_tools(self, task: str) -> List[ToolSuggestion]:
        """Get tool suggestions for a task."""
    
    def list_categories(self) -> List[str]:
        """List all tool categories."""
```

## Best Practices

### 1. Tool Request Guidelines
- Provide clear, specific requirements
- Include example inputs and outputs
- Specify performance requirements
- Define error handling needs

### 2. Integration Patterns
- Cache created tools for reuse
- Handle tool creation failures gracefully
- Use async requests for non-blocking operation
- Monitor tool usage for optimization opportunities

### 3. Error Handling
```python
try:
    tool = tool_builder.request_tool(spec)
except ToolCreationError as e:
    if e.error_type == "requirements_unclear":
        # Clarify requirements and retry
        spec = clarify_requirements(spec, e.suggestions)
        tool = tool_builder.request_tool(spec)
    elif e.error_type == "validation_failed":
        # Handle validation failure
        log.error(f"Tool validation failed: {e.details}")
    else:
        raise
```

## Examples

### Example 1: API Wrapper Tool
```python
# Request an API wrapper tool
api_tool_spec = {
    "name": "weather_api_client",
    "type": "api_wrapper",
    "description": "Client for OpenWeatherMap API",
    "config": {
        "base_url": "https://api.openweathermap.org/data/2.5",
        "auth_type": "api_key",
        "rate_limit": "60/minute"
    },
    "methods": [
        {
            "name": "get_current_weather",
            "endpoint": "/weather",
            "params": ["city", "country_code"]
        }
    ]
}

tool = tool_builder.request_tool(api_tool_spec)
```

### Example 2: Data Processor Tool
```python
# Request a data processing tool
processor_spec = {
    "name": "log_analyzer",
    "type": "data_processor",
    "description": "Analyze application logs for patterns",
    "inputs": [
        {
            "name": "log_file",
            "type": "file_path",
            "description": "Path to log file"
        }
    ],
    "processing": {
        "patterns": [
            "error_detection",
            "performance_analysis",
            "usage_statistics"
        ]
    },
    "outputs": [
        {
            "name": "analysis_report",
            "type": "dict",
            "schema": {
                "errors": "list",
                "performance_metrics": "dict",
                "usage_stats": "dict"
            }
        }
    ]
}

tool = tool_builder.request_tool(processor_spec)
```

## Troubleshooting

### Common Integration Issues

1. **Tool Not Found**
   - Verify tool registration completed
   - Check tool name and version
   - Ensure registry is synchronized

2. **Performance Issues**
   - Use async requests for better concurrency
   - Implement tool result caching
   - Monitor resource usage

3. **Version Conflicts**
   - Use semantic versioning
   - Specify version requirements explicitly
   - Test with multiple versions

## Support

For integration support:
- Check the [API Documentation](api-reference.md)
- Review [Examples](../examples/)
- Contact the Tool Builder team