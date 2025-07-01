#!/bin/bash
# Agent subscription management for broadcast messages

set -euo pipefail

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Subscription directories
SUBSCRIPTION_DIR="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/subscriptions"
BROADCAST_DIR="${CLAUDE_LOGS_DIR}/metaclaude/broadcasts"
QUEUE_DIR="${BROADCAST_DIR}/queues"

# Initialize subscription system
initialize_subscription_system() {
    mkdir -p "$SUBSCRIPTION_DIR" "$QUEUE_DIR"
}

# Create subscription
create_subscription() {
    local agent_id="${1:-${AGENT_ID:-$$}}"
    local agent_type="${2:-${AGENT_TYPE:-unknown}}"
    local topics="${3:-all}"  # Comma-separated list of topics
    local filters="${4:-}"    # Optional JSON filter rules
    
    # Create subscription file
    local sub_file="${SUBSCRIPTION_DIR}/${agent_id}.sub"
    
    # Generate subscription data
    cat > "$sub_file" <<EOF
{
    "subscription_id": "$(uuidgen 2>/dev/null || echo "${agent_id}_$(date +%s)")",
    "agent_id": "$agent_id",
    "agent_type": "$agent_type",
    "topics": $(echo "$topics" | jq -R 'split(",") | map(gsub("^ +| +$";""))'),
    "filters": ${filters:-null},
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "active",
    "queue_dir": "${QUEUE_DIR}/${agent_id}"
}
EOF
    
    # Create agent queue
    local agent_queue="${QUEUE_DIR}/${agent_id}"
    mkdir -p "$agent_queue"
    
    # Create notification pipe (non-blocking)
    local notify_pipe="${agent_queue}/notify.pipe"
    [[ -p "$notify_pipe" ]] || mkfifo "$notify_pipe" 2>/dev/null || true
    
    log_info "Created subscription for agent $agent_id on topics: $topics"
    echo "$sub_file"
}

# Update subscription
update_subscription() {
    local agent_id="${1:-${AGENT_ID:-$$}}"
    local topics="${2:-}"
    local filters="${3:-}"
    
    local sub_file="${SUBSCRIPTION_DIR}/${agent_id}.sub"
    
    if [[ -f "$sub_file" ]]; then
        # Update existing subscription
        local temp_file=$(mktemp)
        jq --arg topics "$topics" --argjson filters "${filters:-null}" '
            if $topics != "" then .topics = ($topics | split(",") | map(gsub("^ +| +$";""))) else . end |
            if $filters != null then .filters = $filters else . end |
            .updated_at = now | strftime("%Y-%m-%dT%H:%M:%SZ")
        ' "$sub_file" > "$temp_file"
        mv "$temp_file" "$sub_file"
        
        log_info "Updated subscription for agent $agent_id"
    else
        # Create new subscription
        create_subscription "$agent_id" "${AGENT_TYPE:-unknown}" "$topics" "$filters"
    fi
}

# Remove subscription
remove_subscription() {
    local agent_id="${1:-${AGENT_ID:-$$}}"
    
    local sub_file="${SUBSCRIPTION_DIR}/${agent_id}.sub"
    local agent_queue="${QUEUE_DIR}/${agent_id}"
    
    # Remove subscription file
    [[ -f "$sub_file" ]] && rm "$sub_file"
    
    # Clean up queue
    [[ -d "$agent_queue" ]] && rm -rf "$agent_queue"
    
    log_info "Removed subscription for agent $agent_id"
}

# Read messages from queue
read_messages() {
    local agent_id="${1:-${AGENT_ID:-$$}}"
    local count="${2:-10}"  # Number of messages to read
    local topic_filter="${3:-}"  # Optional topic filter
    
    local agent_queue="${QUEUE_DIR}/${agent_id}"
    
    if [[ ! -d "$agent_queue" ]]; then
        log_error "No queue found for agent $agent_id"
        return 1
    fi
    
    # Find messages in queue
    local messages=()
    while IFS= read -r -d '' message_file; do
        # Apply topic filter if specified
        if [[ -n "$topic_filter" ]]; then
            local msg_topic=$(jq -r '.topic' "$message_file" 2>/dev/null || echo "")
            [[ "$msg_topic" == "$topic_filter" ]] || continue
        fi
        
        messages+=("$message_file")
    done < <(find "$agent_queue" -name "*.json" -type f -print0 | sort -z)
    
    # Return requested number of messages
    local returned=0
    for message_file in "${messages[@]}"; do
        [[ $returned -lt $count ]] || break
        
        cat "$message_file"
        echo  # Newline separator
        
        # Mark as read by moving to processed folder
        local processed_dir="${agent_queue}/processed"
        mkdir -p "$processed_dir"
        mv "$message_file" "$processed_dir/"
        
        ((returned++))
    done
    
    # Clean old processed messages (older than 1 hour)
    find "${agent_queue}/processed" -name "*.json" -mmin +60 -delete 2>/dev/null || true
}

# Filter messages based on criteria
filter_messages() {
    local agent_id="${1:-${AGENT_ID:-$$}}"
    local filter_json="${2:-}"
    
    local sub_file="${SUBSCRIPTION_DIR}/${agent_id}.sub"
    
    if [[ ! -f "$sub_file" ]]; then
        log_error "No subscription found for agent $agent_id"
        return 1
    fi
    
    # Get subscription filters
    local filters=$(jq -r '.filters // empty' "$sub_file")
    
    # Apply filters to queued messages
    local agent_queue="${QUEUE_DIR}/${agent_id}"
    
    find "$agent_queue" -name "*.json" -type f | while read -r message_file; do
        local passes_filter=true
        
        # Apply custom filter if provided
        if [[ -n "$filter_json" ]]; then
            if ! jq -e "$filter_json" "$message_file" >/dev/null 2>&1; then
                passes_filter=false
            fi
        fi
        
        # Apply subscription filters
        if [[ -n "$filters" ]] && [[ "$filters" != "null" ]]; then
            if ! echo "$filters" | jq -e '.' >/dev/null 2>&1; then
                passes_filter=false
            fi
        fi
        
        if [[ "$passes_filter" == "true" ]]; then
            cat "$message_file"
            echo  # Newline separator
        fi
    done
}

# Wait for messages (blocking with timeout)
wait_for_messages() {
    local agent_id="${1:-${AGENT_ID:-$$}}"
    local timeout="${2:-30}"  # Timeout in seconds
    local topic_filter="${3:-}"
    
    local agent_queue="${QUEUE_DIR}/${agent_id}"
    local notify_pipe="${agent_queue}/notify.pipe"
    
    if [[ ! -p "$notify_pipe" ]]; then
        log_error "No notification pipe found for agent $agent_id"
        return 1
    fi
    
    # Wait for notification with timeout
    if timeout "$timeout" cat "$notify_pipe" >/dev/null 2>&1; then
        # New message arrived, read it
        read_messages "$agent_id" 1 "$topic_filter"
    else
        log_info "No messages received within ${timeout}s timeout"
        return 1
    fi
}

# List active subscriptions
list_subscriptions() {
    local agent_filter="${1:-}"
    
    log_info "Active subscriptions:"
    
    for sub_file in "$SUBSCRIPTION_DIR"/*.sub; do
        [[ -f "$sub_file" ]] || continue
        
        local agent_id=$(jq -r '.agent_id' "$sub_file")
        local agent_type=$(jq -r '.agent_type' "$sub_file")
        local topics=$(jq -r '.topics | join(", ")' "$sub_file")
        
        # Apply filter if specified
        if [[ -n "$agent_filter" ]] && [[ "$agent_id" != *"$agent_filter"* ]]; then
            continue
        fi
        
        echo "  Agent: $agent_id ($agent_type)"
        echo "  Topics: $topics"
        echo "  Queue: ${QUEUE_DIR}/${agent_id}"
        echo ""
    done
}

# Main execution
main() {
    initialize_subscription_system
    
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        create)
            create_subscription "$@"
            ;;
        update)
            update_subscription "$@"
            ;;
        remove)
            remove_subscription "$@"
            ;;
        read)
            read_messages "$@"
            ;;
        filter)
            filter_messages "$@"
            ;;
        wait)
            wait_for_messages "$@"
            ;;
        list)
            list_subscriptions "$@"
            ;;
        help|*)
            cat <<EOF
Usage: $0 <command> [options]

Commands:
    create <agent_id> <agent_type> <topics> [filters]  Create subscription
    update <agent_id> <topics> [filters]               Update subscription
    remove <agent_id>                                  Remove subscription
    read <agent_id> [count] [topic]                   Read messages from queue
    filter <agent_id> <filter_json>                   Filter messages
    wait <agent_id> [timeout] [topic]                 Wait for new messages
    list [agent_filter]                               List active subscriptions

Topics:
    all         All broadcast messages
    system      System-level events
    task        Task-related updates
    state       State changes
    conflict    Conflict notifications
    coordination Agent coordination messages

Examples:
    $0 create researcher_001 researcher "task,state"
    $0 read researcher_001 5 task
    $0 wait orchestrator_main 60 conflict
    $0 filter coder_001 '.content | contains("error")'
EOF
            ;;
    esac
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi