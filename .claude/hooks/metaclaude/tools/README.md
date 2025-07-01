# MetaClaude Tool Usage Excellence

Phase 6 implementation of the MetaClaude hooks system, providing comprehensive tool usage tracking, validation, and continuous improvement capabilities.

## Overview

The Tool Usage Excellence system enhances Claude's tool usage through:
- **Matrix Enforcement**: Validates tool calls against tool-usage-matrix.md rules
- **Usage Tracking**: Records all tool usage patterns for analysis
- **Pattern Analysis**: Identifies common sequences and inefficiencies
- **Report Generation**: Creates detailed usage analytics
- **Auto Documentation**: Updates docs based on real usage

## Components

### 1. Tool Matrix Enforcement (`enforce-matrix.sh`)

Validates tool usage against the defined rules in tool-usage-matrix.md.

**Features:**
- Pre-execution validation (PreToolUse hook)
- Post-execution validation (PostToolUse hook)  
- Suggests better tool alternatives
- Returns JSON with validation results

**Usage:**
```bash
# Called automatically by hooks, or manually:
./enforce-matrix.sh '{"tool_name": "write_file", "context": "saving component", "user_request": "save this to Button.jsx"}'
```

**Output:**
```json
{
  "status": "valid",
  "tool_name": "write_file",
  "validation": {
    "is_valid": true,
    "message": ""
  },
  "required_tools": ["write_file"],
  "suggestions": [],
  "best_practices": [...]
}
```

### 2. Usage Tracking (`track-usage.sh`)

Records all tool usage in JSONL format for analysis.

**Features:**
- Session management with unique IDs
- Tool categorization (read, write, execute, search, browse)
- Operation type detection
- Execution time tracking
- Tool sequence tracking

**Log Location:** `.claude/logs/metaclaude/tool-usage.jsonl`

**Log Entry Example:**
```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "session_id": "abc123",
  "tool": {
    "name": "write_file",
    "category": "write",
    "parameters": {...}
  },
  "context": {
    "operation_type": "generation",
    "description": "Creating React component",
    "user_request": "Create a button component",
    "agent_type": "ui_generator"
  },
  "execution": {
    "status": "success",
    "duration_ms": 150,
    "previous_tool": "read_file"
  }
}
```

### 3. Pattern Analysis (`analyze-patterns.sh`)

Analyzes usage logs to find patterns and improvement opportunities.

**Features:**
- Common tool sequences detection
- Operation-specific tool combinations
- Inefficiency identification
- Integration suggestions
- Efficiency metrics calculation

**Usage:**
```bash
./analyze-patterns.sh
```

**Output Location:** `.claude/logs/metaclaude/usage-patterns.json`

**Key Insights:**
- Frequently used tool pairs
- Repeated operations that could be batched
- Underutilized tools
- Success rate metrics

### 4. Report Generation (`generate-report.sh`)

Creates comprehensive usage reports in JSON and Markdown formats.

**Report Types:**
- Daily reports
- Weekly reports  
- Monthly reports

**Usage:**
```bash
# Generate daily report
./generate-report.sh daily

# Generate weekly report in markdown
./generate-report.sh weekly markdown
```

**Report Contents:**
- Tool usage statistics
- Most/least used tools
- Category distribution
- Efficiency metrics
- Peak usage hours
- Agent distribution
- Insights and recommendations

**Output Location:** `.claude/logs/metaclaude/reports/`

### 5. Auto Documentation (`update-docs.sh`)

Updates tool documentation based on actual usage patterns.

**Features:**
- Extracts real examples from successful operations
- Updates individual tool documentation
- Generates usage statistics
- Identifies common patterns
- Updates main matrix documentation

**Usage:**
```bash
# Update all tool documentation
./update-docs.sh all

# Update specific tool
./update-docs.sh tool write_file

# Update only matrix documentation
./update-docs.sh matrix
```

**Output Location:** `.claude/docs/tool-examples/`

## Hook Configuration

The system integrates with Claude through hooks defined in `.claude/settings.json`:

### PreToolUse Hooks
- **metaclaude-tool-matrix-enforcement**: Validates tool selection before execution

### PostToolUse Hooks
- **metaclaude-tool-usage-tracking**: Records all tool usage
- **metaclaude-tool-validation**: Post-execution validation and learning

## Usage Workflows

### 1. Continuous Monitoring
```bash
# View real-time tool usage
tail -f .claude/logs/metaclaude/tool-usage.jsonl | jq .

# Check current session status
cat .claude/logs/metaclaude/current-session.json | jq .
```

### 2. Regular Analysis
```bash
# Run pattern analysis
./analyze-patterns.sh

# Generate weekly report
./generate-report.sh weekly

# Update documentation
./update-docs.sh all
```

### 3. Troubleshooting
```bash
# Check validation logs
tail -f .claude/logs/metaclaude/tool-enforcement.log

# View inefficiencies
jq '.inefficiencies' .claude/logs/metaclaude/usage-patterns.json

# Check specific tool usage
jq 'select(.tool.name == "write_file")' .claude/logs/metaclaude/tool-usage.jsonl
```

## Best Practices

1. **Regular Analysis**: Run pattern analysis weekly to identify improvement opportunities
2. **Report Review**: Generate and review reports to understand tool usage trends
3. **Documentation Updates**: Keep documentation current with auto-update runs
4. **Monitor Inefficiencies**: Address identified inefficiencies promptly
5. **Session Management**: New sessions are created automatically; old session data is preserved

## Metrics and KPIs

The system tracks:
- **Tool Usage Frequency**: Which tools are used most/least
- **Success Rate**: Percentage of successful tool executions
- **Execution Time**: Average, min, max execution times
- **Tool Diversity**: Variety of tools being utilized
- **Operation Distribution**: Types of operations performed
- **Peak Usage**: When tools are used most frequently

## Troubleshooting

### Common Issues

1. **No usage data appearing**
   - Check if hooks are enabled in settings.json
   - Verify scripts have execute permissions
   - Check log directory permissions

2. **Pattern analysis fails**
   - Ensure usage log exists and has data
   - Check for malformed JSON entries
   - Verify jq is installed

3. **Reports not generating**
   - Check date command compatibility (macOS vs Linux)
   - Ensure sufficient usage data exists
   - Verify write permissions in reports directory

## Future Enhancements

Potential improvements:
- Real-time dashboard for tool usage
- Machine learning for pattern prediction
- Automated inefficiency resolution
- Cross-project tool usage comparison
- Integration with CI/CD pipelines

---

*MetaClaude Tool Usage Excellence v1.0 - Continuous improvement through usage analytics*