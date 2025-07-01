# MetaClaude Phase 5: Cross-Domain Learning Integration Guide

This document describes how to integrate the MetaClaude Cross-Domain Learning system with existing MetaClaude implementations.

## Overview

The Cross-Domain Learning system enables MetaClaude to:
- Extract successful patterns from operations
- Abstract domain-specific patterns to universal principles
- Share improvements across all implementations
- Learn from pattern usage and evolve over time
- Persist knowledge between sessions

## Components

### 1. Pattern Extraction Hooks
- **extract-patterns.sh**: Captures successful strategies from operations
- **abstract-patterns.sh**: Converts domain-specific patterns to universal ones

### 2. Collective Intelligence Hooks
- **share-improvements.sh**: Broadcasts successful patterns to all implementations
- **pattern-feedback.sh**: Collects feedback on pattern effectiveness

### 3. Meta-Learning Hooks
- **meta-learner.sh**: Learns from pattern usage statistics
- **evolution-tracker.sh**: Tracks how patterns evolve over time

### 4. Knowledge Persistence
- **persist-knowledge.sh**: Saves learned patterns and insights

## Integration with Existing Systems

### PostToolUse Hook Integration

Add pattern extraction to your existing PostToolUse hooks:

```bash
# In .claude/hooks/PostToolUse.sh
# After successful tool execution
if [ "$TOOL_SUCCESS" = "true" ]; then
    # Log operation for pattern extraction
    cat <<EOF >> "${CLAUDE_HOME:-.claude}/logs/operations.log"
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "id": "op_$(date +%s)_$$",
    "type": "$TOOL_NAME",
    "domain": "$OPERATION_DOMAIN",
    "data": {
        "tool": "$TOOL_NAME",
        "parameters": $TOOL_PARAMS,
        "result": $TOOL_RESULT,
        "execution_time": $EXECUTION_TIME,
        "steps": $OPERATION_STEPS
    },
    "metrics": {
        "success_rate": 1.0,
        "execution_time": $EXECUTION_TIME,
        "error_count": 0
    },
    "status": "success"
}
EOF
    
    # Trigger pattern extraction if threshold met
    if [ -x "${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/extract-patterns.sh" ]; then
        "${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/extract-patterns.sh" &
    fi
fi
```

### Periodic Learning Tasks

Add to your cron jobs or scheduled tasks:

```bash
# Learning tasks crontab
# Extract and abstract patterns hourly
0 * * * * ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/extract-patterns.sh
15 * * * * ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/abstract-patterns.sh

# Share improvements daily
0 2 * * * ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/share-improvements.sh

# Process feedback and run meta-learning daily
0 3 * * * ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/pattern-feedback.sh
0 4 * * * ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/meta-learner.sh

# Track evolution weekly
0 5 * * 0 ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/evolution-tracker.sh

# Persist knowledge daily
0 6 * * * ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/persist-knowledge.sh
```

### Pattern Usage Integration

When applying patterns in your implementations:

```bash
# In your pattern application code
apply_pattern() {
    local pattern_id="$1"
    local context="$2"
    
    # Apply the pattern
    local result=$(execute_pattern "$pattern_id" "$context")
    
    # Record feedback
    local feedback=$(cat <<EOF
{
    "pattern_id": "$pattern_id",
    "implementation_id": "$(hostname)",
    "success": $([ "$?" -eq 0 ] && echo "true" || echo "false"),
    "execution_time": $SECONDS,
    "domain": "$OPERATION_DOMAIN",
    "use_case": "$context",
    "ease_of_use": 4,
    "fit_for_purpose": 5,
    "continue_use": true
}
EOF
)
    
    # Queue feedback
    echo "$feedback" > "${CLAUDE_HOME:-.claude}/feedback/queue/feedback_$(date +%s).json"
}
```

### Pattern Discovery Integration

To use discovered patterns and compositions:

```bash
# Load recommended patterns
get_recommended_patterns() {
    local domain="$1"
    local use_case="$2"
    
    # Check pattern library
    local patterns=$(jq --arg d "$domain" --arg u "$use_case" '
        .patterns | to_entries | map(select(
            .value.domains | contains([$d]) or
            .value.applicability.contexts | contains([$u])
        )) | sort_by(-.value.quality_score) | limit(5; .[])
    ' "${CLAUDE_HOME:-.claude}/patterns/library/index.json")
    
    echo "$patterns"
}

# Use meta-learning recommendations
apply_meta_recommendations() {
    local recommendations=$(jq -r '.recommendations[]' \
        "${CLAUDE_HOME:-.claude}/learning/meta/meta-learning-summary.json")
    
    while IFS= read -r rec; do
        local type=$(echo "$rec" | jq -r '.type')
        case "$type" in
            "increase_usage")
                # Prioritize underutilized high-performers
                ;;
            "implement_combinations")
                # Try recommended pattern combinations
                ;;
            "expand_domains")
                # Test patterns in new domains
                ;;
        esac
    done <<< "$recommendations"
}
```

## Configuration

### Environment Variables

```bash
# Learning configuration
export CLAUDE_LEARNING_ENABLED=true
export CLAUDE_PATTERN_MIN_SUCCESS=0.8
export CLAUDE_PATTERN_RETENTION_DAYS=365
export CLAUDE_LEARNING_CHECKPOINT_INTERVAL=86400
```

### Abstraction Rules

Create custom abstraction rules in `.claude/config/abstraction-rules.json`:

```json
{
    "domain_mappings": {
        "your_domain": ["specific_term1", "specific_term2"],
        "another_domain": ["term3", "term4"]
    },
    "concept_generalizations": {
        "resource": ["your_resource_types"],
        "operation": ["your_operation_types"]
    }
}
```

## Monitoring and Maintenance

### View Learning Progress

```bash
# Check pattern extraction metrics
cat .claude/patterns/extraction-metrics.json

# View sharing report
cat .claude/patterns/sharing-report.json

# Check feedback report
cat .claude/patterns/feedback-report.json

# View meta-learning summary
cat .claude/learning/meta/meta-learning-summary.json

# Check evolution report
cat .claude/learning/evolution/evolution-report.json

# View persistence status
.claude/hooks/metaclaude/learning/persist-knowledge.sh report
```

### Export and Import Knowledge

```bash
# Export current knowledge
.claude/hooks/metaclaude/learning/persist-knowledge.sh export json

# Export compressed minimal version
.claude/hooks/metaclaude/learning/persist-knowledge.sh export minimal

# Import knowledge from another system
.claude/hooks/metaclaude/learning/persist-knowledge.sh import /path/to/knowledge_export.json
```

### Troubleshooting

1. **Patterns not being extracted**:
   - Check operations.log format
   - Verify success threshold settings
   - Check extract-patterns.sh logs

2. **Patterns not being shared**:
   - Verify implementation directories
   - Check pattern quality scores
   - Review share-improvements.sh logs

3. **Low pattern effectiveness**:
   - Review feedback data
   - Check domain alignment
   - Analyze evolution patterns

## Best Practices

1. **Consistent Operation Logging**: Ensure all successful operations are logged with proper metrics
2. **Regular Feedback**: Provide feedback on pattern usage to improve recommendations
3. **Domain Tagging**: Properly tag operations with domains for better pattern matching
4. **Knowledge Backup**: Regularly export knowledge for backup and sharing
5. **Monitor Evolution**: Track pattern evolution to identify improvement opportunities

## Advanced Usage

### Custom Pattern Extractors

Create specialized extractors for your domain:

```bash
# In .claude/hooks/metaclaude/learning/custom-extractor.sh
extract_domain_specific_pattern() {
    local operation_data="$1"
    
    # Custom extraction logic
    # ...
    
    # Call abstract-patterns.sh
    ./abstract-patterns.sh "$pattern_file"
}
```

### Pattern Composition Strategies

Implement custom composition strategies:

```bash
# Define composition rules
create_domain_composition() {
    local patterns=("$@")
    
    # Custom composition logic based on your domain
    # ...
}
```

## Integration with Feedback Automation

This learning system integrates with the feedback automation system to create a complete learning loop:

1. Operations generate feedback
2. Feedback triggers pattern extraction
3. Patterns are abstracted and shared
4. Usage generates more feedback
5. Meta-learning identifies improvements
6. Evolution tracking guides development

See `feedback-automation.md` for detailed feedback loop configuration.