#!/bin/bash
# PostToolUse hook: detect-conflicts.sh - Detect agent conflicts and resource contention

set -euo pipefail

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Conflict detection directories
CONFLICT_DIR="${CLAUDE_LOGS_DIR}/metaclaude/conflicts"
CONFLICT_ACTIVE="${CONFLICT_DIR}/active"
CONFLICT_RESOLVED="${CONFLICT_DIR}/resolved"
RESOURCE_LOCKS="${CONFLICT_DIR}/resources"
TASK_CLAIMS="${CONFLICT_DIR}/tasks"

# Initialize conflict detection system
initialize_conflict_system() {
    mkdir -p "$CONFLICT_ACTIVE" "$CONFLICT_RESOLVED" "$RESOURCE_LOCKS" "$TASK_CLAIMS"
}

# Resource tracking
claim_resource() {
    local resource_type="$1"  # file, directory, service, etc.
    local resource_path="$2"
    local agent_id="${3:-${AGENT_ID:-$$}}"
    local operation="${4:-modify}"  # read, modify, delete
    local duration="${5:-300}"  # Expected duration in seconds
    
    # Normalize resource path
    local resource_id=$(echo "$resource_path" | sed 's/[^a-zA-Z0-9._-]/_/g')
    local lock_file="${RESOURCE_LOCKS}/${resource_type}_${resource_id}.lock"
    
    # Check for existing claims
    if [[ -f "$lock_file" ]]; then
        local existing_agent=$(jq -r '.agent_id' "$lock_file")
        local existing_op=$(jq -r '.operation' "$lock_file")
        local lock_time=$(jq -r '.timestamp' "$lock_file")
        local lock_duration=$(jq -r '.duration' "$lock_file")
        
        # Check if lock is expired
        local current_time=$(date +%s)
        if (( current_time - lock_time > lock_duration )); then
            log_info "Expired lock on $resource_type:$resource_path, claiming for $agent_id"
        else
            # Check for conflicts
            if [[ "$existing_agent" != "$agent_id" ]]; then
                # Different agent has the resource
                if [[ "$operation" == "read" && "$existing_op" == "read" ]]; then
                    # Multiple reads are okay
                    log_info "Shared read access on $resource_type:$resource_path"
                else
                    # Conflict detected!
                    create_resource_conflict "$resource_type" "$resource_path" "$agent_id" "$existing_agent" "$operation" "$existing_op"
                    return 1
                fi
            fi
        fi
    fi
    
    # Create or update lock
    jq -n \
        --arg agent "$agent_id" \
        --arg type "$resource_type" \
        --arg path "$resource_path" \
        --arg op "$operation" \
        --arg dur "$duration" \
        '{
            agent_id: $agent,
            resource_type: $type,
            resource_path: $path,
            operation: $op,
            timestamp: now | floor,
            duration: ($dur | tonumber),
            created_at: now | strftime("%Y-%m-%dT%H:%M:%SZ")
        }' > "$lock_file"
    
    log_info "Resource claimed: $resource_type:$resource_path by $agent_id for $operation"
}

release_resource() {
    local resource_type="$1"
    local resource_path="$2"
    local agent_id="${3:-${AGENT_ID:-$$}}"
    
    # Normalize resource path
    local resource_id=$(echo "$resource_path" | sed 's/[^a-zA-Z0-9._-]/_/g')
    local lock_file="${RESOURCE_LOCKS}/${resource_type}_${resource_id}.lock"
    
    if [[ -f "$lock_file" ]]; then
        local lock_agent=$(jq -r '.agent_id' "$lock_file")
        if [[ "$lock_agent" == "$agent_id" ]]; then
            rm -f "$lock_file"
            log_info "Resource released: $resource_type:$resource_path by $agent_id"
        else
            log_warn "Cannot release resource owned by $lock_agent (requested by $agent_id)"
        fi
    fi
}

# Task conflict detection
claim_task() {
    local task_id="$1"
    local agent_id="${2:-${AGENT_ID:-$$}}"
    local task_type="${3:-execution}"  # orchestration, execution, monitoring
    
    local claim_file="${TASK_CLAIMS}/${task_id}.claim"
    
    # Check for existing claims
    if [[ -f "$claim_file" ]]; then
        local existing_agent=$(jq -r '.agent_id' "$claim_file")
        local existing_type=$(jq -r '.task_type' "$claim_file")
        
        if [[ "$existing_agent" != "$agent_id" ]]; then
            # Task already claimed by another agent
            create_task_conflict "$task_id" "$agent_id" "$existing_agent" "$task_type" "$existing_type"
            return 1
        fi
    fi
    
    # Create task claim
    jq -n \
        --arg agent "$agent_id" \
        --arg task "$task_id" \
        --arg type "$task_type" \
        '{
            task_id: $task,
            agent_id: $agent,
            task_type: $type,
            timestamp: now | floor,
            created_at: now | strftime("%Y-%m-%dT%H:%M:%SZ")
        }' > "$claim_file"
    
    log_info "Task claimed: $task_id by $agent_id for $task_type"
}

# Conflict creation
create_resource_conflict() {
    local resource_type="$1"
    local resource_path="$2"
    local requesting_agent="$3"
    local holding_agent="$4"
    local requesting_op="$5"
    local holding_op="$6"
    
    local conflict_id="$(date +%s.%N)_resource"
    local conflict_file="${CONFLICT_ACTIVE}/${conflict_id}.conflict"
    
    jq -n \
        --arg id "$conflict_id" \
        --arg rtype "$resource_type" \
        --arg rpath "$resource_path" \
        --arg req_agent "$requesting_agent" \
        --arg hold_agent "$holding_agent" \
        --arg req_op "$requesting_op" \
        --arg hold_op "$holding_op" \
        '{
            conflict_id: $id,
            conflict_type: "resource_contention",
            resource: {
                type: $rtype,
                path: $rpath
            },
            agents: {
                requesting: {
                    id: $req_agent,
                    operation: $req_op
                },
                holding: {
                    id: $hold_agent,
                    operation: $hold_op
                }
            },
            timestamp: now | floor,
            created_at: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            status: "active",
            severity: (if $req_op == "delete" or $hold_op == "delete" then "critical" else "high" end)
        }' > "$conflict_file"
    
    # Broadcast conflict
    broadcast_conflict "$conflict_file"
    
    log_error "CONFLICT: Resource contention on $resource_type:$resource_path between $requesting_agent and $holding_agent"
}

create_task_conflict() {
    local task_id="$1"
    local requesting_agent="$2"
    local assigned_agent="$3"
    local requesting_type="$4"
    local assigned_type="$5"
    
    local conflict_id="$(date +%s.%N)_task"
    local conflict_file="${CONFLICT_ACTIVE}/${conflict_id}.conflict"
    
    jq -n \
        --arg id "$conflict_id" \
        --arg task "$task_id" \
        --arg req_agent "$requesting_agent" \
        --arg ass_agent "$assigned_agent" \
        --arg req_type "$requesting_type" \
        --arg ass_type "$assigned_type" \
        '{
            conflict_id: $id,
            conflict_type: "task_assignment",
            task_id: $task,
            agents: {
                requesting: {
                    id: $req_agent,
                    type: $req_type
                },
                assigned: {
                    id: $ass_agent,
                    type: $ass_type
                }
            },
            timestamp: now | floor,
            created_at: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            status: "active",
            severity: "medium"
        }' > "$conflict_file"
    
    # Broadcast conflict
    broadcast_conflict "$conflict_file"
    
    log_error "CONFLICT: Task assignment conflict for $task_id between $requesting_agent and $assigned_agent"
}

# Pattern-based conflict detection
detect_operation_conflicts() {
    local tool_name="$1"
    local tool_args="${2:-}"
    local agent_id="${AGENT_ID:-$$}"
    
    case "$tool_name" in
        "Write"|"Edit"|"MultiEdit")
            # Extract file path from args
            local file_path=$(echo "$tool_args" | jq -r '.file_path // empty' 2>/dev/null || echo "$tool_args")
            if [[ -n "$file_path" ]]; then
                claim_resource "file" "$file_path" "$agent_id" "modify"
            fi
            ;;
            
        "Delete"|"Remove")
            # Critical operation
            local target=$(echo "$tool_args" | jq -r '.path // .file_path // empty' 2>/dev/null || echo "$tool_args")
            if [[ -n "$target" ]]; then
                claim_resource "file" "$target" "$agent_id" "delete"
            fi
            ;;
            
        "TodoWrite")
            # Check for task conflicts
            local todos=$(echo "$tool_args" | jq -r '.todos[]?.id // empty' 2>/dev/null)
            for task_id in $todos; do
                [[ -n "$task_id" ]] && claim_task "$task_id" "$agent_id"
            done
            ;;
            
        "Task")
            # New task creation
            local task_id=$(echo "$tool_args" | jq -r '.id // empty' 2>/dev/null)
            if [[ -n "$task_id" ]]; then
                claim_task "$task_id" "$agent_id" "orchestration"
            fi
            ;;
    esac
}

# Broadcast conflicts to orchestrators
broadcast_conflict() {
    local conflict_file="$1"
    
    # Use broadcast system if available
    local broadcast_script="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/broadcast.sh"
    if [[ -x "$broadcast_script" ]]; then
        export TOOL_NAME="ConflictDetector"
        export TOOL_OUTPUT=$(cat "$conflict_file")
        "$broadcast_script"
    fi
    
    # Also alert via state
    local state_manager="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/state-manager.sh"
    if [[ -x "$state_manager" ]]; then
        local conflict_id=$(jq -r '.conflict_id' "$conflict_file")
        "$state_manager" update "active_conflicts" ". + [\"$conflict_id\"]" "conflicts"
    fi
}

# Check for stale locks and conflicts
cleanup_stale_resources() {
    local max_age="${1:-3600}"  # Default 1 hour
    local current_time=$(date +%s)
    
    # Clean resource locks
    for lock_file in "$RESOURCE_LOCKS"/*.lock; do
        [[ -f "$lock_file" ]] || continue
        
        local lock_time=$(jq -r '.timestamp' "$lock_file")
        local duration=$(jq -r '.duration' "$lock_file")
        
        if (( current_time - lock_time > duration + max_age )); then
            log_info "Removing stale lock: $(basename "$lock_file")"
            rm -f "$lock_file"
        fi
    done
    
    # Clean old conflicts
    for conflict_file in "$CONFLICT_RESOLVED"/*.conflict; do
        [[ -f "$conflict_file" ]] || continue
        
        local conflict_time=$(jq -r '.timestamp' "$conflict_file")
        if (( current_time - conflict_time > max_age * 24 )); then  # 24 hours
            rm -f "$conflict_file"
        fi
    done
}

# List active conflicts
list_conflicts() {
    local conflict_type="${1:-all}"
    
    log_info "Active conflicts:"
    
    for conflict_file in "$CONFLICT_ACTIVE"/*.conflict; do
        [[ -f "$conflict_file" ]] || continue
        
        local ctype=$(jq -r '.conflict_type' "$conflict_file")
        [[ "$conflict_type" == "all" ]] || [[ "$ctype" == "$conflict_type" ]] || continue
        
        local conflict_id=$(jq -r '.conflict_id' "$conflict_file")
        local severity=$(jq -r '.severity' "$conflict_file")
        local created=$(jq -r '.created_at' "$conflict_file")
        
        echo "  ID: $conflict_id"
        echo "  Type: $ctype"
        echo "  Severity: $severity"
        echo "  Created: $created"
        
        case "$ctype" in
            "resource_contention")
                local resource=$(jq -r '.resource | "\(.type):\(.path)"' "$conflict_file")
                local agents=$(jq -r '.agents | "requesting:\(.requesting.id) holding:\(.holding.id)"' "$conflict_file")
                echo "  Resource: $resource"
                echo "  Agents: $agents"
                ;;
            "task_assignment")
                local task=$(jq -r '.task_id' "$conflict_file")
                local agents=$(jq -r '.agents | "requesting:\(.requesting.id) assigned:\(.assigned.id)"' "$conflict_file")
                echo "  Task: $task"
                echo "  Agents: $agents"
                ;;
        esac
        
        echo ""
    done
}

# PostToolUse hook handler
handle_post_tool_use() {
    local tool_name="${1:-unknown}"
    local tool_args="${2:-}"
    
    # Detect potential conflicts based on tool usage
    detect_operation_conflicts "$tool_name" "$tool_args"
    
    # Cleanup periodically
    if (( RANDOM % 10 == 0 )); then
        cleanup_stale_resources
    fi
}

# Main execution
main() {
    initialize_conflict_system
    
    if [[ $# -eq 0 ]]; then
        # Running as PostToolUse hook
        local tool_name="${TOOL_NAME:-unknown}"
        local tool_args="${TOOL_ARGS:-}"
        handle_post_tool_use "$tool_name" "$tool_args"
    else
        # Running as command
        local command="$1"
        shift
        
        case "$command" in
            claim)
                claim_resource "$@"
                ;;
            release)
                release_resource "$@"
                ;;
            task)
                claim_task "$@"
                ;;
            list)
                list_conflicts "$@"
                ;;
            cleanup)
                cleanup_stale_resources "$@"
                ;;
            help|*)
                cat <<EOF
Usage: $0 [command] [options]

Commands:
    claim <type> <path> [agent_id] [operation] [duration]
        Claim a resource
    
    release <type> <path> [agent_id]
        Release a resource
    
    task <task_id> [agent_id] [type]
        Claim a task
    
    list [type]
        List active conflicts
    
    cleanup [max_age]
        Clean up stale locks

When run without arguments, acts as PostToolUse hook.
EOF
                ;;
        esac
    fi
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi