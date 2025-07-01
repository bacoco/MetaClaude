# MetaClaude Boundary Clarification System

## Overview

The Boundary Clarification System implements strict permission controls and tracking for agent operations in the UI Designer Claude orchestration system. It ensures agents operate within their designated scopes and provides visibility into cross-agent interactions.

## Components

### 1. Permission Matrix (`permission-matrix.json`)

Defines the complete permission structure for all agent types:

- **Agent Types**: orchestrator, design_analyst, style_guide_expert, ui_generator, ux_researcher, brand_strategist, accessibility_auditor
- **Permission Categories**: tools, agents, memory, files, workflows, boundaries
- **Cross-Agent Rules**: communication channels, delegation policies, resource sharing, conflict resolution

### 2. Permission Validation Hook (`validate-permissions.sh`)

Validates all agent operations against the permission matrix:

```bash
# Usage via environment variables
export METACLAUDE_AGENT_TYPE="ui_generator"
export METACLAUDE_OPERATION="tool:Write"
export METACLAUDE_RESOURCE="component.jsx"
./validate-permissions.sh

# Or direct command line
./validate-permissions.sh ui_generator tool:Write component.jsx
```

Exit codes:
- `0`: Operation allowed
- `2`: Operation blocked

### 3. Handoff Tracking System (`track-handoff.sh`)

Tracks all cross-agent communications and handoffs:

```bash
# Track a new handoff
./track-handoff.sh track design_analyst ui_generator "share_visual_analysis" "color_palette_data"

# Update handoff status
./track-handoff.sh update handoff_12345_6789 completed

# Generate summary report
./track-handoff.sh summary
```

### 4. Boundary Visualization (`visualize-boundaries.sh`)

Provides visual representations of agent boundaries and interactions:

```bash
# Show all visualizations
./visualize-boundaries.sh all

# Show agent boundary diagram
./visualize-boundaries.sh boundaries

# Show permissions for specific agent
./visualize-boundaries.sh agent ui_generator

# Show recent handoffs
./visualize-boundaries.sh handoffs

# Show boundary violations
./visualize-boundaries.sh violations

# Show agent interaction matrix
./visualize-boundaries.sh matrix
```

## Integration

### Hook Configuration

The system integrates with Claude Code through hooks defined in `.claude/settings.json`:

- **PreToolUse**: Validates tool usage permissions before execution
- **PostToolUse**: Tracks handoffs after tool completion
- **PreAgentSpawn**: Validates agent spawning permissions

### Environment Variables

The validation system uses these environment variables:

- `METACLAUDE_AGENT_TYPE`: The agent attempting the operation
- `METACLAUDE_OPERATION`: The operation type (tool:, file:, memory:, agent:, workflow:)
- `METACLAUDE_RESOURCE`: The resource being accessed

## Permission Model

### Operation Types

1. **Tool Operations** (`tool:ToolName`)
   - Example: `tool:Write`, `tool:Bash`
   - Wildcard support: `*` allows all tools

2. **File Operations** (`file:action`)
   - Actions: read, write, create, delete
   - Pattern support: `write:*.jsx`, `write:*.css`

3. **Memory Operations** (`memory:action`)
   - Actions: read, write, delete
   - Namespace support: `write:design_tokens`

4. **Agent Operations** (`agent:action`)
   - Actions: spawn, terminate, coordinate, communicate

5. **Workflow Operations** (`workflow:action`)
   - Actions: execute, modify, create, participate

### Delegation Rules

- **orchestrator_to_specialist**: Always allowed
- **specialist_to_specialist**: Requires orchestrator approval
- **specialist_to_orchestrator**: Request only (cannot command)

### Conflict Resolution

Priority order for veto powers:
1. accessibility_auditor (for accessibility issues)
2. orchestrator (for resource conflicts)
3. brand_strategist (for brand consistency)

## Logging

All operations are logged in JSONL format:

- **Permission Validations**: `.claude/logs/metaclaude/permission-validations.jsonl`
- **Handoffs**: `.claude/logs/metaclaude/handoffs.jsonl`

## Examples

### Example 1: UI Generator Creating Component

```bash
# UI Generator attempts to write a React component
METACLAUDE_AGENT_TYPE="ui_generator" \
METACLAUDE_OPERATION="file:write" \
METACLAUDE_RESOURCE="Button.jsx" \
./validate-permissions.sh
# Result: Allowed (ui_generator has write:*.jsx permission)
```

### Example 2: Design Analyst Attempting System Config Change

```bash
# Design Analyst attempts to modify system config
METACLAUDE_AGENT_TYPE="design_analyst" \
METACLAUDE_OPERATION="file:write" \
METACLAUDE_RESOURCE=".claude/settings.json" \
./validate-permissions.sh
# Result: Blocked (design_analyst has read-only file access)
```

### Example 3: Cross-Agent Handoff

```bash
# Style Guide Expert hands off design tokens to UI Generator
./track-handoff.sh track style_guide_expert ui_generator \
  "share_design_tokens" \
  '{"colors": {"primary": "#007bff"}, "spacing": {"unit": "8px"}}'
```

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Check the permission matrix for the agent's allowed operations
   - Verify the operation format (e.g., `tool:ToolName` not just `ToolName`)

2. **Handoff Not Tracked**
   - Ensure the log directory exists: `.claude/logs/metaclaude/`
   - Check file permissions on the log files

3. **Visualization Not Working**
   - Verify `jq` is installed (required for JSON parsing)
   - Check that log files exist and contain data

### Debug Mode

Enable verbose logging by setting:
```bash
export METACLAUDE_DEBUG=1
```

## Security Considerations

1. **Never modify the permission matrix** without careful review
2. **Monitor violation logs** regularly for suspicious patterns
3. **Audit handoff logs** to ensure proper agent coordination
4. **Review agent scopes** periodically to ensure least privilege

## Future Enhancements

- Real-time monitoring dashboard
- Machine learning for anomaly detection
- Automated permission recommendations
- Integration with external security tools