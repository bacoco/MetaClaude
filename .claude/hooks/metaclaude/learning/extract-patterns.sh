#!/bin/bash
#
# Extract Patterns Hook - Captures successful strategies from operations
# Part of MetaClaude Phase 5: Cross-Domain Learning
#

set -euo pipefail

# Source MetaClaude utilities
source "$(dirname "$0")/../../utils/metaclaude-utils.sh"

# Configuration
PATTERNS_DIR="${CLAUDE_HOME:-.claude}/patterns"
EXTRACTED_DIR="$PATTERNS_DIR/extracted"
OPERATIONS_LOG="${CLAUDE_HOME:-.claude}/logs/operations.log"
EXTRACTION_LOG="${CLAUDE_HOME:-.claude}/logs/pattern-extraction.log"
MIN_SUCCESS_THRESHOLD=0.8
PATTERN_VERSION="1.0.0"

# Initialize directories
mkdir -p "$EXTRACTED_DIR" "$(dirname "$EXTRACTION_LOG")"

# Function to log extraction events
log_extraction() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$EXTRACTION_LOG"
}

# Function to analyze operation success
analyze_operation_success() {
    local operation_id="$1"
    local operation_data="$2"
    
    # Extract success metrics
    local success_rate=$(echo "$operation_data" | jq -r '.metrics.success_rate // 0')
    local execution_time=$(echo "$operation_data" | jq -r '.metrics.execution_time // 0')
    local error_count=$(echo "$operation_data" | jq -r '.metrics.error_count // 0')
    
    # Calculate success score
    local success_score=$(awk -v sr="$success_rate" -v et="$execution_time" -v ec="$error_count" '
        BEGIN {
            time_factor = et > 0 ? 1 / (1 + et/1000) : 0
            error_factor = 1 / (1 + ec)
            score = sr * 0.6 + time_factor * 0.2 + error_factor * 0.2
            print score
        }
    ')
    
    echo "$success_score"
}

# Function to extract pattern metadata
extract_pattern_metadata() {
    local operation_data="$1"
    local pattern_type="$2"
    
    cat <<EOF
{
    "pattern_version": "$PATTERN_VERSION",
    "extracted_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "source": {
        "operation_id": "$(echo "$operation_data" | jq -r '.id // "unknown"')",
        "operation_type": "$(echo "$operation_data" | jq -r '.type // "unknown"')",
        "domain": "$(echo "$operation_data" | jq -r '.domain // "general"')"
    },
    "classification": {
        "type": "$pattern_type",
        "tags": $(echo "$operation_data" | jq '.tags // []'),
        "complexity": "$(classify_complexity "$operation_data")"
    },
    "metrics": {
        "success_rate": $(echo "$operation_data" | jq '.metrics.success_rate // 0'),
        "execution_time": $(echo "$operation_data" | jq '.metrics.execution_time // 0'),
        "reuse_count": 0,
        "adaptation_count": 0
    }
}
EOF
}

# Function to classify pattern complexity
classify_complexity() {
    local operation_data="$1"
    local steps=$(echo "$operation_data" | jq '.steps | length // 0')
    local dependencies=$(echo "$operation_data" | jq '.dependencies | length // 0')
    
    if [ "$steps" -gt 10 ] || [ "$dependencies" -gt 5 ]; then
        echo "high"
    elif [ "$steps" -gt 5 ] || [ "$dependencies" -gt 2 ]; then
        echo "medium"
    else
        echo "low"
    fi
}

# Function to extract strategy pattern
extract_strategy_pattern() {
    local operation_data="$1"
    local pattern_id="strategy_$(date +%s)_$$"
    
    # Extract core strategy elements
    local strategy=$(cat <<EOF
{
    "pattern_id": "$pattern_id",
    "pattern_type": "strategy",
    "name": "$(echo "$operation_data" | jq -r '.name // "Unnamed Strategy"')",
    "description": "$(echo "$operation_data" | jq -r '.description // "Extracted strategy pattern"')",
    "context": {
        "preconditions": $(echo "$operation_data" | jq '.preconditions // []'),
        "postconditions": $(echo "$operation_data" | jq '.postconditions // []'),
        "constraints": $(echo "$operation_data" | jq '.constraints // []')
    },
    "implementation": {
        "steps": $(extract_strategy_steps "$operation_data"),
        "decision_points": $(extract_decision_points "$operation_data"),
        "fallback_strategies": $(echo "$operation_data" | jq '.fallbacks // []')
    },
    "metadata": $(extract_pattern_metadata "$operation_data" "strategy")
}
EOF
)
    
    # Save pattern
    echo "$strategy" | jq '.' > "$EXTRACTED_DIR/$pattern_id.json"
    log_extraction "INFO" "Extracted strategy pattern: $pattern_id"
    
    echo "$pattern_id"
}

# Function to extract strategy steps
extract_strategy_steps() {
    local operation_data="$1"
    
    echo "$operation_data" | jq '[.steps[]? | {
        "order": .order,
        "action": .action,
        "purpose": .purpose,
        "inputs": .inputs,
        "outputs": .outputs,
        "conditions": .conditions
    }]'
}

# Function to extract decision points
extract_decision_points() {
    local operation_data="$1"
    
    echo "$operation_data" | jq '[.decisions[]? | {
        "id": .id,
        "description": .description,
        "criteria": .criteria,
        "options": .options,
        "default": .default
    }]'
}

# Function to extract workflow pattern
extract_workflow_pattern() {
    local operation_data="$1"
    local pattern_id="workflow_$(date +%s)_$$"
    
    # Extract workflow elements
    local workflow=$(cat <<EOF
{
    "pattern_id": "$pattern_id",
    "pattern_type": "workflow",
    "name": "$(echo "$operation_data" | jq -r '.workflow.name // "Unnamed Workflow"')",
    "description": "$(echo "$operation_data" | jq -r '.workflow.description // "Extracted workflow pattern"')",
    "structure": {
        "stages": $(extract_workflow_stages "$operation_data"),
        "transitions": $(extract_workflow_transitions "$operation_data"),
        "parallelism": $(echo "$operation_data" | jq '.workflow.parallelism // "sequential"')
    },
    "error_handling": {
        "retry_policy": $(echo "$operation_data" | jq '.workflow.retry_policy // {}'),
        "error_handlers": $(echo "$operation_data" | jq '.workflow.error_handlers // []'),
        "compensation": $(echo "$operation_data" | jq '.workflow.compensation // []')
    },
    "metadata": $(extract_pattern_metadata "$operation_data" "workflow")
}
EOF
)
    
    # Save pattern
    echo "$workflow" | jq '.' > "$EXTRACTED_DIR/$pattern_id.json"
    log_extraction "INFO" "Extracted workflow pattern: $pattern_id"
    
    echo "$pattern_id"
}

# Function to extract workflow stages
extract_workflow_stages() {
    local operation_data="$1"
    
    echo "$operation_data" | jq '[.workflow.stages[]? | {
        "id": .id,
        "name": .name,
        "type": .type,
        "activities": .activities,
        "duration": .duration,
        "dependencies": .dependencies
    }]'
}

# Function to extract workflow transitions
extract_workflow_transitions() {
    local operation_data="$1"
    
    echo "$operation_data" | jq '[.workflow.transitions[]? | {
        "from": .from,
        "to": .to,
        "condition": .condition,
        "action": .action
    }]'
}

# Function to extract optimization pattern
extract_optimization_pattern() {
    local operation_data="$1"
    local pattern_id="optimization_$(date +%s)_$$"
    
    # Extract optimization elements
    local optimization=$(cat <<EOF
{
    "pattern_id": "$pattern_id",
    "pattern_type": "optimization",
    "name": "$(echo "$operation_data" | jq -r '.optimization.name // "Unnamed Optimization"')",
    "description": "$(echo "$operation_data" | jq -r '.optimization.description // "Extracted optimization pattern"')",
    "target": {
        "metric": "$(echo "$operation_data" | jq -r '.optimization.target_metric // "performance"')",
        "improvement": $(echo "$operation_data" | jq '.optimization.improvement // 0'),
        "baseline": $(echo "$operation_data" | jq '.optimization.baseline // {}')
    },
    "techniques": $(extract_optimization_techniques "$operation_data"),
    "constraints": $(echo "$operation_data" | jq '.optimization.constraints // []'),
    "trade_offs": $(echo "$operation_data" | jq '.optimization.trade_offs // []'),
    "metadata": $(extract_pattern_metadata "$operation_data" "optimization")
}
EOF
)
    
    # Save pattern
    echo "$optimization" | jq '.' > "$EXTRACTED_DIR/$pattern_id.json"
    log_extraction "INFO" "Extracted optimization pattern: $pattern_id"
    
    echo "$pattern_id"
}

# Function to extract optimization techniques
extract_optimization_techniques() {
    local operation_data="$1"
    
    echo "$operation_data" | jq '[.optimization.techniques[]? | {
        "name": .name,
        "type": .type,
        "parameters": .parameters,
        "impact": .impact,
        "cost": .cost
    }]'
}

# Function to identify pattern type
identify_pattern_type() {
    local operation_data="$1"
    
    # Check for different pattern indicators
    if echo "$operation_data" | jq -e '.workflow' > /dev/null 2>&1; then
        echo "workflow"
    elif echo "$operation_data" | jq -e '.optimization' > /dev/null 2>&1; then
        echo "optimization"
    elif echo "$operation_data" | jq -e '.steps' > /dev/null 2>&1; then
        echo "strategy"
    else
        echo "general"
    fi
}

# Function to validate extracted pattern
validate_pattern() {
    local pattern_file="$1"
    
    if [ ! -f "$pattern_file" ]; then
        return 1
    fi
    
    # Check required fields
    local required_fields=("pattern_id" "pattern_type" "name" "metadata")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$pattern_file" > /dev/null 2>&1; then
            log_extraction "ERROR" "Pattern validation failed: missing field $field"
            return 1
        fi
    done
    
    return 0
}

# Main extraction logic
main() {
    log_extraction "INFO" "Starting pattern extraction process"
    
    # Check for recent successful operations
    if [ ! -f "$OPERATIONS_LOG" ]; then
        log_extraction "WARN" "No operations log found"
        exit 0
    fi
    
    # Process recent operations
    local extracted_count=0
    local operation_count=0
    
    # Read operations from the last hour
    local one_hour_ago=$(date -d '1 hour ago' +%s 2>/dev/null || date -v-1H +%s)
    
    while IFS= read -r line; do
        # Parse operation data
        local timestamp=$(echo "$line" | jq -r '.timestamp // ""')
        local operation_data=$(echo "$line" | jq -r '.data // {}')
        
        # Skip if timestamp is too old
        if [ -n "$timestamp" ]; then
            local op_timestamp=$(date -d "$timestamp" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" +%s 2>/dev/null || echo "0")
            if [ "$op_timestamp" -lt "$one_hour_ago" ]; then
                continue
            fi
        fi
        
        operation_count=$((operation_count + 1))
        
        # Analyze operation success
        local success_score=$(analyze_operation_success "$(echo "$line" | jq -r '.id')" "$operation_data")
        
        # Extract pattern if successful enough
        if (( $(echo "$success_score >= $MIN_SUCCESS_THRESHOLD" | bc -l) )); then
            local pattern_type=$(identify_pattern_type "$operation_data")
            local pattern_id=""
            
            case "$pattern_type" in
                "strategy")
                    pattern_id=$(extract_strategy_pattern "$operation_data")
                    ;;
                "workflow")
                    pattern_id=$(extract_workflow_pattern "$operation_data")
                    ;;
                "optimization")
                    pattern_id=$(extract_optimization_pattern "$operation_data")
                    ;;
                *)
                    log_extraction "WARN" "Unknown pattern type: $pattern_type"
                    continue
                    ;;
            esac
            
            if [ -n "$pattern_id" ] && validate_pattern "$EXTRACTED_DIR/$pattern_id.json"; then
                extracted_count=$((extracted_count + 1))
                
                # Trigger abstraction hook
                if [ -x "$(dirname "$0")/abstract-patterns.sh" ]; then
                    "$(dirname "$0")/abstract-patterns.sh" "$EXTRACTED_DIR/$pattern_id.json"
                fi
            fi
        fi
    done < <(tail -n 100 "$OPERATIONS_LOG" | grep -E '"status":\s*"success"')
    
    log_extraction "INFO" "Pattern extraction complete: $extracted_count patterns from $operation_count operations"
    
    # Update extraction metrics
    cat <<EOF > "$PATTERNS_DIR/extraction-metrics.json"
{
    "last_extraction": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "operations_analyzed": $operation_count,
    "patterns_extracted": $extracted_count,
    "extraction_rate": $(awk -v e="$extracted_count" -v o="$operation_count" 'BEGIN { print o > 0 ? e/o : 0 }'),
    "total_patterns": $(find "$EXTRACTED_DIR" -name "*.json" | wc -l)
}
EOF
}

# Execute main function
main "$@"