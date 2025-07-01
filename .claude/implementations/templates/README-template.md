# [Specialist Name] Specialist

## Overview

[Brief description of what this specialist does and its primary value proposition]

### Key Features
- 🎯 **[Feature 1]**: [Brief description]
- 🔧 **[Feature 2]**: [Brief description]
- 📊 **[Feature 3]**: [Brief description]
- 🤖 **[Feature 4]**: [Brief description]

### Use Cases
1. **[Use Case 1]**: [When and why to use this specialist]
2. **[Use Case 2]**: [When and why to use this specialist]
3. **[Use Case 3]**: [When and why to use this specialist]

## Architecture

### Core Components

#### Specialized Agents
1. **[Agent Name]** (`agents/[agent-file].md`)
   - Role: [Brief description]
   - Key capabilities: [List main capabilities]

2. **[Agent Name]** (`agents/[agent-file].md`)
   - Role: [Brief description]
   - Key capabilities: [List main capabilities]

3. **[Agent Name]** (`agents/[agent-file].md`)
   - Role: [Brief description]
   - Key capabilities: [List main capabilities]

#### Workflows
1. **[Workflow Name]** (`workflows/[workflow-file].md`)
   - Purpose: [What this workflow accomplishes]
   - Duration: [Typical time range]
   - Complexity: [Simple/Moderate/Complex]

2. **[Workflow Name]** (`workflows/[workflow-file].md`)
   - Purpose: [What this workflow accomplishes]
   - Duration: [Typical time range]
   - Complexity: [Simple/Moderate/Complex]

### Integration with MetaClaude Core

#### Cognitive Patterns
- **[Pattern Name]**: [How this specialist uses it]
- **[Pattern Name]**: [How this specialist uses it]

#### Memory Systems
- **Episodic Memory**: [What experiences are stored]
- **Semantic Memory**: [What knowledge is maintained]
- **Working Memory**: [What temporary data is tracked]

#### Tool Ecosystem
- **Required Tools**: [List of essential tools]
- **Optional Tools**: [List of beneficial tools]
- **Custom Tools**: [Tools this specialist might request from Tool Builder]

## Quick Start

### Prerequisites
```bash
# Ensure MetaClaude core is properly configured
cd /path/to/.claude
cat CLAUDE.md  # Verify configuration

# Check required dependencies
[dependency check commands]
```

### Basic Usage

#### Example 1: [Common Task]
```bash
# Command or interaction pattern
[example command or usage]

# Expected output
[example output]
```

#### Example 2: [Another Common Task]
```bash
# Command or interaction pattern
[example command or usage]

# Expected output
[example output]
```

### Advanced Usage

#### Custom Configuration
```json
{
  "[specialist-name]": {
    "setting1": "value1",
    "setting2": "value2",
    "advanced": {
      "option1": true,
      "option2": "custom-value"
    }
  }
}
```

#### Workflow Composition
```yaml
# Example of combining multiple workflows
combined_workflow:
  - workflow: [workflow-1]
    params:
      param1: value1
  - workflow: [workflow-2]
    depends_on: [workflow-1]
  - parallel:
    - workflow: [workflow-3]
    - workflow: [workflow-4]
```

## Commands and Operations

### Core Commands
| Command | Description | Example |
|---------|-------------|---------|
| `[command-1]` | [What it does] | `[example usage]` |
| `[command-2]` | [What it does] | `[example usage]` |
| `[command-3]` | [What it does] | `[example usage]` |

### Workflow Triggers
| Trigger | Workflow | Description |
|---------|----------|-------------|
| `[trigger-1]` | [Workflow Name] | [When this triggers] |
| `[trigger-2]` | [Workflow Name] | [When this triggers] |

## Integration Examples

### With Other Specialists

#### [Other Specialist Name]
```python
# Example integration code or pattern
[integration example]
```

#### Tool Builder Integration
```python
# Requesting a custom tool
tool_request = {
    "name": "[tool-name]",
    "purpose": "[what the tool does]",
    "inputs": ["[input1]", "[input2]"],
    "output": "[expected output format]"
}
```

### With External Systems

#### [System Name]
- **Integration Method**: [API/File/Database/etc.]
- **Data Flow**: [How data moves between systems]
- **Example**: [Brief code or configuration example]

## Best Practices

### Do's
- ✅ **[Best Practice 1]**: [Why it's important]
- ✅ **[Best Practice 2]**: [Why it's important]
- ✅ **[Best Practice 3]**: [Why it's important]

### Don'ts
- ❌ **[Anti-pattern 1]**: [Why to avoid it]
- ❌ **[Anti-pattern 2]**: [Why to avoid it]
- ❌ **[Anti-pattern 3]**: [Why to avoid it]

### Performance Tips
1. **[Tip 1]**: [How to optimize performance]
2. **[Tip 2]**: [How to optimize performance]
3. **[Tip 3]**: [How to optimize performance]

## Troubleshooting

### Common Issues

#### Issue: [Problem Description]
- **Symptoms**: [What users observe]
- **Cause**: [Root cause]
- **Solution**: [Step-by-step fix]

#### Issue: [Problem Description]
- **Symptoms**: [What users observe]
- **Cause**: [Root cause]
- **Solution**: [Step-by-step fix]

### Debug Mode
```bash
# Enable debug logging
export [SPECIALIST_NAME]_DEBUG=true

# Check specialist status
[status command]

# View recent operations
[log command]
```

## Development

### Extending the Specialist

#### Adding New Agents
1. Create agent definition in `agents/`
2. Update orchestrator configuration
3. Add integration tests
4. Document in this README

#### Creating New Workflows
1. Define workflow in `workflows/`
2. Map agent interactions
3. Add example scenarios
4. Update command registry

### Testing
```bash
# Run unit tests
[test command]

# Run integration tests
[test command]

# Run example scenarios
[test command]
```

### Contributing
1. Review existing patterns in `docs/`
2. Follow MetaClaude cognitive patterns
3. Ensure comprehensive documentation
4. Add examples for new features

## Resources

### Documentation
- **Setup Guide**: [`docs/setup-guide.md`](docs/setup-guide.md)
- **API Reference**: [`docs/api-reference.md`](docs/api-reference.md)
- **Examples**: [`examples/`](examples/)

### Related Specialists
- **[Related Specialist 1]**: [How they work together]
- **[Related Specialist 2]**: [How they work together]

### External Resources
- [Resource 1]: [Description and link]
- [Resource 2]: [Description and link]

## Roadmap

### Current Version: v[X.Y.Z]
- ✅ [Completed feature 1]
- ✅ [Completed feature 2]
- ✅ [Completed feature 3]

### Planned Features
- 🚧 **v[X.Y+1.Z]**: [Planned feature 1]
- 📋 **v[X+1.0.0]**: [Major planned feature]
- 🔮 **Future**: [Long-term vision]

## License and Attribution

This specialist is part of the MetaClaude framework. See the main [LICENSE](../../LICENSE) file for details.

### Acknowledgments
- [Acknowledgment 1]
- [Acknowledgment 2]

---

*[Specialist Name] v[X.Y.Z] | Part of MetaClaude Cognitive Framework*