#!/bin/bash
# hook-metrics.sh - Track and report MetaClaude hook execution metrics
# Provides insights into hook performance and usage patterns

set -euo pipefail

# Paths
METRICS_DIR="${HOME}/.claude/hooks/metaclaude/monitoring/metrics"
METRICS_FILE="${METRICS_DIR}/hook_metrics.json"
DAILY_METRICS="${METRICS_DIR}/daily_$(date +%Y-%m-%d).json"

# Ensure directories exist
mkdir -p "$METRICS_DIR"

# Initialize metrics file if not exists
if [[ ! -f "$METRICS_FILE" ]]; then
    echo '{
        "total_executions": 0,
        "hooks": {},
        "last_updated": null
    }' | jq . > "$METRICS_FILE"
fi

# Function to record metric
record_metric() {
    local hook_name="$1"
    local status="$2"
    local duration_ms="${3:-0}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Update main metrics
    jq --arg hook "$hook_name" \
       --arg status "$status" \
       --arg duration "$duration_ms" \
       --arg ts "$timestamp" \
       '
       .total_executions += 1 |
       .last_updated = $ts |
       .hooks[$hook] = (.hooks[$hook] // {
           "executions": 0,
           "success": 0,
           "warning": 0,
           "error": 0,
           "total_duration_ms": 0,
           "avg_duration_ms": 0,
           "last_execution": null
       }) |
       .hooks[$hook].executions += 1 |
       .hooks[$hook].last_execution = $ts |
       .hooks[$hook].total_duration_ms += ($duration | tonumber) |
       .hooks[$hook].avg_duration_ms = (.hooks[$hook].total_duration_ms / .hooks[$hook].executions) |
       if $status == "success" then .hooks[$hook].success += 1
       elif $status == "warning" then .hooks[$hook].warning += 1
       elif $status == "error" then .hooks[$hook].error += 1
       else . end
       ' "$METRICS_FILE" > "${METRICS_FILE}.tmp" && mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
    
    # Update daily metrics
    if [[ ! -f "$DAILY_METRICS" ]]; then
        echo '{"date": "'$(date +%Y-%m-%d)'", "hooks": {}}' | jq . > "$DAILY_METRICS"
    fi
    
    jq --arg hook "$hook_name" \
       --arg status "$status" \
       --arg duration "$duration_ms" \
       --arg ts "$timestamp" \
       '
       .hooks[$hook] = (.hooks[$hook] // []) |
       .hooks[$hook] += [{
           "timestamp": $ts,
           "status": $status,
           "duration_ms": ($duration | tonumber)
       }]
       ' "$DAILY_METRICS" > "${DAILY_METRICS}.tmp" && mv "${DAILY_METRICS}.tmp" "$DAILY_METRICS"
}

# Function to get hook statistics
get_hook_stats() {
    local hook_name="${1:-all}"
    
    if [[ "$hook_name" == "all" ]]; then
        jq . "$METRICS_FILE"
    else
        jq --arg hook "$hook_name" '.hooks[$hook] // {"error": "Hook not found"}' "$METRICS_FILE"
    fi
}

# Function to generate report
generate_report() {
    local report_type="${1:-summary}"
    
    case "$report_type" in
        summary)
            jq '
            {
                "summary": {
                    "total_executions": .total_executions,
                    "total_hooks": (.hooks | length),
                    "last_updated": .last_updated
                },
                "top_hooks": (
                    .hooks | to_entries | 
                    sort_by(-.value.executions) | 
                    .[0:5] | 
                    map({
                        "name": .key,
                        "executions": .value.executions,
                        "success_rate": ((.value.success / .value.executions * 100) | round)
                    })
                ),
                "performance": (
                    .hooks | to_entries |
                    map({
                        "hook": .key,
                        "avg_duration_ms": (.value.avg_duration_ms | round)
                    }) |
                    sort_by(-.avg_duration_ms) |
                    .[0:5]
                )
            }
            ' "$METRICS_FILE"
            ;;
        
        daily)
            if [[ -f "$DAILY_METRICS" ]]; then
                jq '
                {
                    "date": .date,
                    "total_executions": (.hooks | to_entries | map(.value | length) | add),
                    "hooks_used": (.hooks | length),
                    "hourly_distribution": (
                        .hooks | to_entries |
                        map(.value[]) |
                        group_by(.timestamp[0:13]) |
                        map({
                            "hour": .[0].timestamp[0:13],
                            "count": length
                        })
                    )
                }
                ' "$DAILY_METRICS"
            else
                echo '{"error": "No daily metrics available"}'
            fi
            ;;
        
        errors)
            jq '
            {
                "error_summary": (
                    .hooks | to_entries |
                    map(select(.value.error > 0)) |
                    map({
                        "hook": .key,
                        "errors": .value.error,
                        "error_rate": ((.value.error / .value.executions * 100) | round)
                    })
                )
            }
            ' "$METRICS_FILE"
            ;;
    esac
}

# Function to clean old metrics
clean_old_metrics() {
    local days_to_keep="${1:-7}"
    find "$METRICS_DIR" -name "daily_*.json" -mtime +$days_to_keep -delete
}

# Main command handling
case "${1:-help}" in
    record)
        record_metric "$2" "$3" "${4:-0}"
        ;;
    stats)
        get_hook_stats "${2:-all}"
        ;;
    report)
        generate_report "${2:-summary}"
        ;;
    clean)
        clean_old_metrics "${2:-7}"
        ;;
    help|*)
        echo "Usage: $0 {record|stats|report|clean|help}"
        echo ""
        echo "Commands:"
        echo "  record <hook_name> <status> [duration_ms]  - Record hook execution"
        echo "  stats [hook_name]                          - Get statistics for hook(s)"
        echo "  report [type]                              - Generate report (summary|daily|errors)"
        echo "  clean [days]                               - Clean metrics older than N days"
        echo "  help                                       - Show this help"
        ;;
esac