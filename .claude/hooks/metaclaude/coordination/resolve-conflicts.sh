#!/bin/bash
# Conflict resolution strategies and agent hierarchy enforcement

set -euo pipefail

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Conflict resolution directories
CONFLICT_DIR="${CLAUDE_LOGS_DIR}/metaclaude/conflicts"
CONFLICT_ACTIVE="${CONFLICT_DIR}/active"
CONFLICT_RESOLVED="${CONFLICT_DIR}/resolved"
RESOLUTION_RULES="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/resolution-rules.json"

# Agent hierarchy for priority resolution
AGENT_HIERARCHY='{
    "orchestrator": 100,
    "architect": 90,
    "reviewer": 80,
    "debugger": 75,
    "analyzer": 70,
    "tester": 65,
    "coder": 60,
    "researcher": 50,
    "documenter": 40,
    "optimizer": 30,
    "default": 10
}'

# Initialize resolution system
initialize_resolution_system() {
    mkdir -p "$CONFLICT_ACTIVE" "$CONFLICT_RESOLVED"
    
    # Create default resolution rules if not exists
    if [[ ! -f "$RESOLUTION_RULES" ]]; then
        create_default_resolution_rules
    fi
}

# Create default resolution rules
create_default_resolution_rules() {
    cat > "$RESOLUTION_RULES" <<'EOF'
{
    "resource_contention": {
        "file": {
            "read_read": "allow_both",
            "read_modify": "priority_based",
            "read_delete": "block_delete",
            "modify_modify": "sequential",
            "modify_delete": "block_delete",
            "delete_delete": "first_wins"
        },
        "directory": {
            "default": "priority_based"
        },
        "service": {
            "default": "time_share"
        }
    },
    "task_assignment": {
        "orchestration_orchestration": "merge_delegation",
        "orchestration_execution": "orchestrator_priority",
        "execution_execution": "workload_balance",
        "default": "priority_based"
    },
    "state_conflict": {
        "list_append": "merge_unique",
        "counter": "sum_values",
        "timestamp": "latest_wins",
        "ownership": "priority_based",
        "default": "vector_clock"
    }
}
EOF
}

# Get agent priority
get_agent_priority() {
    local agent_id="$1"
    local agent_type="${2:-unknown}"
    
    # Extract type from agent_id if not provided
    if [[ "$agent_type" == "unknown" ]] && [[ "$agent_id" =~ ^([^_]+)_ ]]; then
        agent_type="${BASH_REMATCH[1]}"
    fi
    
    # Get priority from hierarchy
    echo "$AGENT_HIERARCHY" | jq -r --arg type "$agent_type" '.[$type] // .default'
}

# Resolve conflict based on strategy
resolve_conflict() {
    local conflict_file="$1"
    local strategy="${2:-auto}"
    local resolver_agent="${3:-${AGENT_ID:-system}}"
    
    if [[ ! -f "$conflict_file" ]]; then
        log_error "Conflict file not found: $conflict_file"
        return 1
    fi
    
    local conflict_id=$(jq -r '.conflict_id' "$conflict_file")
    local conflict_type=$(jq -r '.conflict_type' "$conflict_file")
    
    log_info "Resolving conflict $conflict_id of type $conflict_type using strategy: $strategy"
    
    # Determine resolution based on conflict type
    case "$conflict_type" in
        "resource_contention")
            resolve_resource_conflict "$conflict_file" "$strategy"
            ;;
        "task_assignment")
            resolve_task_conflict "$conflict_file" "$strategy"
            ;;
        "state_conflict")
            resolve_state_conflict "$conflict_file" "$strategy"
            ;;
        *)
            log_error "Unknown conflict type: $conflict_type"
            return 1
            ;;
    esac
}

# Resolve resource contention
resolve_resource_conflict() {
    local conflict_file="$1"
    local strategy="$2"
    
    local resource_type=$(jq -r '.resource.type' "$conflict_file")
    local resource_path=$(jq -r '.resource.path' "$conflict_file")
    local req_agent=$(jq -r '.agents.requesting.id' "$conflict_file")
    local hold_agent=$(jq -r '.agents.holding.id' "$conflict_file")
    local req_op=$(jq -r '.agents.requesting.operation' "$conflict_file")
    local hold_op=$(jq -r '.agents.holding.operation' "$conflict_file")
    
    # Get resolution rule
    local rule=$(jq -r --arg rtype "$resource_type" --arg rop "$req_op" --arg hop "$hold_op" \
        '.resource_contention[$rtype][$rop + "_" + $hop] // .resource_contention[$rtype].default // "priority_based"' \
        "$RESOLUTION_RULES")
    
    local resolution=""
    local action=""
    
    case "$rule" in
        "allow_both")
            resolution="Both agents can proceed"
            action="allow"
            ;;
            
        "priority_based")
            local req_priority=$(get_agent_priority "$req_agent")
            local hold_priority=$(get_agent_priority "$hold_agent")
            
            if (( req_priority > hold_priority )); then
                resolution="Higher priority agent $req_agent takes precedence"
                action="transfer_to_requesting"
                notify_agent_preemption "$hold_agent" "$resource_type:$resource_path" "$req_agent"
            else
                resolution="Current holder $hold_agent maintains control"
                action="deny_requesting"
                notify_agent_denial "$req_agent" "$resource_type:$resource_path" "$hold_agent"
            fi
            ;;
            
        "sequential")
            resolution="Queue requesting agent after current operation"
            action="queue"
            queue_agent_request "$req_agent" "$resource_type" "$resource_path" "$req_op"
            ;;
            
        "block_delete")
            if [[ "$req_op" == "delete" ]] || [[ "$hold_op" == "delete" ]]; then
                resolution="Delete operation blocked due to conflict"
                action="block"
                notify_agent_block "$req_agent" "delete" "$resource_type:$resource_path"
            fi
            ;;
            
        "first_wins")
            resolution="Current holder maintains control"
            action="deny_requesting"
            ;;
            
        "time_share")
            resolution="Implement time-sharing schedule"
            action="schedule"
            schedule_resource_sharing "$resource_type" "$resource_path" "$req_agent" "$hold_agent"
            ;;
    esac
    
    # Record resolution
    record_resolution "$conflict_file" "$resolution" "$action" "$rule"
}

# Resolve task assignment conflicts
resolve_task_conflict() {
    local conflict_file="$1"
    local strategy="$2"
    
    local task_id=$(jq -r '.task_id' "$conflict_file")
    local req_agent=$(jq -r '.agents.requesting.id' "$conflict_file")
    local ass_agent=$(jq -r '.agents.assigned.id' "$conflict_file")
    local req_type=$(jq -r '.agents.requesting.type' "$conflict_file")
    local ass_type=$(jq -r '.agents.assigned.type' "$conflict_file")
    
    # Get resolution rule
    local rule=$(jq -r --arg rtype "$req_type" --arg atype "$ass_type" \
        '.task_assignment[$rtype + "_" + $atype] // .task_assignment.default // "priority_based"' \
        "$RESOLUTION_RULES")
    
    local resolution=""
    local action=""
    
    case "$rule" in
        "merge_delegation")
            resolution="Merge delegation strategies from both orchestrators"
            action="merge"
            merge_orchestration_plans "$task_id" "$req_agent" "$ass_agent"
            ;;
            
        "orchestrator_priority")
            if [[ "$req_type" == "orchestration" ]]; then
                resolution="Orchestrator $req_agent takes control from executor"
                action="transfer_to_requesting"
            else
                resolution="Orchestrator $ass_agent maintains control"
                action="deny_requesting"
            fi
            ;;
            
        "workload_balance")
            # Check agent workloads
            local req_workload=$(get_agent_workload "$req_agent")
            local ass_workload=$(get_agent_workload "$ass_agent")
            
            if (( req_workload < ass_workload )); then
                resolution="Balance workload - assign to less busy agent $req_agent"
                action="transfer_to_requesting"
            else
                resolution="Current assignee $ass_agent has lower workload"
                action="deny_requesting"
            fi
            ;;
            
        "priority_based")
            local req_priority=$(get_agent_priority "$req_agent" "$req_type")
            local ass_priority=$(get_agent_priority "$ass_agent" "$ass_type")
            
            if (( req_priority > ass_priority )); then
                resolution="Higher priority agent $req_agent takes task"
                action="transfer_to_requesting"
            else
                resolution="Current assignee $ass_agent maintains task"
                action="deny_requesting"
            fi
            ;;
    esac
    
    # Apply task transfer if needed
    if [[ "$action" == "transfer_to_requesting" ]]; then
        transfer_task "$task_id" "$ass_agent" "$req_agent"
    fi
    
    # Record resolution
    record_resolution "$conflict_file" "$resolution" "$action" "$rule"
}

# Helper functions for conflict resolution
notify_agent_preemption() {
    local agent_id="$1"
    local resource="$2"
    local preempting_agent="$3"
    
    # Broadcast preemption notice
    local broadcast_script="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/broadcast.sh"
    if [[ -x "$broadcast_script" ]]; then
        export TOOL_NAME="ConflictResolver"
        export TOOL_OUTPUT=$(jq -n \
            --arg agent "$agent_id" \
            --arg resource "$resource" \
            --arg preemptor "$preempting_agent" \
            '{
                type: "resource_preemption",
                agent: $agent,
                resource: $resource,
                preempted_by: $preemptor,
                action_required: "release_resource"
            }')
        "$broadcast_script"
    fi
}

notify_agent_denial() {
    local agent_id="$1"
    local resource="$2"
    local holding_agent="$3"
    
    # Broadcast denial notice
    local broadcast_script="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/broadcast.sh"
    if [[ -x "$broadcast_script" ]]; then
        export TOOL_NAME="ConflictResolver"
        export TOOL_OUTPUT=$(jq -n \
            --arg agent "$agent_id" \
            --arg resource "$resource" \
            --arg holder "$holding_agent" \
            '{
                type: "resource_denied",
                agent: $agent,
                resource: $resource,
                held_by: $holder,
                suggestion: "retry_later_or_coordinate"
            }')
        "$broadcast_script"
    fi
}

queue_agent_request() {
    local agent_id="$1"
    local resource_type="$2"
    local resource_path="$3"
    local operation="$4"
    
    local queue_file="${CONFLICT_DIR}/queues/${resource_type}_$(echo "$resource_path" | sed 's/[^a-zA-Z0-9._-]/_/g').queue"
    mkdir -p "$(dirname "$queue_file")"
    
    # Add to queue
    jq -n \
        --arg agent "$agent_id" \
        --arg op "$operation" \
        '{
            agent_id: $agent,
            operation: $op,
            queued_at: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            status: "waiting"
        }' >> "$queue_file"
    
    log_info "Queued request from $agent_id for $resource_type:$resource_path"
}

get_agent_workload() {
    local agent_id="$1"
    
    # Check active tasks
    local task_count=$(find "$TASK_CLAIMS" -name "*.claim" -exec jq -r --arg agent "$agent_id" \
        'select(.agent_id == $agent) | .task_id' {} \; 2>/dev/null | wc -l)
    
    # Check resource locks
    local resource_count=$(find "$RESOURCE_LOCKS" -name "*.lock" -exec jq -r --arg agent "$agent_id" \
        'select(.agent_id == $agent) | .resource_path' {} \; 2>/dev/null | wc -l)
    
    echo $((task_count + resource_count))
}

transfer_task() {
    local task_id="$1"
    local from_agent="$2"
    local to_agent="$3"
    
    local claim_file="${TASK_CLAIMS}/${task_id}.claim"
    
    if [[ -f "$claim_file" ]]; then
        # Update claim
        local temp_file=$(mktemp)
        jq --arg agent "$to_agent" \
           '.agent_id = $agent | .transferred_from = .agent_id | .transferred_at = now' \
           "$claim_file" > "$temp_file"
        mv "$temp_file" "$claim_file"
        
        log_info "Transferred task $task_id from $from_agent to $to_agent"
    fi
}

merge_orchestration_plans() {
    local task_id="$1"
    local agent1="$2"
    local agent2="$3"
    
    # Create merged plan notification
    local broadcast_script="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/broadcast.sh"
    if [[ -x "$broadcast_script" ]]; then
        export TOOL_NAME="ConflictResolver"
        export TOOL_OUTPUT=$(jq -n \
            --arg task "$task_id" \
            --arg a1 "$agent1" \
            --arg a2 "$agent2" \
            '{
                type: "orchestration_merge",
                task_id: $task,
                orchestrators: [$a1, $a2],
                action_required: "coordinate_plans"
            }')
        "$broadcast_script"
    fi
}

record_resolution() {
    local conflict_file="$1"
    local resolution="$2"
    local action="$3"
    local rule="$4"
    
    local conflict_id=$(basename "$conflict_file" .conflict)
    
    # Update conflict record
    local temp_file=$(mktemp)
    jq --arg res "$resolution" \
       --arg act "$action" \
       --arg rule "$rule" \
       --arg resolver "${AGENT_ID:-system}" \
       '.status = "resolved" |
        .resolution = {
            description: $res,
            action: $act,
            rule_applied: $rule,
            resolved_by: $resolver,
            resolved_at: now | strftime("%Y-%m-%dT%H:%M:%SZ")
        }' "$conflict_file" > "$temp_file"
    
    # Move to resolved
    mv "$temp_file" "${CONFLICT_RESOLVED}/${conflict_id}.conflict"
    rm -f "$conflict_file"
    
    log_info "Resolved conflict $conflict_id: $resolution"
}

# Batch conflict resolution
resolve_all_conflicts() {
    local strategy="${1:-auto}"
    local conflict_type="${2:-all}"
    
    log_info "Resolving all conflicts of type: $conflict_type"
    
    for conflict_file in "$CONFLICT_ACTIVE"/*.conflict; do
        [[ -f "$conflict_file" ]] || continue
        
        local ctype=$(jq -r '.conflict_type' "$conflict_file")
        [[ "$conflict_type" == "all" ]] || [[ "$ctype" == "$conflict_type" ]] || continue
        
        resolve_conflict "$conflict_file" "$strategy"
    done
}

# Monitor and auto-resolve
monitor_conflicts() {
    local interval="${1:-30}"  # Check every 30 seconds
    local auto_resolve="${2:-true}"
    
    log_info "Starting conflict monitor (interval: ${interval}s, auto-resolve: $auto_resolve)"
    
    while true; do
        # Check for new conflicts
        local conflict_count=$(find "$CONFLICT_ACTIVE" -name "*.conflict" | wc -l)
        
        if (( conflict_count > 0 )); then
            log_info "Found $conflict_count active conflicts"
            
            if [[ "$auto_resolve" == "true" ]]; then
                resolve_all_conflicts "auto"
            else
                # Just notify
                local broadcast_script="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/broadcast.sh"
                if [[ -x "$broadcast_script" ]]; then
                    export TOOL_NAME="ConflictResolver"
                    export TOOL_OUTPUT=$(jq -n --arg count "$conflict_count" \
                        '{
                            type: "conflict_alert",
                            active_conflicts: ($count | tonumber),
                            action_required: "manual_resolution"
                        }')
                    "$broadcast_script"
                fi
            fi
        fi
        
        sleep "$interval"
    done
}

# Main execution
main() {
    initialize_resolution_system
    
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        resolve)
            resolve_conflict "$@"
            ;;
        resolve-all)
            resolve_all_conflicts "$@"
            ;;
        monitor)
            monitor_conflicts "$@"
            ;;
        priority)
            get_agent_priority "$@"
            ;;
        rules)
            cat "$RESOLUTION_RULES" | jq '.'
            ;;
        help|*)
            cat <<EOF
Usage: $0 <command> [options]

Commands:
    resolve <conflict_file> [strategy] [resolver]
        Resolve a specific conflict
    
    resolve-all [strategy] [type]
        Resolve all conflicts of given type
    
    monitor [interval] [auto_resolve]
        Monitor and optionally auto-resolve conflicts
    
    priority <agent_id> [agent_type]
        Get agent priority level
    
    rules
        Display resolution rules

Strategies:
    auto        Use rules-based automatic resolution
    priority    Resolve based on agent hierarchy
    manual      Mark for manual resolution

Examples:
    $0 resolve /path/to/conflict.conflict auto
    $0 resolve-all priority resource_contention
    $0 monitor 60 true
EOF
            ;;
    esac
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi