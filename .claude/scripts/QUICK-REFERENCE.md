# TES Orchestration Quick Reference

## Output Mapping

### Basic Mapping
```yaml
output_mapping:
  - source: "$.data.value"      # JSONPath expression
    target: "my_variable"       # Variable name
    transform: "string"         # Optional transformation
    default: "none"            # Optional default value
    required: false            # Optional requirement flag
```

### Common Transformations
- **Type conversions**: `string`, `number`, `boolean`, `array`, `object`
- **Array operations**: 
  - `filter:condition` - Filter array elements
  - `map:expression` - Transform elements
  - `reduce:operation` - Reduce to single value
- **String operations**:
  - `split:delimiter` - Split into array
  - `join:delimiter` - Join array to string
  - `regex:pattern` - Extract with regex
- **Pipelines**: `filter:x > 5|map:x * 2|reduce:sum`

### JSONPath Examples
- `$.users[*].name` - All user names
- `$.users[?(@.age > 18)]` - Filtered users
- `$.data.items[0]` - First item
- `$.response..id` - All nested IDs

## Workflow Control

### Task Types
```yaml
# Simple task
- type: task
  id: my_task
  tool: tool_name
  parameters: {}

# Parallel execution
- type: parallel
  tasks: [...]

# Conditional
- type: conditional
  condition: expression
  then: [...]
  else: [...]

# Loop
- type: loop
  loop_type: for|while
  collection: "$items"
  body: [...]

# Composition
- type: compose
  tasks: [...]  # Output piped between tasks
```

### Conditions
```yaml
# Simple
condition: "variables['score'] > 90"

# Complex
condition:
  and:
    - greater: ["$score", 90]
    - exists: "user_data"
  or:
    - equals: ["$status", "active"]
```

### Dependencies & Retry
```yaml
depends_on: [task1, task2]
retry:
  max_attempts: 3
  delay: 2
  backoff: exponential
continue_on_error: true
```

## Variable References

- `$variable_name` - Simple variable
- `${variable.property}` - Nested property
- `${expression}` - Template expression

## Quick Examples

### Extract and Transform
```yaml
output_mapping:
  - source: "$.users"
    target: "active_users"
    transform: "filter:item['active'] == true|map:item['name']"
```

### Conditional Processing
```yaml
- type: conditional
  condition:
    greater: ["${users.length}", 10]
  then:
    - type: parallel
      tasks: [batch_process]
  else:
    - type: task
      id: simple_process
```

### Error Handling
```yaml
- type: task
  tool: unreliable_api
  retry:
    max_attempts: 3
  continue_on_error: true
```

### Loop with Mapping
```yaml
- type: loop
  collection: "$items"
  variable: "item"
  body:
    - type: task
      parameters:
        data: "$item"
      output_mapping:
        - source: "$.result"
          target: "results.${item.id}"
```

## Backward Compatibility

Old style (still works):
```yaml
output_mapping:
  result: "my_var"
```

Automatically converted to:
```yaml
output_mapping:
  - source: "$.result"
    target: "my_var"
```

## Debug Tips

1. **Enable logging**: Set environment variable `LOG_LEVEL=DEBUG`
2. **Test mappings**: Use `orchestration_demo.py` to test
3. **Validate JSONPath**: Use online JSONPath testers
4. **Check state**: Workflows save state in `.workflow_state/`