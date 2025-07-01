# MetaClaude Coordination Layer

The Enhanced Coordination layer provides real-time communication, shared state management, conflict resolution, and role enforcement for multi-agent collaboration.

## Overview

The coordination layer consists of five main components:

1. **Broadcast System** - Real-time agent communication
2. **State Management** - Shared state with atomic operations
3. **Conflict Detection** - Resource contention and task collision detection
4. **Conflict Resolution** - Automated and manual conflict resolution
5. **Role Enforcement** - Agent role boundaries and delegation

## Components

### 1. Broadcast System (`broadcast.sh` & `subscribe.sh`)

Enables pub-sub messaging between agents with topic-based filtering.

#### Topics
- `system` - System-level events
- `task` - Task-related updates
- `state` - State changes
- `conflict` - Conflict notifications
- `coordination` - Agent coordination messages

#### Usage

**Broadcasting (automatic via PostToolUse hook):**
```bash
# Messages are automatically broadcast when tools are used
# Manual broadcast:
export TOOL_NAME="MyTool"
export TOOL_OUTPUT="Tool output data"
./broadcast.sh
```

**Subscribing:**
```bash
# Create subscription
./subscribe.sh create agent_001 researcher "task,state"

# Read messages
./subscribe.sh read agent_001 5 task

# Wait for new messages
./subscribe.sh wait agent_001 30 conflict

# List subscriptions
./subscribe.sh list
```

### 2. State Management (`state-manager.sh` & `state-sync.sh`)

Provides atomic state operations with snapshot capability.

#### Operations
- `get` - Read state values
- `set` - Set state values (atomic)
- `update` - Update with JQ expressions (atomic)
- `delete` - Remove state keys
- `snapshot` - Create state snapshots
- `restore` - Restore from snapshots

#### Usage

```bash
# Set state
./state-manager.sh set current_task '{"id": "task-123", "status": "active"}'

# Update state atomically
./state-manager.sh update task_queue '. + ["new_task"]'

# Create snapshot
./state-manager.sh snapshot main "Before major refactor"

# Inspect state
./state-manager.sh inspect

# Synchronize state changes
./state-sync.sh sync main current_task '{"status": "completed"}'
```

### 3. Conflict Detection (`detect-conflicts.sh`)

Automatically detects:
- Resource contention (files, directories, services)
- Task assignment conflicts
- Operation collisions

#### Resource Claims

```bash
# Claim resource
./detect-conflicts.sh claim file "/path/to/file.js" agent_001 modify 300

# Release resource
./detect-conflicts.sh release file "/path/to/file.js" agent_001

# List conflicts
./detect-conflicts.sh list
```

### 4. Conflict Resolution (`resolve-conflicts.sh`)

Implements multiple resolution strategies based on agent hierarchy and rules.

#### Agent Hierarchy (Priority Levels)
- `orchestrator`: 100
- `architect`: 90
- `reviewer`: 80
- `debugger`: 75
- `analyzer`: 70
- `tester`: 65
- `coder`: 60
- `researcher`: 50
- `default`: 10

#### Resolution Strategies
- **Priority-based** - Higher priority agent wins
- **Sequential** - Queue requests
- **Time-sharing** - Schedule resource sharing
- **Merge** - Combine operations (for lists, etc.)
- **Block** - Prevent dangerous operations

#### Usage

```bash
# Resolve specific conflict
./resolve-conflicts.sh resolve /path/to/conflict.conflict auto

# Resolve all conflicts
./resolve-conflicts.sh resolve-all priority resource_contention

# Monitor and auto-resolve
./resolve-conflicts.sh monitor 30 true
```

### 5. Role Enforcement (`role-enforcer.sh`)

Enforces agent role boundaries and ensures proper delegation.

#### Agent Roles

**Orchestration Agents:**
- `orchestrator` - Coordinates and delegates tasks
- `architect` - Designs system architecture

**Execution Agents:**
- `coder` - Implements code changes
- `tester` - Tests and validates
- `debugger` - Debugs issues

**Analysis Agents:**
- `researcher` - Researches information
- `reviewer` - Reviews code
- `analyzer` - Analyzes performance

#### Usage

```bash
# Check permissions
./role-enforcer.sh check orchestrator Write

# View role configuration
./role-enforcer.sh role coder

# Analyze compliance
./role-enforcer.sh analyze orchestrator 3600
```

## Hook Integration

The coordination layer integrates with Claude hooks:

### PreToolUse Hooks
- **role-enforcer.sh** - Validates tool permissions before execution

### PostToolUse Hooks
- **broadcast.sh** - Broadcasts tool usage to subscribers
- **detect-conflicts.sh** - Detects conflicts from tool usage

## Configuration

### Resolution Rules (`resolution-rules.json`)

Customize conflict resolution strategies:

```json
{
  "resource_contention": {
    "file": {
      "read_read": "allow_both",
      "read_modify": "priority_based",
      "modify_modify": "sequential"
    }
  },
  "task_assignment": {
    "orchestration_execution": "orchestrator_priority"
  }
}
```

## Examples

### Multi-Agent File Editing

```bash
# Agent 1 (Coder) claims file
AGENT_ID=coder_001 ./detect-conflicts.sh claim file "app.js" coder_001 modify

# Agent 2 (Debugger) tries to claim same file
AGENT_ID=debugger_001 ./detect-conflicts.sh claim file "app.js" debugger_001 modify
# Conflict detected!

# Resolution based on priority
./resolve-conflicts.sh resolve-all auto
```

### Orchestrator Delegation

```bash
# Orchestrator attempts direct code edit
AGENT_TYPE=orchestrator TOOL_NAME=Write ./role-enforcer.sh
# BLOCKED: orchestrator agent cannot use Write
# Suggestion: delegate to coder agent
```

### State Synchronization

```bash
# Multiple agents updating task list
AGENT_ID=agent_001 ./state-sync.sh sync main task_list '["task1", "task2"]'
AGENT_ID=agent_002 ./state-sync.sh sync main task_list '["task1", "task3"]'

# Automatic merge resolution
./state-sync.sh process main
# Result: ["task1", "task2", "task3"]
```

## Best Practices

1. **Subscribe to Relevant Topics** - Agents should only subscribe to topics they need
2. **Release Resources Promptly** - Always release resources when done
3. **Use Appropriate Namespaces** - Separate state by concern
4. **Create Regular Snapshots** - Before major operations
5. **Follow Role Boundaries** - Orchestrators delegate, executors implement

## Troubleshooting

### Common Issues

1. **Stale Locks**
   ```bash
   ./detect-conflicts.sh cleanup 3600
   ```

2. **Message Queue Overflow**
   - Old messages are automatically cleaned after 1 hour
   - Adjust retention in broadcast.sh if needed

3. **State Conflicts**
   - Check vector clocks in sync conflicts
   - Use manual resolution for complex cases

4. **Role Violations**
   ```bash
   ./role-enforcer.sh violations orchestrator
   ```

## Monitoring

### System Status

```bash
# Broadcast status
./subscribe.sh list

# State status
./state-manager.sh namespaces

# Conflict status
./detect-conflicts.sh list

# Sync status
./state-sync.sh status
```

### Metrics Collection

The coordination layer automatically tracks:
- Message broadcast rates
- State update frequency
- Conflict occurrence patterns
- Role violation incidents
- Resource contention hotspots

## Advanced Features

### Custom Topics

Add new topics by modifying the topic extraction logic in `broadcast.sh`:

```bash
case "$tool_name" in
    "CustomTool")
        echo "custom_topic"
        ;;
esac
```

### Extended Role Definitions

Add new agent roles in `role-enforcer.sh`:

```json
"specialist": {
    "type": "execution",
    "allowed_tools": ["CustomTool", "Read"],
    "forbidden_tools": ["Delete"],
    "delegation_required": []
}
```

### Conflict Resolution Plugins

Create custom resolution strategies by extending `resolve-conflicts.sh`.

## Security Considerations

1. **Agent Authentication** - Agent IDs should be verified
2. **State Isolation** - Use namespaces to isolate sensitive state
3. **Resource Limits** - Implement quotas for resource claims
4. **Message Validation** - Validate broadcast message content

## Performance Optimization

1. **Message Filtering** - Use specific topics to reduce message volume
2. **State Partitioning** - Split large state into multiple namespaces
3. **Async Operations** - Use non-blocking message reads
4. **Cleanup Jobs** - Regular cleanup of old data

## Future Enhancements

- [ ] Message encryption for sensitive broadcasts
- [ ] Distributed state replication
- [ ] Machine learning for conflict prediction
- [ ] Dynamic role assignment based on workload
- [ ] GraphQL API for state queries