# Advanced TES Orchestration Guide

## Overview

The Advanced TES Orchestration system provides powerful workflow control capabilities including:

- **Complex Output Mapping**: JSONPath expressions, transformations, and pipelines
- **Conditional Branching**: IF-THEN-ELSE logic with complex conditions
- **Parallel Execution**: Run multiple tools concurrently with dependency management
- **Tool Composition**: Chain tools together, piping outputs between them
- **Retry Logic**: Automatic retry with configurable backoff strategies
- **State Management**: Persist and resume workflows
- **Error Handling**: Graceful error recovery and fallback strategies

## Core Components

### 1. Output Mapper (`output-mapper.py`)

The Output Mapper handles complex data extraction and transformation from tool outputs.

#### Features

- **JSONPath Support**: Extract nested data using JSONPath expressions
- **Type Conversion**: Convert between string, number, boolean, array, and object types
- **Array Operations**: Filter, map, and reduce array data
- **Pipeline Transformations**: Chain multiple transformations together
- **Regex Extraction**: Extract data using regular expressions
- **Default Values**: Provide fallbacks for missing data

#### Basic Mapping Syntax

```yaml
output_mapping:
  # Simple extraction
  - source: "$.data.value"
    target: "my_variable"
    
  # With transformation
  - source: "$.users"
    target: "active_users"
    transform: "filter:item['active'] == true"
    
  # With default
  - source: "$.optional_field"
    target: "my_field"
    default: "default_value"
    required: false
```

#### Transformation Types

1. **Type Conversions**:
   - `string`: Convert to string
   - `number`: Convert to number (int or float)
   - `boolean`: Convert to boolean
   - `array`: Convert to array
   - `object`: Convert to object/dictionary

2. **Array Operations**:
   - `filter:<condition>`: Filter array elements
   - `map:<expression>`: Transform array elements
   - `reduce:<operation>`: Reduce array to single value

3. **String Operations**:
   - `split:<delimiter>`: Split string into array
   - `join:<delimiter>`: Join array into string
   - `regex:<pattern>`: Extract using regex

4. **Object Operations**:
   - `keys`: Get object keys
   - `values`: Get object values

#### Pipeline Transformations

Chain multiple transformations using the pipe (`|`) operator:

```yaml
transform: "filter:item['score'] > 80|map:item['name']|join:', '"
```

#### JSONPath Examples

```yaml
# Extract all user names
source: "$.users[*].name"

# Extract users with specific condition
source: "$.users[?(@.age > 18)].email"

# Extract nested array
source: "$.data.results[0].items[*]"

# Extract with array index
source: "$.records[2].value"
```

### 2. Workflow Controller (`workflow-controller.py`)

The Workflow Controller manages complex workflow execution with advanced control flow.

#### Execution Modes

1. **Sequential**: Execute tasks one after another
2. **Parallel**: Execute multiple tasks concurrently
3. **Conditional**: Branch based on conditions
4. **Loop**: Iterate over collections or conditions
5. **Compose**: Chain tools with output piping

#### Task Dependencies

```yaml
- type: task
  id: process_data
  tool: processor
  depends_on:
    - fetch_data
    - validate_input
```

#### Conditional Execution

##### Simple Conditions

```yaml
condition: "variables['score'] > 90"
```

##### Complex Conditions

```yaml
condition:
  and:
    - greater: ["$score", 90]
    - exists: "user_data"
    - or:
        - equals: ["$status", "active"]
        - equals: ["$override", true]
```

##### Condition Operators

- `and`: All conditions must be true
- `or`: Any condition must be true
- `not`: Negate a condition
- `equals`: Check equality
- `greater`: Greater than comparison
- `less`: Less than comparison
- `in`: Check if value in collection
- `exists`: Check if variable exists

#### Parallel Execution

```yaml
- type: parallel
  max_workers: 5
  tasks:
    - id: task1
      tool: tool1
    - id: task2
      tool: tool2
    - id: task3
      tool: tool3
```

#### Loops

##### For Loop

```yaml
- type: loop
  loop_type: for
  collection: "$items"
  variable: "item"
  body:
    - type: task
      tool: process_item
      parameters:
        item: "$item"
```

##### While Loop

```yaml
- type: loop
  loop_type: while
  condition: "variables['counter'] < 10"
  max_iterations: 100  # Safety limit
  body:
    - type: task
      tool: increment_counter
```

#### Tool Composition

Chain tools together, automatically piping outputs:

```yaml
- type: compose
  tasks:
    - id: fetch
      tool: fetcher
    - id: transform
      tool: transformer
      # Receives _piped_input from previous tool
    - id: save
      tool: saver
      # Receives _piped_input from transformer
```

#### Retry Logic

```yaml
- type: task
  tool: unreliable_api
  retry:
    max_attempts: 3
    delay: 2  # seconds
    backoff: exponential  # or linear
  continue_on_error: false
```

### 3. State Management

Workflows can be paused and resumed:

```yaml
id: long_running_workflow
resume: true  # Resume from saved state if exists
```

State includes:
- Current variables
- Task results
- Execution path
- Timestamps

## Best Practices

### 1. Output Mapping Design

**DO:**
- Use specific JSONPath expressions
- Provide sensible defaults
- Validate data types
- Handle missing data gracefully

**DON'T:**
- Use overly complex transformations
- Assume data structure without validation
- Ignore error cases

### 2. Conditional Logic

**DO:**
- Keep conditions simple and readable
- Use meaningful variable names
- Test edge cases
- Provide else branches for important logic

**DON'T:**
- Nest conditions too deeply
- Use complex expressions in strings
- Forget null/undefined checks

### 3. Parallel Execution

**DO:**
- Identify truly independent tasks
- Set reasonable worker limits
- Handle partial failures
- Use depends_on for ordering

**DON'T:**
- Parallelize dependent tasks
- Overwhelm external services
- Ignore resource constraints

### 4. Error Handling

**DO:**
- Use continue_on_error for non-critical tasks
- Implement retry for transient failures
- Log errors comprehensively
- Provide fallback strategies

**DON'T:**
- Silently swallow errors
- Retry indefinitely
- Ignore error patterns

### 5. Performance Optimization

**DO:**
- Use parallel execution for independent tasks
- Cache intermediate results
- Minimize data transformations
- Profile workflow execution

**DON'T:**
- Over-parallelize small tasks
- Transform data unnecessarily
- Create deep dependency chains

## Advanced Patterns

### 1. Fan-out/Fan-in Pattern

Process items in parallel then aggregate results:

```yaml
# Fan-out
- type: loop
  collection: "$items"
  variable: "item"
  body:
    - type: task
      id: "process_${item.id}"
      tool: processor
      parameters:
        item: "$item"
      output_mapping:
        - source: "$.result"
          target: "results.${item.id}"

# Fan-in
- type: task
  tool: aggregator
  parameters:
    results: "$results"
```

### 2. Circuit Breaker Pattern

Prevent cascading failures:

```yaml
- type: conditional
  condition: "variables['failure_count'] < 3"
  then:
    - type: task
      tool: external_api
      continue_on_error: true
      output_mapping:
        - source: "$.success"
          target: "api_success"
  else:
    - type: task
      tool: use_cache
      parameters:
        reason: "Circuit breaker open"
```

### 3. Saga Pattern

Implement compensating transactions:

```yaml
steps:
  - type: task
    id: create_order
    tool: order_service
    
  - type: task
    id: charge_payment
    tool: payment_service
    
  - type: conditional
    condition: "not variables['payment_success']"
    then:
      # Compensate
      - type: task
        tool: cancel_order
        parameters:
          order_id: "$order_id"
```

### 4. Dynamic Workflow Generation

Generate workflow steps based on data:

```yaml
- type: task
  id: get_tasks
  tool: task_generator
  output_mapping:
    - source: "$.tasks"
      target: "dynamic_tasks"

- type: loop
  collection: "$dynamic_tasks"
  variable: "task_config"
  body:
    - type: task
      tool: "${task_config.tool}"
      parameters: "${task_config.parameters}"
```

## Integration with TES

### 1. Tool Registration

```python
from workflow_controller import WorkflowController

controller = WorkflowController()

# Register TES tools
controller.register_tool('TodoWrite', tes_todo_write)
controller.register_tool('Task', tes_task)
controller.register_tool('Memory', tes_memory)
```

### 2. Workflow Execution

```python
import asyncio
import yaml

# Load workflow
with open('workflow.yaml', 'r') as f:
    workflow = yaml.safe_load(f)

# Execute
async def run():
    state = await controller.execute_workflow(
        workflow,
        initial_variables={'api_key': 'xxx'}
    )
    return state

result = asyncio.run(run())
```

### 3. Monitoring

```python
# Get workflow status
status = controller.get_workflow_status('workflow_id')
print(f"Status: {status['status']}")
print(f"Progress: {status['successful_tasks']}/{status['task_count']}")
```

## Backward Compatibility

The system maintains backward compatibility with simple output mappings:

```yaml
# Old style (still supported)
output_mapping:
  result: "my_variable"

# Automatically converted to:
output_mapping:
  - source: "$.result"
    target: "my_variable"
```

## Troubleshooting

### Common Issues

1. **JSONPath not finding data**
   - Check path syntax
   - Verify data structure
   - Use online JSONPath testers

2. **Conditions always false**
   - Check variable names
   - Verify data types
   - Add debug logging

3. **Parallel tasks not running**
   - Check dependencies
   - Verify worker limits
   - Look for blocking operations

4. **State not persisting**
   - Check state directory permissions
   - Verify workflow ID uniqueness
   - Clear old state files

### Debug Mode

Enable debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Performance Profiling

```yaml
metadata:
  profiling: true
  metrics:
    - execution_time
    - memory_usage
    - task_duration
```

## Future Enhancements

1. **Visual Workflow Designer**: GUI for creating workflows
2. **Workflow Templates**: Reusable workflow patterns
3. **Event-Driven Execution**: Trigger workflows on events
4. **Distributed Execution**: Run across multiple machines
5. **Advanced Analytics**: Workflow performance insights