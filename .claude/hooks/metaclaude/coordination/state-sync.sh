#!/bin/bash
# State synchronization between agents with conflict resolution

set -euo pipefail

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Sync directories
SYNC_DIR="${CLAUDE_LOGS_DIR}/metaclaude/sync"
SYNC_QUEUE="${SYNC_DIR}/queue"
SYNC_CONFLICTS="${SYNC_DIR}/conflicts"
SYNC_HISTORY="${SYNC_DIR}/history"

# Initialize sync system
initialize_sync_system() {
    mkdir -p "$SYNC_QUEUE" "$SYNC_CONFLICTS" "$SYNC_HISTORY"
}

# Vector clock implementation for distributed consistency
get_vector_clock() {
    local namespace="${1:-main}"
    local clock_file="${SYNC_DIR}/${namespace}.vclock"
    
    if [[ -f "$clock_file" ]]; then
        cat "$clock_file"
    else
        echo '{}'
    fi
}

update_vector_clock() {
    local namespace="${1:-main}"
    local agent_id="${2:-${AGENT_ID:-$$}}"
    local clock_file="${SYNC_DIR}/${namespace}.vclock"
    
    # Get current clock
    local clock=$(get_vector_clock "$namespace")
    
    # Increment agent's clock
    local new_clock=$(echo "$clock" | jq --arg agent "$agent_id" '
        .[$agent] = ((.[$agent] // 0) + 1)
    ')
    
    echo "$new_clock" > "$clock_file"
    echo "$new_clock"
}

compare_vector_clocks() {
    local clock1="$1"
    local clock2="$2"
    
    # Returns: "equal", "before", "after", or "concurrent"
    local result=$(jq -n \
        --argjson c1 "$clock1" \
        --argjson c2 "$clock2" '
        def compare:
            . as [$a, $b] |
            ($a | keys) + ($b | keys) | unique | map(. as $k |
                ($a[$k] // 0) - ($b[$k] // 0)
            ) |
            if all(. == 0) then "equal"
            elif all(. <= 0) then "before"
            elif all(. >= 0) then "after"
            else "concurrent"
            end;
        [$c1, $c2] | compare
    ')
    
    echo "$result"
}

# Sync state changes between agents
sync_state_change() {
    local namespace="$1"
    local key="$2"
    local value="$3"
    local agent_id="${4:-${AGENT_ID:-$$}}"
    local operation="${5:-update}"
    
    # Update vector clock
    local vclock=$(update_vector_clock "$namespace" "$agent_id")
    
    # Create sync entry
    local sync_id="$(date +%s.%N)_${agent_id}"
    local sync_file="${SYNC_QUEUE}/${sync_id}.sync"
    
    jq -n \
        --arg ns "$namespace" \
        --arg key "$key" \
        --argjson value "$value" \
        --arg agent "$agent_id" \
        --arg op "$operation" \
        --argjson clock "$vclock" \
        '{
            id: $ARGS.named.id,
            timestamp: now,
            namespace: $ns,
            key: $key,
            value: $value,
            agent: $agent,
            operation: $op,
            vector_clock: $clock
        }' \
        --arg id "$sync_id" > "$sync_file"
    
    # Process sync queue
    process_sync_queue "$namespace"
}

# Process synchronization queue
process_sync_queue() {
    local namespace="${1:-main}"
    
    # Get state manager
    local state_manager="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/state-manager.sh"
    
    # Process all pending sync entries for namespace
    for sync_file in "$SYNC_QUEUE"/*.sync; do
        [[ -f "$sync_file" ]] || continue
        
        local sync_ns=$(jq -r '.namespace' "$sync_file")
        [[ "$sync_ns" == "$namespace" ]] || continue
        
        # Check for conflicts
        if check_sync_conflict "$sync_file"; then
            handle_sync_conflict "$sync_file"
        else
            apply_sync_entry "$sync_file"
        fi
        
        # Move to history
        mv "$sync_file" "$SYNC_HISTORY/"
    done
}

# Check for synchronization conflicts
check_sync_conflict() {
    local sync_file="$1"
    
    local namespace=$(jq -r '.namespace' "$sync_file")
    local key=$(jq -r '.key' "$sync_file")
    local sync_clock=$(jq '.vector_clock' "$sync_file")
    
    # Get current state clock
    local state_clock_file="${SYNC_DIR}/state_${namespace}_${key}.vclock"
    
    if [[ -f "$state_clock_file" ]]; then
        local state_clock=$(cat "$state_clock_file")
        local comparison=$(compare_vector_clocks "$sync_clock" "$state_clock")
        
        case "$comparison" in
            "concurrent")
                # Concurrent modification - conflict!
                return 0
                ;;
            "before")
                # Sync is outdated, skip
                log_info "Skipping outdated sync for $namespace.$key"
                return 1
                ;;
            *)
                # No conflict
                return 1
                ;;
        esac
    fi
    
    return 1
}

# Handle synchronization conflicts
handle_sync_conflict() {
    local sync_file="$1"
    
    local namespace=$(jq -r '.namespace' "$sync_file")
    local key=$(jq -r '.key' "$sync_file")
    local sync_value=$(jq '.value' "$sync_file")
    local sync_agent=$(jq -r '.agent' "$sync_file")
    local sync_clock=$(jq '.vector_clock' "$sync_file")
    
    # Get current state value
    local state_manager="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/state-manager.sh"
    local current_value=$("$state_manager" get "$key" "$namespace")
    
    # Create conflict record
    local conflict_id="$(date +%s.%N)"
    local conflict_file="${SYNC_CONFLICTS}/${conflict_id}.conflict"
    
    jq -n \
        --arg ns "$namespace" \
        --arg key "$key" \
        --argjson current "$current_value" \
        --argjson proposed "$sync_value" \
        --arg agent "$sync_agent" \
        --argjson clock "$sync_clock" \
        '{
            id: $ARGS.named.id,
            timestamp: now,
            namespace: $ns,
            key: $key,
            current_value: $current,
            proposed_value: $proposed,
            proposing_agent: $agent,
            vector_clock: $clock,
            status: "pending",
            resolution: null
        }' \
        --arg id "$conflict_id" > "$conflict_file"
    
    # Attempt automatic resolution
    resolve_conflict_automatically "$conflict_file"
}

# Apply sync entry to state
apply_sync_entry() {
    local sync_file="$1"
    
    local namespace=$(jq -r '.namespace' "$sync_file")
    local key=$(jq -r '.key' "$sync_file")
    local value=$(jq '.value' "$sync_file")
    local operation=$(jq -r '.operation' "$sync_file")
    local sync_clock=$(jq '.vector_clock' "$sync_file")
    
    # Get state manager
    local state_manager="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/state-manager.sh"
    
    # Apply operation
    case "$operation" in
        "set"|"update")
            "$state_manager" set "$key" "$value" "$namespace"
            ;;
        "delete")
            "$state_manager" delete "$key" "$namespace"
            ;;
    esac
    
    # Update state clock
    local state_clock_file="${SYNC_DIR}/state_${namespace}_${key}.vclock"
    echo "$sync_clock" > "$state_clock_file"
}

# Automatic conflict resolution strategies
resolve_conflict_automatically() {
    local conflict_file="$1"
    
    local namespace=$(jq -r '.namespace' "$conflict_file")
    local key=$(jq -r '.key' "$conflict_file")
    local current=$(jq '.current_value' "$conflict_file")
    local proposed=$(jq '.proposed_value' "$conflict_file")
    
    # Determine resolution strategy based on data type and key pattern
    local resolution_strategy="last-write-wins"  # Default
    
    # Special handling for certain keys
    case "$key" in
        *_list|*_array)
            resolution_strategy="merge-lists"
            ;;
        *_count|*_total)
            resolution_strategy="sum-values"
            ;;
        *_timestamp|*_updated)
            resolution_strategy="latest-timestamp"
            ;;
        *_lock|*_owner)
            resolution_strategy="manual"
            ;;
    esac
    
    local resolved_value=""
    local resolution_method=""
    
    case "$resolution_strategy" in
        "last-write-wins")
            # Use proposed value (newer based on vector clock)
            resolved_value="$proposed"
            resolution_method="last-write-wins"
            ;;
            
        "merge-lists")
            # Merge arrays/lists
            if [[ $(echo "$current" | jq 'type') == '"array"' ]] && \
               [[ $(echo "$proposed" | jq 'type') == '"array"' ]]; then
                resolved_value=$(jq -n \
                    --argjson curr "$current" \
                    --argjson prop "$proposed" \
                    '$curr + $prop | unique')
                resolution_method="list-merge"
            else
                resolved_value="$proposed"
                resolution_method="type-mismatch-fallback"
            fi
            ;;
            
        "sum-values")
            # Sum numeric values
            if [[ $(echo "$current" | jq 'type') == '"number"' ]] && \
               [[ $(echo "$proposed" | jq 'type') == '"number"' ]]; then
                resolved_value=$(jq -n \
                    --argjson curr "$current" \
                    --argjson prop "$proposed" \
                    '$curr + $prop')
                resolution_method="numeric-sum"
            else
                resolved_value="$proposed"
                resolution_method="type-mismatch-fallback"
            fi
            ;;
            
        "latest-timestamp")
            # Choose the latest timestamp
            resolved_value="$proposed"
            resolution_method="latest-timestamp"
            ;;
            
        "manual")
            # Require manual resolution
            log_warn "Manual conflict resolution required for $namespace.$key"
            return 1
            ;;
    esac
    
    # Apply resolution
    if [[ -n "$resolved_value" ]]; then
        # Update conflict record
        local temp_file=$(mktemp)
        jq --argjson resolved "$resolved_value" \
           --arg method "$resolution_method" \
           '.status = "resolved" | .resolution = {value: $resolved, method: $method, timestamp: now}' \
           "$conflict_file" > "$temp_file"
        mv "$temp_file" "$conflict_file"
        
        # Apply resolved value
        local state_manager="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/state-manager.sh"
        "$state_manager" set "$key" "$resolved_value" "$namespace"
        
        log_info "Automatically resolved conflict for $namespace.$key using $resolution_method"
    fi
}

# Manual conflict resolution
resolve_conflict_manually() {
    local conflict_id="$1"
    local resolved_value="$2"
    local resolution_reason="${3:-Manual resolution}"
    
    local conflict_file="${SYNC_CONFLICTS}/${conflict_id}.conflict"
    
    if [[ ! -f "$conflict_file" ]]; then
        log_error "Conflict not found: $conflict_id"
        return 1
    fi
    
    # Update conflict record
    local temp_file=$(mktemp)
    jq --argjson resolved "$resolved_value" \
       --arg reason "$resolution_reason" \
       '.status = "resolved" | .resolution = {value: $resolved, method: "manual", reason: $reason, timestamp: now}' \
       "$conflict_file" > "$temp_file"
    mv "$temp_file" "$conflict_file"
    
    # Apply resolved value
    local namespace=$(jq -r '.namespace' "$conflict_file")
    local key=$(jq -r '.key' "$conflict_file")
    
    local state_manager="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/state-manager.sh"
    "$state_manager" set "$key" "$resolved_value" "$namespace"
    
    log_info "Manually resolved conflict for $namespace.$key"
}

# List pending conflicts
list_conflicts() {
    local status="${1:-pending}"
    
    log_info "Conflicts with status: $status"
    
    for conflict_file in "$SYNC_CONFLICTS"/*.conflict; do
        [[ -f "$conflict_file" ]] || continue
        
        local conflict_status=$(jq -r '.status' "$conflict_file")
        [[ "$status" == "all" ]] || [[ "$conflict_status" == "$status" ]] || continue
        
        local conflict_id=$(basename "$conflict_file" .conflict)
        local namespace=$(jq -r '.namespace' "$conflict_file")
        local key=$(jq -r '.key' "$conflict_file")
        local timestamp=$(jq -r '.timestamp' "$conflict_file")
        
        echo "  ID: $conflict_id"
        echo "  Namespace: $namespace"
        echo "  Key: $key"
        echo "  Time: $(date -d "@$timestamp" 2>/dev/null || date -r "$timestamp")"
        echo "  Status: $conflict_status"
        
        if [[ "$conflict_status" == "resolved" ]]; then
            local method=$(jq -r '.resolution.method' "$conflict_file")
            echo "  Resolution: $method"
        fi
        
        echo ""
    done
}

# Sync status and statistics
sync_status() {
    log_info "Synchronization Status"
    
    echo "Queue: $(find "$SYNC_QUEUE" -name "*.sync" | wc -l) pending"
    echo "Conflicts: $(find "$SYNC_CONFLICTS" -name "*.conflict" | grep -c '"status": "pending"' || echo 0) pending"
    echo "History: $(find "$SYNC_HISTORY" -name "*.sync" | wc -l) processed"
    
    echo ""
    echo "Recent sync activity:"
    find "$SYNC_HISTORY" -name "*.sync" -mmin -60 | tail -5 | while read -r sync_file; do
        local agent=$(jq -r '.agent' "$sync_file")
        local ns=$(jq -r '.namespace' "$sync_file")
        local key=$(jq -r '.key' "$sync_file")
        echo "  $agent: $ns.$key"
    done
}

# Main execution
main() {
    initialize_sync_system
    
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        sync)
            sync_state_change "$@"
            ;;
        process)
            process_sync_queue "$@"
            ;;
        resolve)
            resolve_conflict_manually "$@"
            ;;
        conflicts)
            list_conflicts "$@"
            ;;
        status)
            sync_status
            ;;
        help|*)
            cat <<EOF
Usage: $0 <command> [options]

Commands:
    sync <namespace> <key> <value> [agent_id] [operation]
        Synchronize state change
    
    process [namespace]
        Process sync queue for namespace
    
    resolve <conflict_id> <value> [reason]
        Manually resolve a conflict
    
    conflicts [status]
        List conflicts (pending/resolved/all)
    
    status
        Show sync status and statistics

Examples:
    $0 sync main current_task '{"id": "task-123", "status": "active"}'
    $0 process main
    $0 resolve 1234567890.123 '{"merged": true}'
    $0 conflicts pending
EOF
            ;;
    esac
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi