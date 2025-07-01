#!/bin/bash
# Shared state management for multi-agent coordination

set -euo pipefail

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# State management directories
STATE_DIR="${CLAUDE_LOGS_DIR}/metaclaude/state"
STATE_STORE="${STATE_DIR}/store"
STATE_SNAPSHOTS="${STATE_DIR}/snapshots"
STATE_LOCKS="${STATE_DIR}/locks"
STATE_JOURNAL="${STATE_DIR}/journal"

# Initialize state management system
initialize_state_system() {
    mkdir -p "$STATE_STORE" "$STATE_SNAPSHOTS" "$STATE_LOCKS" "$STATE_JOURNAL"
    
    # Create initial state file if not exists
    local main_state="${STATE_STORE}/main.state"
    if [[ ! -f "$main_state" ]]; then
        echo '{}' > "$main_state"
    fi
}

# Lock management for atomic operations
acquire_lock() {
    local key="${1:-main}"
    local timeout="${2:-30}"
    local lock_file="${STATE_LOCKS}/${key}.lock"
    
    local start_time=$(date +%s)
    
    while true; do
        # Try to create lock file atomically
        if (set -C; echo "$$" > "$lock_file") 2>/dev/null; then
            return 0
        fi
        
        # Check timeout
        local current_time=$(date +%s)
        if (( current_time - start_time >= timeout )); then
            log_error "Failed to acquire lock for key '$key' within ${timeout}s"
            return 1
        fi
        
        # Check if lock holder is still alive
        if [[ -f "$lock_file" ]]; then
            local lock_pid=$(cat "$lock_file" 2>/dev/null || echo "0")
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                # Lock holder is dead, remove stale lock
                rm -f "$lock_file"
                continue
            fi
        fi
        
        # Wait before retry
        sleep 0.1
    done
}

release_lock() {
    local key="${1:-main}"
    local lock_file="${STATE_LOCKS}/${key}.lock"
    
    # Only release if we own the lock
    if [[ -f "$lock_file" ]] && [[ "$(cat "$lock_file" 2>/dev/null)" == "$$" ]]; then
        rm -f "$lock_file"
    fi
}

# Atomic state operations
get_state() {
    local key="${1:-}"
    local namespace="${2:-main}"
    local state_file="${STATE_STORE}/${namespace}.state"
    
    if [[ ! -f "$state_file" ]]; then
        echo "{}"
        return
    fi
    
    if [[ -z "$key" ]]; then
        # Return entire state
        cat "$state_file"
    else
        # Return specific key
        jq -r --arg key "$key" '.[$key] // empty' "$state_file"
    fi
}

set_state() {
    local key="$1"
    local value="$2"
    local namespace="${3:-main}"
    local state_file="${STATE_STORE}/${namespace}.state"
    
    # Ensure state file exists
    [[ -f "$state_file" ]] || echo '{}' > "$state_file"
    
    # Acquire lock for atomic update
    if ! acquire_lock "$namespace"; then
        return 1
    fi
    
    # Perform atomic update
    local temp_file=$(mktemp)
    local old_value=$(jq -r --arg key "$key" '.[$key] // empty' "$state_file")
    
    # Update state
    jq --arg key "$key" --argjson value "$value" '.[$key] = $value' "$state_file" > "$temp_file"
    mv "$temp_file" "$state_file"
    
    # Log to journal
    log_journal "set" "$namespace" "$key" "$old_value" "$value"
    
    # Release lock
    release_lock "$namespace"
    
    # Broadcast state change
    broadcast_state_change "$namespace" "$key" "$old_value" "$value"
}

update_state() {
    local key="$1"
    local update_fn="$2"  # JQ expression to update value
    local namespace="${3:-main}"
    local state_file="${STATE_STORE}/${namespace}.state"
    
    # Ensure state file exists
    [[ -f "$state_file" ]] || echo '{}' > "$state_file"
    
    # Acquire lock for atomic update
    if ! acquire_lock "$namespace"; then
        return 1
    fi
    
    # Get current value
    local old_value=$(jq -r --arg key "$key" '.[$key] // empty' "$state_file")
    
    # Apply update function
    local temp_file=$(mktemp)
    jq --arg key "$key" ".[\$key] |= $update_fn" "$state_file" > "$temp_file"
    
    # Get new value
    local new_value=$(jq -r --arg key "$key" '.[$key] // empty' "$temp_file")
    
    # Move updated file
    mv "$temp_file" "$state_file"
    
    # Log to journal
    log_journal "update" "$namespace" "$key" "$old_value" "$new_value"
    
    # Release lock
    release_lock "$namespace"
    
    # Broadcast state change
    broadcast_state_change "$namespace" "$key" "$old_value" "$new_value"
}

delete_state() {
    local key="$1"
    local namespace="${2:-main}"
    local state_file="${STATE_STORE}/${namespace}.state"
    
    if [[ ! -f "$state_file" ]]; then
        return 0
    fi
    
    # Acquire lock for atomic update
    if ! acquire_lock "$namespace"; then
        return 1
    fi
    
    # Get current value for journal
    local old_value=$(jq -r --arg key "$key" '.[$key] // empty' "$state_file")
    
    # Delete key
    local temp_file=$(mktemp)
    jq --arg key "$key" 'del(.[$key])' "$state_file" > "$temp_file"
    mv "$temp_file" "$state_file"
    
    # Log to journal
    log_journal "delete" "$namespace" "$key" "$old_value" ""
    
    # Release lock
    release_lock "$namespace"
    
    # Broadcast state change
    broadcast_state_change "$namespace" "$key" "$old_value" "null"
}

# State snapshots
create_snapshot() {
    local namespace="${1:-main}"
    local description="${2:-Manual snapshot}"
    local state_file="${STATE_STORE}/${namespace}.state"
    
    if [[ ! -f "$state_file" ]]; then
        log_error "No state found for namespace '$namespace'"
        return 1
    fi
    
    local timestamp=$(date +%s)
    local snapshot_file="${STATE_SNAPSHOTS}/${namespace}_${timestamp}.snapshot"
    
    # Create snapshot metadata
    jq -n \
        --arg timestamp "$timestamp" \
        --arg namespace "$namespace" \
        --arg description "$description" \
        --arg agent "${AGENT_TYPE:-unknown}/${AGENT_ID:-$$}" \
        --argjson state "$(cat "$state_file")" \
        '{
            timestamp: $timestamp,
            namespace: $namespace,
            description: $description,
            created_by: $agent,
            created_at: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            state: $state
        }' > "$snapshot_file"
    
    log_info "Created snapshot for namespace '$namespace': $snapshot_file"
    echo "$snapshot_file"
}

restore_snapshot() {
    local snapshot_file="$1"
    local namespace="${2:-}"
    
    if [[ ! -f "$snapshot_file" ]]; then
        log_error "Snapshot file not found: $snapshot_file"
        return 1
    fi
    
    # Extract namespace from snapshot if not provided
    if [[ -z "$namespace" ]]; then
        namespace=$(jq -r '.namespace' "$snapshot_file")
    fi
    
    local state_file="${STATE_STORE}/${namespace}.state"
    
    # Acquire lock
    if ! acquire_lock "$namespace"; then
        return 1
    fi
    
    # Backup current state
    create_snapshot "$namespace" "Pre-restore backup"
    
    # Restore state
    jq '.state' "$snapshot_file" > "$state_file"
    
    # Log restore
    log_journal "restore" "$namespace" "snapshot" "$snapshot_file" "$(date +%s)"
    
    # Release lock
    release_lock "$namespace"
    
    log_info "Restored snapshot to namespace '$namespace'"
}

list_snapshots() {
    local namespace="${1:-}"
    
    log_info "Available snapshots:"
    
    local pattern="${namespace}_*.snapshot"
    [[ -z "$namespace" ]] && pattern="*.snapshot"
    
    find "$STATE_SNAPSHOTS" -name "$pattern" -type f | sort -r | while read -r snapshot; do
        local snap_namespace=$(jq -r '.namespace' "$snapshot")
        local snap_time=$(jq -r '.created_at' "$snapshot")
        local snap_desc=$(jq -r '.description' "$snapshot")
        local snap_agent=$(jq -r '.created_by' "$snapshot")
        
        echo "  Namespace: $snap_namespace"
        echo "  Time: $snap_time"
        echo "  Description: $snap_desc"
        echo "  Created by: $snap_agent"
        echo "  File: $snapshot"
        echo ""
    done
}

# Journal logging
log_journal() {
    local operation="$1"
    local namespace="$2"
    local key="$3"
    local old_value="$4"
    local new_value="$5"
    
    local journal_file="${STATE_JOURNAL}/$(date +%Y%m%d).journal"
    
    # Create journal entry
    jq -n \
        --arg op "$operation" \
        --arg ns "$namespace" \
        --arg key "$key" \
        --arg old "$old_value" \
        --arg new "$new_value" \
        --arg agent "${AGENT_TYPE:-unknown}/${AGENT_ID:-$$}" \
        '{
            timestamp: now,
            operation: $op,
            namespace: $ns,
            key: $key,
            old_value: $old,
            new_value: $new,
            agent: $agent
        }' >> "$journal_file"
}

# Broadcast state changes
broadcast_state_change() {
    local namespace="$1"
    local key="$2"
    local old_value="$3"
    local new_value="$4"
    
    # Use broadcast system if available
    local broadcast_script="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/broadcast.sh"
    if [[ -x "$broadcast_script" ]]; then
        export TOOL_NAME="StateManager"
        export TOOL_OUTPUT=$(jq -n \
            --arg ns "$namespace" \
            --arg key "$key" \
            --arg old "$old_value" \
            --arg new "$new_value" \
            '{
                namespace: $ns,
                key: $key,
                old_value: $old,
                new_value: $new,
                operation: "state_change"
            }')
        "$broadcast_script"
    fi
}

# State inspection
inspect_state() {
    local namespace="${1:-main}"
    local state_file="${STATE_STORE}/${namespace}.state"
    
    if [[ ! -f "$state_file" ]]; then
        log_error "No state found for namespace '$namespace'"
        return 1
    fi
    
    log_info "State inspection for namespace: $namespace"
    echo "Current state:"
    jq '.' "$state_file"
    
    echo ""
    echo "State statistics:"
    echo "  Keys: $(jq 'keys | length' "$state_file")"
    echo "  Size: $(stat -f%z "$state_file" 2>/dev/null || stat -c%s "$state_file") bytes"
    echo "  Modified: $(stat -f%Sm "$state_file" 2>/dev/null || stat -c%y "$state_file")"
}

# Namespace management
list_namespaces() {
    log_info "Active namespaces:"
    
    for state_file in "$STATE_STORE"/*.state; do
        [[ -f "$state_file" ]] || continue
        
        local namespace=$(basename "$state_file" .state)
        local keys=$(jq 'keys | length' "$state_file")
        local size=$(stat -f%z "$state_file" 2>/dev/null || stat -c%s "$state_file")
        
        echo "  $namespace: $keys keys, $size bytes"
    done
}

# Main execution
main() {
    initialize_state_system
    
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        get)
            get_state "$@"
            ;;
        set)
            set_state "$@"
            ;;
        update)
            update_state "$@"
            ;;
        delete)
            delete_state "$@"
            ;;
        snapshot)
            create_snapshot "$@"
            ;;
        restore)
            restore_snapshot "$@"
            ;;
        snapshots)
            list_snapshots "$@"
            ;;
        inspect)
            inspect_state "$@"
            ;;
        namespaces)
            list_namespaces
            ;;
        help|*)
            cat <<EOF
Usage: $0 <command> [options]

Commands:
    get [key] [namespace]              Get state value
    set <key> <value> [namespace]      Set state value (atomic)
    update <key> <jq_expr> [namespace] Update state value (atomic)
    delete <key> [namespace]           Delete state key
    snapshot [namespace] [description] Create state snapshot
    restore <snapshot_file>            Restore from snapshot
    snapshots [namespace]              List available snapshots
    inspect [namespace]                Inspect namespace state
    namespaces                         List all namespaces

Examples:
    $0 get current_task
    $0 set agent_count 5
    $0 update task_queue '. + ["new_task"]'
    $0 snapshot main "Before major refactor"
    $0 inspect coordination
EOF
            ;;
    esac
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi