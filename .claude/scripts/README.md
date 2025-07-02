# TES Orchestration Scripts

This directory contains advanced orchestration tools for the Tool Execution Service (TES) that enable sophisticated workflow control, output mapping, and parallel execution.

## 🚀 New Features

### 1. **Advanced Output Mapping** (`core/output-mapper.py`)
- JSONPath expressions for nested data extraction
- Pipeline transformations (filter, map, reduce)
- Type conversions and validation
- Backward compatible with simple mappings
- **Minimal version available** (`core/output-mapper-minimal.py`) - works without dependencies!

### 2. **Workflow Controller** (`core/workflow-controller.py`)
- Conditional branching (IF-THEN-ELSE)
- Parallel task execution
- Tool composition and output piping
- Retry logic with backoff strategies
- State persistence for workflow resumption

### 3. **Ready-to-Use Examples**
- `examples/advanced-workflow.yaml` - Comprehensive workflow demonstrating all features
- `examples/simple-to-advanced.yaml` - Migration path from simple to advanced workflows
- `examples/orchestration_demo.py` - Python demo with practical examples

## 📖 Quick Start

### Optional Dependencies

The orchestration system works with minimal dependencies, but for full features:

```bash
# Install all optional dependencies
pip install -r requirements.txt

# Or install individually
pip install jsonpath-ng  # For advanced JSONPath support
pip install pyyaml       # For YAML workflow files
pip install aiofiles     # For async file operations
```

**Note**: Basic functionality works without these dependencies using the minimal implementations.

### Test the Installation
```bash
# Test with minimal version (no dependencies needed)
python3 core/output_mapper_minimal.py

# Test full version (requires dependencies)
python3 test_orchestration.py
```

### Run the Demo
```bash
python examples/orchestration_demo.py
```

### Create Your First Workflow

1. **Simple Task with Output Mapping**
```yaml
- type: task
  tool: my_tool
  output_mapping:
    - source: "$.data.result"
      target: "my_variable"
      transform: "string"
```

2. **Conditional Execution**
```yaml
- type: conditional
  condition: "variables['score'] > 90"
  then:
    - type: task
      tool: high_score_handler
  else:
    - type: task
      tool: normal_handler
```

3. **Parallel Execution**
```yaml
- type: parallel
  tasks:
    - id: task1
      tool: processor1
    - id: task2
      tool: processor2
```

## 📚 Documentation

- **[ORCHESTRATION-GUIDE.md](ORCHESTRATION-GUIDE.md)** - Complete guide with patterns and best practices
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Quick syntax reference
- **[core/](core/)** - Core implementation modules
- **[examples/](examples/)** - Working examples

## 🔧 Core Components

### Output Mapper
Maps complex tool outputs to workflow variables:
- JSONPath support: `$.users[?(@.active)].name`
- Transformations: `filter:score > 80|map:name|join:', '`
- Type safety with defaults and validation

### Workflow Controller
Manages workflow execution with:
- Task dependencies and ordering
- Error handling and recovery
- State management for long-running workflows
- Integration with TES tools

## 🎯 Common Use Cases

1. **Data Processing Pipeline**
   - Fetch data from multiple sources in parallel
   - Transform and filter based on conditions
   - Store results with error recovery

2. **Conditional Deployment**
   - Run tests and quality checks
   - Deploy only if all checks pass
   - Rollback on failure

3. **Batch Operations**
   - Process items in parallel
   - Aggregate results
   - Generate reports

## ⚡ Performance Features

- Parallel execution with configurable worker limits
- Efficient state persistence
- Minimal overhead for simple workflows
- Backward compatibility ensures no breaking changes

## 🔄 Integration with TES

The orchestration system seamlessly integrates with existing TES tools:

```python
controller.register_tool('TodoWrite', tes_todo_write)
controller.register_tool('Task', tes_task)
controller.register_tool('Memory', tes_memory)
```

## 🐛 Troubleshooting

1. **Import Errors**: Ensure you're in the correct directory or add to Python path
2. **JSONPath Issues**: Test expressions with online JSONPath testers
3. **State Persistence**: Check `.workflow_state/` directory permissions
4. **Debug Mode**: Set `LOG_LEVEL=DEBUG` for detailed logging

---

For questions or issues, refer to the comprehensive [ORCHESTRATION-GUIDE.md](ORCHESTRATION-GUIDE.md) or check the examples directory.