#!/bin/bash

# Tool Usage Report Generator
# Creates daily/weekly usage reports with metrics and insights
# Shows most/least used tools and efficiency metrics

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
USAGE_LOG="$CLAUDE_ROOT/.claude/logs/metaclaude/tool-usage.jsonl"
REPORTS_DIR="$CLAUDE_ROOT/.claude/logs/metaclaude/reports"
PATTERNS_FILE="$CLAUDE_ROOT/.claude/logs/metaclaude/usage-patterns.json"

# Ensure directories exist
mkdir -p "$REPORTS_DIR"

# Function to get date range
get_date_range() {
    local period="${1:-daily}"
    local end_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local start_date=""
    
    case "$period" in
        daily)
            start_date=$(date -u -d "1 day ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-1d +"%Y-%m-%dT%H:%M:%SZ")
            ;;
        weekly)
            start_date=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ")
            ;;
        monthly)
            start_date=$(date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-30d +"%Y-%m-%dT%H:%M:%SZ")
            ;;
        *)
            start_date=$(date -u -d "1 day ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-1d +"%Y-%m-%dT%H:%M:%SZ")
            ;;
    esac
    
    echo "$start_date|$end_date"
}

# Function to filter logs by date range
filter_logs() {
    local start_date="$1"
    local end_date="$2"
    local filtered_file=$(mktemp)
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        touch "$filtered_file"
        echo "$filtered_file"
        return
    fi
    
    # Filter logs within date range
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | jq -r '.timestamp // empty')
        if [[ -n "$timestamp" ]]; then
            # Simple string comparison works for ISO 8601 dates
            if [[ "$timestamp" > "$start_date" && "$timestamp" < "$end_date" ]]; then
                echo "$line" >> "$filtered_file"
            fi
        fi
    done < "$USAGE_LOG"
    
    echo "$filtered_file"
}

# Function to calculate tool statistics
calculate_tool_stats() {
    local log_file="$1"
    local stats_json="{}"
    
    if [[ ! -s "$log_file" ]]; then
        echo "$stats_json"
        return
    fi
    
    # Most used tools
    local most_used=$(jq -r '.tool.name' "$log_file" 2>/dev/null | sort | uniq -c | sort -rn | head -10 | while read count tool; do
        echo "{\"tool\": \"$tool\", \"count\": $count, \"percentage\": 0}"
    done | jq -s .)
    
    # Calculate percentages
    local total=$(wc -l < "$log_file")
    if [[ $total -gt 0 ]]; then
        most_used=$(echo "$most_used" | jq --argjson total "$total" 'map(. + {percentage: ((.count / $total) * 100 | round)})')
    fi
    
    # Least used tools (from all available tools)
    local all_tools=("read_file" "write_file" "run_shell_command" "search_file_content" "list_files" "Read" "Write" "Edit" "MultiEdit" "Bash" "Grep" "Glob" "LS")
    local least_used="[]"
    
    for tool in "${all_tools[@]}"; do
        local count=$(jq -r "select(.tool.name == \"$tool\") | .tool.name" "$log_file" 2>/dev/null | wc -l)
        if [[ $count -lt 5 ]]; then
            least_used=$(echo "$least_used" | jq ". += [{\"tool\": \"$tool\", \"count\": $count}]")
        fi
    done
    
    # Tool category distribution
    local categories=$(jq -r '.tool.category' "$log_file" 2>/dev/null | sort | uniq -c | sort -rn | while read count category; do
        echo "{\"category\": \"$category\", \"count\": $count}"
    done | jq -s .)
    
    stats_json=$(cat <<EOF
{
  "most_used": $most_used,
  "least_used": $least_used,
  "category_distribution": $categories,
  "total_operations": $total
}
EOF
)
    
    echo "$stats_json"
}

# Function to calculate efficiency metrics
calculate_efficiency() {
    local log_file="$1"
    local efficiency_json="{}"
    
    if [[ ! -s "$log_file" ]]; then
        echo "$efficiency_json"
        return
    fi
    
    # Success rate
    local total=$(wc -l < "$log_file")
    local successful=$(jq -r 'select(.execution.status == "success") | .tool.name' "$log_file" 2>/dev/null | wc -l)
    local failed=$(jq -r 'select(.execution.status == "failed") | .tool.name' "$log_file" 2>/dev/null | wc -l)
    
    # Execution time statistics
    local avg_time=$(jq -r '.execution.duration_ms // 0' "$log_file" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
    local max_time=$(jq -r '.execution.duration_ms // 0' "$log_file" 2>/dev/null | sort -rn | head -1)
    local min_time=$(jq -r '.execution.duration_ms // 0' "$log_file" 2>/dev/null | sort -n | head -1)
    
    # Peak usage hours
    local peak_hours=$(jq -r '.metadata.hour_of_day' "$log_file" 2>/dev/null | sort | uniq -c | sort -rn | head -5 | while read count hour; do
        echo "{\"hour\": $hour, \"operations\": $count}"
    done | jq -s .)
    
    # Agent type distribution
    local agent_dist=$(jq -r '.context.agent_type // "unknown"' "$log_file" 2>/dev/null | sort | uniq -c | sort -rn | while read count agent; do
        echo "{\"agent\": \"$agent\", \"operations\": $count}"
    done | jq -s .)
    
    efficiency_json=$(cat <<EOF
{
  "success_rate": $(awk "BEGIN {if($total>0) printf \"%.2f\", $successful / $total * 100; else print 0}"),
  "failure_rate": $(awk "BEGIN {if($total>0) printf \"%.2f\", $failed / $total * 100; else print 0}"),
  "execution_time": {
    "average_ms": $avg_time,
    "max_ms": ${max_time:-0},
    "min_ms": ${min_time:-0}
  },
  "peak_usage_hours": $peak_hours,
  "agent_distribution": $agent_dist
}
EOF
)
    
    echo "$efficiency_json"
}

# Function to generate insights
generate_insights() {
    local stats="$1"
    local efficiency="$2"
    local patterns_file="$3"
    local insights="[]"
    
    # Insight: Most used tool
    local top_tool=$(echo "$stats" | jq -r '.most_used[0].tool // "none"')
    local top_percentage=$(echo "$stats" | jq -r '.most_used[0].percentage // 0')
    insights=$(echo "$insights" | jq ". += [{
        \"type\": \"usage\",
        \"priority\": \"info\",
        \"message\": \"Most frequently used tool is $top_tool, accounting for ${top_percentage}% of operations\"
    }]")
    
    # Insight: Success rate
    local success_rate=$(echo "$efficiency" | jq -r '.success_rate // 0')
    if (( $(echo "$success_rate < 95" | bc -l) )); then
        insights=$(echo "$insights" | jq ". += [{
            \"type\": \"performance\",
            \"priority\": \"warning\",
            \"message\": \"Success rate is ${success_rate}%, consider investigating failed operations\"
        }]")
    fi
    
    # Insight: Underutilized tools
    local least_used_count=$(echo "$stats" | jq '.least_used | length')
    if [[ $least_used_count -gt 3 ]]; then
        insights=$(echo "$insights" | jq ". += [{
            \"type\": \"optimization\",
            \"priority\": \"suggestion\",
            \"message\": \"$least_used_count tools are underutilized. Consider training or documentation updates\"
        }]")
    fi
    
    # Insight: Peak hours
    local peak_hour=$(echo "$efficiency" | jq -r '.peak_usage_hours[0].hour // 0')
    insights=$(echo "$insights" | jq ". += [{
        \"type\": \"pattern\",
        \"priority\": \"info\",
        \"message\": \"Peak usage occurs at hour $peak_hour UTC\"
    }]")
    
    # Load pattern insights if available
    if [[ -f "$patterns_file" ]]; then
        local inefficiency_count=$(jq '.inefficiencies | length' "$patterns_file" 2>/dev/null || echo 0)
        if [[ $inefficiency_count -gt 0 ]]; then
            insights=$(echo "$insights" | jq ". += [{
                \"type\": \"efficiency\",
                \"priority\": \"improvement\",
                \"message\": \"$inefficiency_count inefficient patterns detected. Run pattern analysis for details\"
            }]")
        fi
    fi
    
    echo "$insights"
}

# Function to create markdown report
create_markdown_report() {
    local period="$1"
    local stats="$2"
    local efficiency="$3"
    local insights="$4"
    local report_date=$(date +"%Y-%m-%d")
    
    cat <<EOF
# Tool Usage Report - ${period^}
Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Executive Summary
- **Total Operations**: $(echo "$stats" | jq -r '.total_operations')
- **Success Rate**: $(echo "$efficiency" | jq -r '.success_rate')%
- **Average Execution Time**: $(echo "$efficiency" | jq -r '.execution_time.average_ms')ms

## Most Used Tools
| Tool | Usage Count | Percentage |
|------|------------|------------|
$(echo "$stats" | jq -r '.most_used[] | "| \(.tool) | \(.count) | \(.percentage)% |"')

## Least Used Tools
| Tool | Usage Count |
|------|------------|
$(echo "$stats" | jq -r '.least_used[] | "| \(.tool) | \(.count) |"')

## Category Distribution
$(echo "$stats" | jq -r '.category_distribution[] | "- **\(.category)**: \(.count) operations"')

## Efficiency Metrics

### Execution Time
- **Average**: $(echo "$efficiency" | jq -r '.execution_time.average_ms')ms
- **Maximum**: $(echo "$efficiency" | jq -r '.execution_time.max_ms')ms
- **Minimum**: $(echo "$efficiency" | jq -r '.execution_time.min_ms')ms

### Peak Usage Hours (UTC)
$(echo "$efficiency" | jq -r '.peak_usage_hours[] | "- Hour \(.hour): \(.operations) operations"')

### Agent Distribution
$(echo "$efficiency" | jq -r '.agent_distribution[] | "- **\(.agent)**: \(.operations) operations"')

## Insights & Recommendations
$(echo "$insights" | jq -r '.[] | "### \(.priority | ascii_upcase): \(.type)\n\(.message)\n"')

## Action Items
1. Review and address any failed operations
2. Investigate underutilized tools for training opportunities
3. Optimize frequently used tool sequences
4. Consider implementing suggested tool integrations

---
*Report generated by MetaClaude Tool Analytics*
EOF
}

# Main report generation function
main() {
    local period="${1:-daily}"
    local format="${2:-json}"
    
    echo "Generating $period tool usage report..." >&2
    
    # Get date range
    IFS='|' read -r start_date end_date <<< "$(get_date_range "$period")"
    
    # Filter logs for period
    local filtered_log=$(filter_logs "$start_date" "$end_date")
    
    # Calculate statistics
    local stats=$(calculate_tool_stats "$filtered_log")
    local efficiency=$(calculate_efficiency "$filtered_log")
    local insights=$(generate_insights "$stats" "$efficiency" "$PATTERNS_FILE")
    
    # Generate report
    local report_json=$(cat <<EOF
{
  "report_type": "$period",
  "period": {
    "start": "$start_date",
    "end": "$end_date"
  },
  "statistics": $stats,
  "efficiency": $efficiency,
  "insights": $insights,
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)
    
    # Save report
    local report_filename="tool-usage-${period}-$(date +%Y%m%d-%H%M%S)"
    
    if [[ "$format" == "markdown" || "$format" == "md" ]]; then
        create_markdown_report "$period" "$stats" "$efficiency" "$insights" > "$REPORTS_DIR/${report_filename}.md"
        echo "{\"status\": \"success\", \"report_file\": \"$REPORTS_DIR/${report_filename}.md\", \"format\": \"markdown\"}"
    else
        echo "$report_json" | jq . > "$REPORTS_DIR/${report_filename}.json"
        
        # Also create markdown version
        create_markdown_report "$period" "$stats" "$efficiency" "$insights" > "$REPORTS_DIR/${report_filename}.md"
        
        echo "{\"status\": \"success\", \"report_file\": \"$REPORTS_DIR/${report_filename}.json\", \"markdown_file\": \"$REPORTS_DIR/${report_filename}.md\", \"format\": \"json\"}"
    fi
    
    # Cleanup temp file
    rm -f "$filtered_log"
}

# Execute main function with arguments
main "$@"