# MetaClaude Feedback Automation System

This document describes the comprehensive feedback automation system that powers MetaClaude's continuous learning and improvement capabilities.

## Overview

The Feedback Automation System creates a closed-loop learning system where:
1. Operations generate feedback data
2. Feedback triggers pattern extraction and learning
3. Learning improves future operations
4. Improvements generate more feedback

## Feedback Flow Architecture

```
Operation Execution
        ↓
    Feedback Generation
        ↓
    Pattern Extraction ←─────┐
        ↓                   │
    Pattern Abstraction     │
        ↓                   │
    Pattern Sharing         │
        ↓                   │
    Implementation Usage    │
        ↓                   │
    Feedback Collection ────┘
        ↓
    Meta-Learning
        ↓
    Evolution & Persistence
```

## Components

### 1. Feedback Generation

Feedback is automatically generated from:
- Tool execution results
- Operation success/failure metrics
- Performance measurements
- Error tracking
- Resource usage monitoring

### 2. Feedback Collection

The system collects feedback through:
- **Direct feedback**: Explicit success/failure indicators
- **Implicit feedback**: Performance metrics and usage patterns
- **Contextual feedback**: Domain and environment information

### 3. Feedback Processing

Feedback is processed by:
- **pattern-feedback.sh**: Aggregates and rates pattern effectiveness
- **extract-patterns.sh**: Identifies successful strategies from feedback
- **meta-learner.sh**: Learns from aggregated feedback patterns

### 4. Feedback-Driven Actions

Based on feedback, the system:
- Archives ineffective patterns
- Promotes successful patterns
- Suggests pattern combinations
- Triggers pattern evolution

## Integration Points

### PostToolUse Feedback

```bash
# In PostToolUse hook
generate_tool_feedback() {
    local tool="$1"
    local result="$2"
    local execution_time="$3"
    local error_count="$4"
    
    # Generate feedback record
    local feedback=$(cat <<EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "tool": "$tool",
    "success": $([ "$error_count" -eq 0 ] && echo "true" || echo "false"),
    "execution_time": $execution_time,
    "error_count": $error_count,
    "context": {
        "operation_id": "$OPERATION_ID",
        "domain": "$DOMAIN",
        "environment": "$ENVIRONMENT"
    }
}
EOF
)
    
    # Log feedback
    echo "$feedback" >> "${CLAUDE_HOME:-.claude}/logs/feedback.log"
    
    # Trigger learning if significant
    if [ "$error_count" -eq 0 ] && [ "$execution_time" -lt 1000 ]; then
        trigger_pattern_extraction "$feedback"
    fi
}
```

### Automated Feedback Triggers

```bash
# Feedback automation configuration
setup_feedback_triggers() {
    # Success trigger
    on_operation_success() {
        local operation="$1"
        
        # Extract successful pattern
        extract_success_pattern "$operation"
        
        # Update metrics
        update_success_metrics "$operation"
    }
    
    # Failure trigger
    on_operation_failure() {
        local operation="$1"
        local error="$2"
        
        # Analyze failure pattern
        analyze_failure_pattern "$operation" "$error"
        
        # Trigger adaptation
        suggest_alternative_patterns "$operation"
    }
    
    # Performance trigger
    on_performance_threshold() {
        local metric="$1"
        local value="$2"
        
        if [ "$metric" = "execution_time" ] && [ "$value" -gt 5000 ]; then
            trigger_optimization_search "$metric"
        fi
    }
}
```

### Feedback Queuing System

```bash
# Queue feedback for batch processing
queue_feedback() {
    local feedback_data="$1"
    local queue_dir="${CLAUDE_HOME:-.claude}/feedback/queue"
    
    mkdir -p "$queue_dir"
    
    local feedback_id="fb_$(date +%s)_$$"
    echo "$feedback_data" > "$queue_dir/${feedback_id}.json"
    
    # Process queue if size threshold reached
    local queue_size=$(find "$queue_dir" -name "*.json" | wc -l)
    if [ "$queue_size" -gt 100 ]; then
        process_feedback_queue
    fi
}

# Process feedback queue
process_feedback_queue() {
    local queue_dir="${CLAUDE_HOME:-.claude}/feedback/queue"
    
    # Batch process feedback
    find "$queue_dir" -name "*.json" -type f | while read -r feedback_file; do
        local feedback=$(cat "$feedback_file")
        
        # Route to appropriate processor
        local feedback_type=$(echo "$feedback" | jq -r '.type // "general"')
        
        case "$feedback_type" in
            "pattern_usage")
                "${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/pattern-feedback.sh" <<< "$feedback"
                ;;
            "operation_result")
                "${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/extract-patterns.sh" <<< "$feedback"
                ;;
            *)
                log_feedback "$feedback"
                ;;
        esac
        
        # Remove processed feedback
        rm -f "$feedback_file"
    done
}
```

## Feedback Metrics

### Key Performance Indicators

1. **Pattern Success Rate**: Percentage of successful pattern applications
2. **Learning Velocity**: Rate of new pattern discovery
3. **Adaptation Rate**: Speed of pattern evolution
4. **Cross-Domain Transfer**: Patterns successfully used in multiple domains

### Metric Collection

```bash
# Collect and aggregate metrics
collect_feedback_metrics() {
    local metrics=$(cat <<EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "pattern_metrics": {
        "total_patterns": $(count_total_patterns),
        "active_patterns": $(count_active_patterns),
        "success_rate": $(calculate_pattern_success_rate),
        "evolution_rate": $(calculate_evolution_rate)
    },
    "learning_metrics": {
        "new_patterns_24h": $(count_new_patterns 24),
        "improvements_7d": $(count_improvements 7),
        "cross_domain_transfers": $(count_cross_domain_transfers)
    },
    "system_metrics": {
        "feedback_processed": $(count_processed_feedback),
        "queue_size": $(get_feedback_queue_size),
        "processing_latency": $(calculate_processing_latency)
    }
}
EOF
)
    
    echo "$metrics" > "${CLAUDE_HOME:-.claude}/metrics/feedback-metrics.json"
}
```

## Feedback Loops

### 1. Immediate Feedback Loop
- Triggers: Tool execution completion
- Processing: Real-time pattern extraction
- Action: Update operation strategies

### 2. Periodic Feedback Loop
- Triggers: Scheduled intervals (hourly/daily)
- Processing: Batch analysis and aggregation
- Action: Pattern evolution and sharing

### 3. Threshold-Based Loop
- Triggers: Performance thresholds
- Processing: Targeted optimization
- Action: Pattern refinement

## Configuration

### Feedback Settings

```bash
# .claude/config/feedback-config.json
{
    "feedback_enabled": true,
    "collection_mode": "automatic",
    "processing_interval": 3600,
    "queue_threshold": 100,
    "metrics_retention_days": 90,
    "feedback_channels": {
        "tool_execution": true,
        "pattern_usage": true,
        "performance_metrics": true,
        "error_tracking": true
    },
    "thresholds": {
        "success_rate_min": 0.7,
        "execution_time_max": 5000,
        "error_rate_max": 0.1
    }
}
```

### Custom Feedback Handlers

```bash
# Register custom feedback handler
register_feedback_handler() {
    local handler_name="$1"
    local handler_script="$2"
    
    # Add to handler registry
    echo "$handler_name:$handler_script" >> \
        "${CLAUDE_HOME:-.claude}/config/feedback-handlers.txt"
}

# Example custom handler
create_performance_feedback_handler() {
    cat > "${CLAUDE_HOME:-.claude}/hooks/feedback/performance-handler.sh" <<'EOF'
#!/bin/bash
# Custom performance feedback handler

handle_performance_feedback() {
    local feedback="$1"
    local execution_time=$(echo "$feedback" | jq -r '.execution_time')
    
    if [ "$execution_time" -lt 100 ]; then
        # Mark as high-performance pattern
        mark_high_performance_pattern "$feedback"
    elif [ "$execution_time" -gt 5000 ]; then
        # Trigger optimization search
        search_optimization_patterns "$feedback"
    fi
}
EOF
}
```

## Monitoring and Debugging

### Feedback Dashboard

```bash
# Generate feedback dashboard
generate_feedback_dashboard() {
    cat <<EOF
=== MetaClaude Feedback Dashboard ===
Generated: $(date)

FEEDBACK STATISTICS:
- Total Feedback Records: $(count_feedback_records)
- Processed Today: $(count_feedback_today)
- Queue Size: $(get_feedback_queue_size)
- Processing Rate: $(calculate_processing_rate)/hour

PATTERN PERFORMANCE:
- Success Rate: $(calculate_pattern_success_rate)%
- Top Performing: $(get_top_patterns 5)
- Needs Improvement: $(get_low_performing_patterns 5)

LEARNING PROGRESS:
- New Patterns (24h): $(count_new_patterns 24)
- Evolved Patterns (7d): $(count_evolved_patterns 7)
- Cross-Domain Success: $(calculate_cross_domain_success)%

SYSTEM HEALTH:
- Queue Processing Time: $(get_queue_processing_time)ms
- Feedback Latency: $(get_feedback_latency)ms
- Error Rate: $(calculate_error_rate)%
EOF
}
```

### Troubleshooting

1. **Feedback not being processed**:
   ```bash
   # Check queue status
   ls -la ${CLAUDE_HOME:-.claude}/feedback/queue/
   
   # Manually trigger processing
   ${CLAUDE_HOME:-.claude}/hooks/metaclaude/learning/pattern-feedback.sh
   ```

2. **Patterns not improving**:
   ```bash
   # Check feedback quality
   jq '.qualitative' ${CLAUDE_HOME:-.claude}/patterns/feedback/*.json
   
   # Verify learning is enabled
   grep "learning_enabled" ${CLAUDE_HOME:-.claude}/config/feedback-config.json
   ```

3. **High feedback latency**:
   ```bash
   # Check queue size
   find ${CLAUDE_HOME:-.claude}/feedback/queue -name "*.json" | wc -l
   
   # Process backlog
   for i in {1..10}; do
       process_feedback_queue &
   done
   ```

## Best Practices

1. **Structured Feedback**: Always include context, metrics, and outcomes
2. **Timely Processing**: Process feedback within the configured interval
3. **Balanced Metrics**: Consider both quantitative and qualitative feedback
4. **Regular Cleanup**: Archive old feedback to maintain performance
5. **Continuous Monitoring**: Track feedback metrics and system health

## Integration with Learning System

The feedback automation system is the primary data source for the Cross-Domain Learning system:

1. **Pattern Extraction**: Feedback identifies successful operations for pattern extraction
2. **Pattern Rating**: Aggregated feedback determines pattern effectiveness
3. **Evolution Triggers**: Feedback trends trigger pattern evolution
4. **Meta-Learning Input**: Feedback patterns inform meta-learning algorithms

See `metaclaude-learning-integration.md` for detailed learning system integration.

## Future Enhancements

1. **Machine Learning Integration**: Use ML models for feedback analysis
2. **Predictive Feedback**: Anticipate issues before they occur
3. **Federated Learning**: Share feedback insights across instances
4. **Real-time Adaptation**: Immediate pattern adjustments based on feedback
5. **Feedback Visualization**: Interactive dashboards and analytics