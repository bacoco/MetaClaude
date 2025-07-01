# MetaClaude Hook System

## Overview

The MetaClaude hook system provides intelligent content management, monitoring, boundary enforcement, and multi-agent coordination capabilities for Claude Code operations. This implementation includes all four phases: content management (Phase 1), agent boundaries (Phase 2), tool enforcement (Phase 3), and enhanced coordination (Phase 4).

## Directory Structure

```
.claude/hooks/metaclaude/
├── content/              # Content management hooks
│   ├── dedup-check.sh   # Content deduplication validation
│   └── similarity-detector.sh  # Pattern similarity detection
├── monitoring/          # Monitoring and analytics
│   ├── hook-metrics.sh  # Hook execution metrics tracking
│   └── log-aggregator.sh # Centralized log management
├── coordination/        # Multi-agent coordination (Phase 4)
│   ├── broadcast.sh     # Real-time agent communication
│   ├── subscribe.sh     # Agent subscription management
│   ├── state-manager.sh # Shared state management
│   ├── state-sync.sh    # State synchronization
│   ├── detect-conflicts.sh # Conflict detection
│   ├── resolve-conflicts.sh # Conflict resolution
│   ├── role-enforcer.sh # Agent role enforcement
│   └── README.md        # Coordination documentation
├── boundaries/          # Agent boundary management
├── tools/              # Tool usage enforcement
├── utils/              # Utility scripts
└── README.md          # This documentation
```

## Hook Components

### Content Management

#### dedup-check.sh
- **Purpose**: Validates content before Write/Edit operations to prevent redundancy
- **Triggers**: Write and Edit tool operations
- **Features**:
  - Detects duplicate operating principles
  - Suggests references to CLAUDE.md configuration
  - Logs validation results for monitoring
  - Returns warnings for potential duplicates

**Usage Example**:
```bash
echo '{"content": "Core Configuration settings..."}' | ./dedup-check.sh
```

#### similarity-detector.sh
- **Purpose**: Analyzes content for pattern similarities
- **Features**:
  - Uses grep patterns to find similar content
  - Outputs JSON with similarity scores
  - Analyzes content chunks and patterns
  - Compares against CLAUDE.md and project files

**Usage Example**:
```bash
./similarity-detector.sh "Your content to analyze"
# Or pipe content
echo "Content to analyze" | ./similarity-detector.sh
```

### Monitoring Infrastructure

#### hook-metrics.sh
- **Purpose**: Track and report hook execution metrics
- **Commands**:
  - `record <hook_name> <status> [duration_ms]` - Record hook execution
  - `stats [hook_name]` - Get statistics for hooks
  - `report [type]` - Generate reports (summary|daily|errors)
  - `clean [days]` - Clean old metrics

**Usage Examples**:
```bash
# Record a hook execution
./hook-metrics.sh record dedup-check success 125

# Get statistics
./hook-metrics.sh stats dedup-check

# Generate summary report
./hook-metrics.sh report summary
```

#### log-aggregator.sh
- **Purpose**: Collect and analyze hook logs
- **Commands**:
  - `collect [since] [output]` - Collect logs since timestamp
  - `analyze [type] [input]` - Analyze logs (summary|errors|performance|patterns)
  - `report` - Generate comprehensive report
  - `monitor` - Monitor logs in real-time
  - `clean [days]` - Clean old logs

**Usage Examples**:
```bash
# Collect recent logs
./log-aggregator.sh collect "2 hours ago"

# Analyze errors
./log-aggregator.sh analyze errors

# Monitor in real-time
./log-aggregator.sh monitor
```

## Hook Configuration

The hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "name": "metaclaude-content-deduplication",
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${HOME}/.claude/hooks/metaclaude/content/dedup-check.sh",
        "description": "Validates content before Write/Edit operations"
      }]
    }]
  }
}
```

## Logging

All hooks write logs to:
- `~/.claude/hooks/metaclaude/monitoring/dedup.log` - Deduplication events
- `~/.claude/hooks/metaclaude/monitoring/similarity.log` - Similarity detection
- `~/.claude/hooks/metaclaude/monitoring/metrics/` - Performance metrics

## Exit Codes

- `0` - Success, no issues found
- `1` - Error occurred
- `2` - Warning (e.g., duplicates detected)

### Coordination Layer (Phase 4)

The coordination layer enables smooth multi-agent collaboration:

#### broadcast.sh & subscribe.sh
- **Purpose**: Real-time pub-sub messaging between agents
- **Features**: Topic-based filtering, message queuing, non-blocking delivery

#### state-manager.sh & state-sync.sh
- **Purpose**: Shared state management with consistency
- **Features**: Atomic operations, vector clocks, conflict detection, snapshots

#### detect-conflicts.sh & resolve-conflicts.sh
- **Purpose**: Prevent and resolve agent conflicts
- **Features**: Resource contention detection, priority-based resolution, automatic/manual modes

#### role-enforcer.sh
- **Purpose**: Enforce agent role boundaries
- **Features**: Tool permissions, delegation requirements, violation tracking

For detailed coordination documentation, see `.claude/hooks/metaclaude/coordination/README.md`.

## Future Enhancements

Completed phases:
- Phase 1: Content management and monitoring ✓
- Phase 2: Agent boundaries and permissions ✓
- Phase 3: Tool usage enforcement ✓
- Phase 4: Enhanced coordination layer ✓

Future development:
- Advanced ML-based conflict prediction
- Cross-session learning and memory
- Distributed state replication
- Dynamic role assignment

## Testing

Test the hooks with:
```bash
# Test deduplication
echo '{"content": "Core Configuration example"}' | \
  .claude/hooks/metaclaude/content/dedup-check.sh

# Test similarity detection
.claude/hooks/metaclaude/content/similarity-detector.sh \
  "Test content with patterns"

# View metrics
.claude/hooks/metaclaude/monitoring/hook-metrics.sh report

# Test coordination layer
.claude/hooks/metaclaude/coordination/test-coordination.sh

# Test individual coordination components
.claude/hooks/metaclaude/coordination/role-enforcer.sh check orchestrator Write
.claude/hooks/metaclaude/coordination/state-manager.sh set test_key '{"value": "test"}'
.claude/hooks/metaclaude/coordination/subscribe.sh list
```

## Troubleshooting

1. **Hook not executing**: Check that scripts are executable (`chmod +x`)
2. **No logs generated**: Ensure log directories exist and have write permissions
3. **JSON parsing errors**: Validate JSON input format
4. **Path issues**: Verify `$HOME` environment variable is set correctly

## Contributing

When adding new hooks:
1. Follow the existing naming conventions
2. Include proper error handling
3. Add logging for monitoring
4. Update this documentation
5. Test thoroughly before deployment