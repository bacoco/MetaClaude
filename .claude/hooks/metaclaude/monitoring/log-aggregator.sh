#!/bin/bash
# log-aggregator.sh - Collect and analyze MetaClaude hook logs
# Provides centralized log management and analysis

set -euo pipefail

# Paths
LOG_BASE="${HOME}/.claude/hooks/metaclaude/monitoring"
AGGREGATED_LOG="${LOG_BASE}/aggregated.log"
ANALYSIS_OUTPUT="${LOG_BASE}/analysis"

# Ensure directories exist
mkdir -p "$LOG_BASE" "$ANALYSIS_OUTPUT"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to collect logs
collect_logs() {
    local since="${1:-1 hour ago}"
    local output_file="${2:-$AGGREGATED_LOG}"
    
    echo -e "${BLUE}Collecting logs since: $since${NC}"
    
    # Clear output file
    > "$output_file"
    
    # Find all log files
    local log_files=$(find "$LOG_BASE" -name "*.log" -type f 2>/dev/null | grep -v "aggregated.log")
    
    if [[ -z "$log_files" ]]; then
        echo -e "${YELLOW}No log files found${NC}"
        return 1
    fi
    
    # Process each log file
    while IFS= read -r log_file; do
        local log_name=$(basename "$log_file" .log)
        echo -e "${GREEN}Processing: $log_name${NC}"
        
        # Extract logs based on timestamp
        local since_timestamp=$(date -d "$since" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v-1H '+%Y-%m-%d %H:%M:%S')
        
        # Add source identifier and filter by date
        awk -v source="$log_name" -v since="$since_timestamp" '
            BEGIN { OFS="|" }
            {
                # Extract timestamp from log line
                if (match($0, /\[([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\]/, ts)) {
                    timestamp = ts[1]
                    if (timestamp >= since) {
                        print timestamp, source, $0
                    }
                }
            }
        ' "$log_file" >> "$output_file"
    done <<< "$log_files"
    
    # Sort by timestamp
    sort -t'|' -k1,1 "$output_file" -o "$output_file"
    
    local line_count=$(wc -l < "$output_file")
    echo -e "${GREEN}Collected $line_count log entries${NC}"
}

# Function to analyze logs
analyze_logs() {
    local input_file="${1:-$AGGREGATED_LOG}"
    local analysis_type="${2:-summary}"
    
    case "$analysis_type" in
        summary)
            echo -e "\n${BLUE}=== Log Summary ===${NC}"
            
            # Count by source
            echo -e "\n${GREEN}Logs by Source:${NC}"
            cut -d'|' -f2 "$input_file" | sort | uniq -c | sort -rn
            
            # Count by hour
            echo -e "\n${GREEN}Logs by Hour:${NC}"
            cut -d'|' -f1 "$input_file" | cut -d' ' -f1,2 | cut -d':' -f1 | sort | uniq -c
            
            # Error patterns
            echo -e "\n${GREEN}Error Patterns:${NC}"
            grep -i "error\|fail\|exception" "$input_file" | cut -d'|' -f2 | sort | uniq -c | sort -rn | head -10
            ;;
        
        errors)
            echo -e "\n${RED}=== Error Analysis ===${NC}"
            
            # Extract error logs
            local error_file="${ANALYSIS_OUTPUT}/errors_$(date +%Y%m%d_%H%M%S).log"
            grep -i "error\|fail\|exception" "$input_file" > "$error_file"
            
            # Group errors by type
            echo -e "\n${GREEN}Error Types:${NC}"
            awk -F'|' '{print $3}' "$error_file" | 
                grep -oE "(ERROR|FAIL|Exception):[^:]*" | 
                sort | uniq -c | sort -rn
            
            # Recent errors
            echo -e "\n${GREEN}Recent Errors (last 10):${NC}"
            tail -10 "$error_file" | while IFS='|' read -r timestamp source message; do
                echo -e "${YELLOW}[$timestamp]${NC} ${RED}$source${NC}: ${message#*]}"
            done
            ;;
        
        performance)
            echo -e "\n${BLUE}=== Performance Analysis ===${NC}"
            
            # Extract duration patterns
            echo -e "\n${GREEN}Operation Durations:${NC}"
            grep -oE "duration[: ]+[0-9]+ms" "$input_file" | 
                sed 's/[^0-9]//g' | 
                awk '{sum+=$1; count++} END {if(count>0) printf "Average: %.2fms, Total: %d operations\n", sum/count, count}'
            
            # Slow operations
            echo -e "\n${GREEN}Slow Operations (>1000ms):${NC}"
            grep -E "duration[: ]+[0-9]{4,}ms" "$input_file" | tail -10
            ;;
        
        patterns)
            echo -e "\n${BLUE}=== Pattern Analysis ===${NC}"
            
            # Common patterns
            echo -e "\n${GREEN}Most Common Log Patterns:${NC}"
            awk -F'|' '{
                # Remove timestamps and specific values
                gsub(/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/, "TIMESTAMP", $3)
                gsub(/[0-9]+ms/, "Nms", $3)
                gsub(/[0-9]+/, "N", $3)
                print $3
            }' "$input_file" | sort | uniq -c | sort -rn | head -20
            ;;
    esac
}

# Function to create report
create_report() {
    local report_file="${ANALYSIS_OUTPUT}/report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "MetaClaude Hook Log Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""
        
        # Collect recent logs
        collect_logs "1 hour ago" "${ANALYSIS_OUTPUT}/temp.log" 2>&1
        
        # Run all analyses
        for analysis in summary errors performance patterns; do
            analyze_logs "${ANALYSIS_OUTPUT}/temp.log" "$analysis" 2>&1
            echo ""
        done
        
        # Cleanup
        rm -f "${ANALYSIS_OUTPUT}/temp.log"
        
    } > "$report_file"
    
    echo -e "${GREEN}Report created: $report_file${NC}"
    cat "$report_file"
}

# Function to monitor logs in real-time
monitor_logs() {
    echo -e "${BLUE}Monitoring logs in real-time (Ctrl+C to stop)...${NC}"
    
    # Create named pipe for multiplexing
    local pipe="${LOG_BASE}/.monitor_pipe"
    mkfifo "$pipe" 2>/dev/null || true
    
    # Start tail processes for all log files
    find "$LOG_BASE" -name "*.log" -type f ! -name "aggregated.log" -exec tail -f {} + | 
    while IFS= read -r line; do
        # Add timestamp and color based on content
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        if echo "$line" | grep -qi "error\|fail"; then
            echo -e "${RED}[$timestamp] $line${NC}"
        elif echo "$line" | grep -qi "warning\|warn"; then
            echo -e "${YELLOW}[$timestamp] $line${NC}"
        elif echo "$line" | grep -qi "success\|complete"; then
            echo -e "${GREEN}[$timestamp] $line${NC}"
        else
            echo "[$timestamp] $line"
        fi
    done
}

# Function to clean old logs
clean_old_logs() {
    local days="${1:-7}"
    echo -e "${BLUE}Cleaning logs older than $days days...${NC}"
    
    local count=0
    while IFS= read -r file; do
        echo "Removing: $file"
        rm -f "$file"
        ((count++))
    done < <(find "$LOG_BASE" -name "*.log" -mtime +$days -type f)
    
    echo -e "${GREEN}Cleaned $count old log files${NC}"
}

# Main command handling
case "${1:-help}" in
    collect)
        collect_logs "${2:-1 hour ago}" "${3:-$AGGREGATED_LOG}"
        ;;
    analyze)
        analyze_logs "${3:-$AGGREGATED_LOG}" "${2:-summary}"
        ;;
    report)
        create_report
        ;;
    monitor)
        monitor_logs
        ;;
    clean)
        clean_old_logs "${2:-7}"
        ;;
    help|*)
        echo "Usage: $0 {collect|analyze|report|monitor|clean|help}"
        echo ""
        echo "Commands:"
        echo "  collect [since] [output]     - Collect logs since timestamp"
        echo "  analyze [type] [input]       - Analyze logs (summary|errors|performance|patterns)"
        echo "  report                       - Generate comprehensive report"
        echo "  monitor                      - Monitor logs in real-time"
        echo "  clean [days]                 - Clean logs older than N days"
        echo "  help                         - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 collect '2 hours ago'"
        echo "  $0 analyze errors"
        echo "  $0 monitor"
        ;;
esac