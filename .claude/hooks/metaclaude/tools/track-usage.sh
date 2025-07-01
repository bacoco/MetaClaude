#!/bin/bash

# Tool Usage Tracking Hook
# Records all tool usage patterns in JSONL format
# Stores in .claude/logs/metaclaude/tool-usage.jsonl

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
USAGE_LOG="$CLAUDE_ROOT/.claude/logs/metaclaude/tool-usage.jsonl"
SESSION_FILE="$CLAUDE_ROOT/.claude/logs/metaclaude/current-session.json"

# Ensure log directory exists
mkdir -p "$(dirname "$USAGE_LOG")"

# Function to get or create session ID
get_session_id() {
    if [[ -f "$SESSION_FILE" ]]; then
        jq -r '.session_id // empty' "$SESSION_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Function to create new session
create_session() {
    local session_id=$(uuidgen 2>/dev/null || date +%s%N | sha256sum | head -c 16)
    local session_data=$(cat <<EOF
{
  "session_id": "$session_id",
  "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tool_count": 0,
  "last_activity": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)
    echo "$session_data" > "$SESSION_FILE"
    echo "$session_id"
}

# Function to update session activity
update_session() {
    local session_id="$1"
    if [[ -f "$SESSION_FILE" ]]; then
        local tool_count=$(jq -r '.tool_count // 0' "$SESSION_FILE")
        tool_count=$((tool_count + 1))
        jq ".tool_count = $tool_count | .last_activity = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$SESSION_FILE" > "${SESSION_FILE}.tmp" && mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
    fi
}

# Function to categorize tool
categorize_tool() {
    local tool_name="$1"
    case "$tool_name" in
        read_file|Read)
            echo "read"
            ;;
        write_file|Write|Edit|MultiEdit)
            echo "write"
            ;;
        run_shell_command|Bash)
            echo "execute"
            ;;
        search_file_content|Grep|Glob)
            echo "search"
            ;;
        list_files|LS)
            echo "browse"
            ;;
        *)
            echo "other"
            ;;
    esac
}

# Function to extract operation type from context
extract_operation() {
    local context="$1"
    local context_lower=$(echo "$context" | tr '[:upper:]' '[:lower:]')
    
    # Common operation patterns
    if [[ "$context_lower" =~ (analyz|review|inspect|check) ]]; then
        echo "analysis"
    elif [[ "$context_lower" =~ (generat|creat|build|design) ]]; then
        echo "generation"
    elif [[ "$context_lower" =~ (sav|export|writ|stor) ]]; then
        echo "persistence"
    elif [[ "$context_lower" =~ (search|find|locat|discover) ]]; then
        echo "discovery"
    elif [[ "$context_lower" =~ (test|validat|verif|check) ]]; then
        echo "validation"
    elif [[ "$context_lower" =~ (install|setup|configur|init) ]]; then
        echo "setup"
    else
        echo "general"
    fi
}

# Function to track tool sequence
track_sequence() {
    local tool_name="$1"
    local sequence_file="$CLAUDE_ROOT/.claude/logs/metaclaude/tool-sequence.tmp"
    
    # Append to sequence
    echo "$tool_name" >> "$sequence_file"
    
    # Keep only last 10 tools
    if [[ -f "$sequence_file" ]]; then
        tail -n 10 "$sequence_file" > "${sequence_file}.new" && mv "${sequence_file}.new" "$sequence_file"
    fi
    
    # Get previous tool
    if [[ -f "$sequence_file" && $(wc -l < "$sequence_file") -gt 1 ]]; then
        tail -n 2 "$sequence_file" | head -n 1
    else
        echo "none"
    fi
}

# Main tracking function
main() {
    local input_json="${1:-}"
    
    if [[ -z "$input_json" ]]; then
        # Return error if no input
        cat <<EOF
{
  "status": "error",
  "message": "No tool usage data provided"
}
EOF
        return 1
    fi
    
    # Get or create session
    local session_id=$(get_session_id)
    if [[ -z "$session_id" ]]; then
        session_id=$(create_session)
    fi
    
    # Parse input
    local tool_name=$(echo "$input_json" | jq -r '.tool_name // empty')
    local context=$(echo "$input_json" | jq -r '.context // empty')
    local parameters=$(echo "$input_json" | jq -c '.parameters // {}')
    local result_status=$(echo "$input_json" | jq -r '.result_status // "unknown"')
    local execution_time=$(echo "$input_json" | jq -r '.execution_time // 0')
    local user_request=$(echo "$input_json" | jq -r '.user_request // empty')
    local agent_type=$(echo "$input_json" | jq -r '.agent_type // "unknown"')
    
    # Categorize and analyze
    local tool_category=$(categorize_tool "$tool_name")
    local operation_type=$(extract_operation "$context")
    local previous_tool=$(track_sequence "$tool_name")
    
    # Create usage record
    local usage_record=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "session_id": "$session_id",
  "tool": {
    "name": "$tool_name",
    "category": "$tool_category",
    "parameters": $parameters
  },
  "context": {
    "operation_type": "$operation_type",
    "description": "$context",
    "user_request": "$user_request",
    "agent_type": "$agent_type"
  },
  "execution": {
    "status": "$result_status",
    "duration_ms": $execution_time,
    "previous_tool": "$previous_tool"
  },
  "metadata": {
    "day_of_week": "$(date +%A)",
    "hour_of_day": $(date +%H),
    "project_path": "$CLAUDE_ROOT"
  }
}
EOF
)
    
    # Append to log file
    echo "$usage_record" | jq -c . >> "$USAGE_LOG"
    
    # Update session
    update_session "$session_id"
    
    # Return success
    cat <<EOF
{
  "status": "success",
  "message": "Tool usage tracked",
  "session_id": "$session_id",
  "record": $usage_record
}
EOF
}

# Execute main function with input
main "$@"