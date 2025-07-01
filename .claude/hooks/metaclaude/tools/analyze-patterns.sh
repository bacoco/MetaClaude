#!/bin/bash

# Tool Usage Pattern Analysis Hook
# Analyzes usage logs to find patterns and suggest improvements
# Identifies frequently used tool combinations and integration opportunities

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
USAGE_LOG="$CLAUDE_ROOT/.claude/logs/metaclaude/tool-usage.jsonl"
PATTERNS_OUTPUT="$CLAUDE_ROOT/.claude/logs/metaclaude/usage-patterns.json"

# Ensure log directory exists
mkdir -p "$(dirname "$PATTERNS_OUTPUT")"

# Function to analyze tool sequences
analyze_sequences() {
    local sequences_json="[]"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "$sequences_json"
        return
    fi
    
    # Extract tool sequences (pairs)
    local prev_tool=""
    local sequences=()
    
    while IFS= read -r line; do
        local tool_name=$(echo "$line" | jq -r '.tool.name // empty')
        if [[ -n "$prev_tool" && -n "$tool_name" ]]; then
            sequences+=("${prev_tool}->${tool_name}")
        fi
        prev_tool="$tool_name"
    done < "$USAGE_LOG"
    
    # Count sequence frequencies
    if [ ${#sequences[@]} -gt 0 ]; then
        printf '%s\n' "${sequences[@]}" | sort | uniq -c | sort -rn | head -20 | while read count sequence; do
            sequences_json=$(echo "$sequences_json" | jq ". += [{\"sequence\": \"$sequence\", \"count\": $count}]")
            echo "$sequences_json"
        done | tail -1
    else
        echo "$sequences_json"
    fi
}

# Function to analyze tool combinations per operation
analyze_combinations() {
    local combinations_json="{}"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "$combinations_json"
        return
    fi
    
    # Group by operation type
    local operation_types=(analysis generation persistence discovery validation setup)
    
    for op_type in "${operation_types[@]}"; do
        local tools=$(jq -r "select(.context.operation_type == \"$op_type\") | .tool.name" "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -5)
        
        local tools_array="[]"
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local count=$(echo "$line" | awk '{print $1}')
                local tool=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
                tools_array=$(echo "$tools_array" | jq ". += [{\"tool\": \"$tool\", \"count\": $count}]")
            fi
        done <<< "$tools"
        
        combinations_json=$(echo "$combinations_json" | jq ".\"$op_type\" = $tools_array")
    done
    
    echo "$combinations_json"
}

# Function to identify inefficient patterns
identify_inefficiencies() {
    local inefficiencies="[]"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "$inefficiencies"
        return
    fi
    
    # Check for repeated reads of same file
    local repeated_reads=$(jq -r 'select(.tool.category == "read") | .tool.parameters.file_path // empty' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -rn | awk '$1 > 3 {print $2}')
    
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            inefficiencies=$(echo "$inefficiencies" | jq ". += [{\"type\": \"repeated_read\", \"file\": \"$file\", \"suggestion\": \"Cache file content or use memory for frequently accessed files\"}]")
        fi
    done <<< "$repeated_reads"
    
    # Check for sequential writes that could be batched
    local prev_time=""
    local prev_tool=""
    local write_cluster=0
    
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | jq -r '.timestamp')
        local tool_name=$(echo "$line" | jq -r '.tool.name')
        local category=$(echo "$line" | jq -r '.tool.category')
        
        if [[ "$category" == "write" ]]; then
            if [[ "$prev_tool" == "write" ]]; then
                write_cluster=$((write_cluster + 1))
            else
                if [[ $write_cluster -gt 2 ]]; then
                    inefficiencies=$(echo "$inefficiencies" | jq ". += [{\"type\": \"sequential_writes\", \"count\": $write_cluster, \"suggestion\": \"Consider batching multiple write operations\"}]")
                fi
                write_cluster=1
            fi
        else
            write_cluster=0
        fi
        
        prev_time="$timestamp"
        prev_tool="$category"
    done < "$USAGE_LOG"
    
    echo "$inefficiencies"
}

# Function to suggest new integrations
suggest_integrations() {
    local suggestions="[]"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "$suggestions"
        return
    fi
    
    # Analyze common tool pairs that might benefit from integration
    local tool_pairs=$(jq -r '[.tool.name] | @csv' "$USAGE_LOG" 2>/dev/null | tr ',' '\n' | sed 's/"//g' | sort | uniq -c | sort -rn)
    
    # Check for patterns that suggest integration opportunities
    local read_then_write=$(grep -E "read_file.*write_file|Read.*Write" "$USAGE_LOG" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    if [ "$read_then_write" -gt 10 ]; then
        suggestions=$(echo "$suggestions" | jq '. += [{
            "pattern": "frequent_read_then_write",
            "suggestion": "Consider creating a transform_file tool that reads, modifies, and writes in one operation",
            "frequency": '$read_then_write'
        }]')
    fi
    
    # Check for search then read patterns
    local search_then_read=$(grep -E "search_file_content.*read_file|Grep.*Read|Glob.*Read" "$USAGE_LOG" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    if [ "$search_then_read" -gt 5 ]; then
        suggestions=$(echo "$suggestions" | jq '. += [{
            "pattern": "search_then_read",
            "suggestion": "Create a search_and_extract tool that finds and returns content in one operation",
            "frequency": '$search_then_read'
        }]')
    fi
    
    echo "$suggestions"
}

# Function to calculate efficiency metrics
calculate_metrics() {
    local metrics="{}"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "$metrics"
        return
    fi
    
    # Total operations
    local total_ops=$(wc -l < "$USAGE_LOG" | tr -d ' ')
    
    # Success rate
    local successful=$(jq -r 'select(.execution.status == "success") | .tool.name' "$USAGE_LOG" 2>/dev/null | wc -l | tr -d ' ')
    local success_rate=0
    if [[ $total_ops -gt 0 ]]; then
        success_rate=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $successful / $total_ops * 100}")
    fi
    
    # Average execution time by category
    local categories=(read write execute search browse)
    local avg_times="{}"
    
    for category in "${categories[@]}"; do
        local avg=$(jq -r "select(.tool.category == \"$category\") | .execution.duration_ms // 0" "$USAGE_LOG" 2>/dev/null | LC_NUMERIC=C awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
        avg_times=$(echo "$avg_times" | jq ".\"$category\" = $avg")
    done
    
    # Tool diversity score (number of unique tools used)
    local unique_tools=$(jq -r '.tool.name' "$USAGE_LOG" 2>/dev/null | sort -u | wc -l | tr -d ' ')
    local diversity_score=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", $unique_tools / 10 * 100}")
    
    metrics=$(cat <<EOF
{
  "total_operations": $total_ops,
  "success_rate": $success_rate,
  "average_execution_ms": $avg_times,
  "tool_diversity_score": $diversity_score,
  "unique_tools_used": $unique_tools
}
EOF
)
    
    echo "$metrics"
}

# Main analysis function
main() {
    echo "Analyzing tool usage patterns..." >&2
    
    # Perform analyses
    local sequences=$(analyze_sequences)
    local combinations=$(analyze_combinations)
    local inefficiencies=$(identify_inefficiencies)
    local integrations=$(suggest_integrations)
    local metrics=$(calculate_metrics)
    
    # Get most used tools
    local top_tools="[]"
    if [[ -f "$USAGE_LOG" ]]; then
        top_tools=$(jq -r '.tool.name' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -10 | while read count tool; do
            echo "{\"tool\": \"$tool\", \"count\": $count}"
        done | jq -s .)
    fi
    
    # Generate patterns report
    local patterns_report=$(cat <<EOF
{
  "analyzed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "metrics": $metrics,
  "top_tools": $top_tools,
  "common_sequences": $sequences,
  "operation_combinations": $combinations,
  "inefficiencies": $inefficiencies,
  "integration_suggestions": $integrations,
  "recommendations": [
    {
      "priority": "high",
      "category": "efficiency",
      "suggestion": "Implement caching for frequently read files",
      "based_on": "repeated_read_patterns"
    },
    {
      "priority": "medium",
      "category": "integration",
      "suggestion": "Create composite tools for common sequences",
      "based_on": "sequence_analysis"
    },
    {
      "priority": "low",
      "category": "monitoring",
      "suggestion": "Set up alerts for failed operations",
      "based_on": "success_rate_metrics"
    }
  ]
}
EOF
)
    
    # Save patterns report
    echo "$patterns_report" | jq . > "$PATTERNS_OUTPUT"
    
    # Return summary
    cat <<EOF
{
  "status": "success",
  "message": "Pattern analysis complete",
  "output_file": "$PATTERNS_OUTPUT",
  "summary": {
    "total_operations_analyzed": $(echo "$metrics" | jq -r '.total_operations'),
    "patterns_identified": $(echo "$sequences" | jq '. | length'),
    "inefficiencies_found": $(echo "$inefficiencies" | jq '. | length'),
    "integration_opportunities": $(echo "$integrations" | jq '. | length')
  }
}
EOF
}

# Execute main function
main "$@"