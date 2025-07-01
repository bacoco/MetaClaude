#!/bin/bash
# PostToolUse hook: broadcast.sh - Real-time agent communication broadcasting

set -euo pipefail

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Broadcast directories
BROADCAST_DIR="${CLAUDE_LOGS_DIR}/metaclaude/broadcasts"
SUBSCRIPTION_DIR="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/subscriptions"
TOPIC_DIR="${BROADCAST_DIR}/topics"

# Initialize directories
initialize_broadcast_system() {
    mkdir -p "$BROADCAST_DIR" "$SUBSCRIPTION_DIR" "$TOPIC_DIR"
    mkdir -p "$TOPIC_DIR"/{system,task,state,conflict,coordination}
}

# Extract topic from tool usage or message content
extract_topic() {
    local tool_name="$1"
    local content="$2"
    
    # Default topic mappings
    case "$tool_name" in
        "TodoWrite"|"TodoRead")
            echo "task"
            ;;
        "Task"|"Agent")
            echo "coordination"
            ;;
        "Write"|"Edit"|"MultiEdit")
            echo "state"
            ;;
        "WebSearch"|"WebFetch")
            echo "system"
            ;;
        *)
            # Extract from content patterns
            if [[ "$content" =~ conflict|collision|contention ]]; then
                echo "conflict"
            elif [[ "$content" =~ coordinate|orchestrate|delegate ]]; then
                echo "coordination"
            elif [[ "$content" =~ state|update|modify ]]; then
                echo "state"
            else
                echo "system"
            fi
            ;;
    esac
}

# Generate broadcast message
generate_broadcast_message() {
    local agent_type="${AGENT_TYPE:-unknown}"
    local agent_id="${AGENT_ID:-$$}"
    local timestamp="$(date +%s.%N)"
    local tool_name="$1"
    local content="$2"
    local topic="$3"
    
    # Create message payload
    cat <<EOF
{
    "message_id": "$(uuidgen 2>/dev/null || echo "${timestamp}_${agent_id}")",
    "timestamp": "$timestamp",
    "agent": {
        "type": "$agent_type",
        "id": "$agent_id",
        "pid": "$$"
    },
    "tool": {
        "name": "$tool_name",
        "status": "${TOOL_STATUS:-success}"
    },
    "topic": "$topic",
    "content": $(echo "$content" | jq -Rs .),
    "metadata": {
        "session_id": "${SESSION_ID:-unknown}",
        "task_id": "${TASK_ID:-unknown}",
        "parent_task": "${PARENT_TASK:-none}"
    }
}
EOF
}

# Broadcast to subscribers
broadcast_to_subscribers() {
    local topic="$1"
    local message="$2"
    local message_file="$3"
    
    # Write to topic directory
    cp "$message_file" "$TOPIC_DIR/$topic/"
    
    # Find active subscribers for this topic
    if [[ -d "$SUBSCRIPTION_DIR" ]]; then
        for sub_file in "$SUBSCRIPTION_DIR"/*.sub; do
            [[ -f "$sub_file" ]] || continue
            
            # Check if subscriber is interested in this topic
            if grep -q "\"topic\": \"$topic\"" "$sub_file" 2>/dev/null || \
               grep -q "\"topic\": \"all\"" "$sub_file" 2>/dev/null; then
                
                # Extract subscriber info
                local sub_agent=$(jq -r '.agent_id' "$sub_file" 2>/dev/null || echo "unknown")
                local sub_queue="${BROADCAST_DIR}/queues/${sub_agent}"
                
                # Create subscriber queue if needed
                mkdir -p "$sub_queue"
                
                # Copy message to subscriber queue
                cp "$message_file" "$sub_queue/"
                
                # Send notification if subscriber has a notification pipe
                local notify_pipe="${sub_queue}/notify.pipe"
                if [[ -p "$notify_pipe" ]]; then
                    echo "$message_file" > "$notify_pipe" 2>/dev/null || true
                fi
            fi
        done
    fi
}

# Main broadcast function
broadcast_message() {
    local tool_name="${1:-unknown}"
    local content="${2:-}"
    
    # Extract topic
    local topic=$(extract_topic "$tool_name" "$content")
    
    # Generate message
    local message=$(generate_broadcast_message "$tool_name" "$content" "$topic")
    
    # Save message
    local timestamp=$(date +%s.%N)
    local message_file="${BROADCAST_DIR}/${timestamp}_${AGENT_ID:-$$}_${topic}.json"
    echo "$message" > "$message_file"
    
    # Broadcast to subscribers
    broadcast_to_subscribers "$topic" "$message" "$message_file"
    
    # Log broadcast
    log_info "Broadcast message to topic '$topic' from agent ${AGENT_TYPE:-unknown}/${AGENT_ID:-$$}"
    
    # Clean old broadcasts (older than 1 hour)
    find "$BROADCAST_DIR" -name "*.json" -mmin +60 -delete 2>/dev/null || true
}

# PostToolUse hook handler
handle_post_tool_use() {
    local tool_name="$1"
    local tool_output="${2:-}"
    
    # Skip broadcasting for certain tools to avoid loops
    case "$tool_name" in
        "Bash"|"Read"|"LS"|"Glob"|"Grep")
            # Only broadcast if significant
            if [[ -n "$tool_output" ]] && [[ ${#tool_output} -gt 100 ]]; then
                broadcast_message "$tool_name" "$tool_output"
            fi
            ;;
        *)
            # Always broadcast for state-changing tools
            broadcast_message "$tool_name" "$tool_output"
            ;;
    esac
}

# Main execution
main() {
    initialize_broadcast_system
    
    # Get tool information from environment or args
    local tool_name="${TOOL_NAME:-${1:-unknown}}"
    local tool_output="${TOOL_OUTPUT:-${2:-}}"
    
    # Handle the broadcast
    handle_post_tool_use "$tool_name" "$tool_output"
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi