#!/bin/bash
# PreToolUse hook: role-enforcer.sh - Enforce agent role boundaries

set -euo pipefail

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Role enforcement directories
ROLE_DIR="${CLAUDE_LOGS_DIR}/metaclaude/roles"
ROLE_VIOLATIONS="${ROLE_DIR}/violations"
ROLE_PATTERNS="${ROLE_DIR}/patterns"
DELEGATION_LOG="${ROLE_DIR}/delegations"

# Initialize role enforcement system
initialize_role_system() {
    mkdir -p "$ROLE_VIOLATIONS" "$ROLE_PATTERNS" "$DELEGATION_LOG"
}

# Agent role definitions
AGENT_ROLES='{
    "orchestrator": {
        "type": "orchestration",
        "allowed_tools": ["Task", "Agent", "TodoWrite", "TodoRead", "Memory"],
        "forbidden_tools": ["Write", "Edit", "MultiEdit", "Delete"],
        "delegation_required": ["implementation", "coding", "testing", "debugging"],
        "description": "Coordinates and delegates tasks to other agents"
    },
    "architect": {
        "type": "orchestration",
        "allowed_tools": ["Read", "TodoWrite", "Memory", "Task"],
        "forbidden_tools": ["Write", "Edit", "MultiEdit"],
        "delegation_required": ["implementation"],
        "description": "Designs system architecture and patterns"
    },
    "coder": {
        "type": "execution",
        "allowed_tools": ["Write", "Edit", "MultiEdit", "Read", "TodoWrite", "Bash"],
        "forbidden_tools": ["Task", "Agent"],
        "delegation_required": [],
        "description": "Implements code changes"
    },
    "tester": {
        "type": "execution",
        "allowed_tools": ["Read", "Bash", "TodoWrite"],
        "forbidden_tools": ["Write", "Edit", "Task", "Agent"],
        "delegation_required": ["implementation"],
        "description": "Tests code and validates functionality"
    },
    "researcher": {
        "type": "analysis",
        "allowed_tools": ["Read", "WebSearch", "WebFetch", "Memory", "TodoRead"],
        "forbidden_tools": ["Write", "Edit", "MultiEdit", "Delete", "Task"],
        "delegation_required": ["implementation", "execution"],
        "description": "Researches and analyzes information"
    },
    "reviewer": {
        "type": "analysis",
        "allowed_tools": ["Read", "TodoRead", "Memory"],
        "forbidden_tools": ["Write", "Edit", "MultiEdit", "Delete"],
        "delegation_required": ["implementation"],
        "description": "Reviews code and provides feedback"
    },
    "debugger": {
        "type": "execution",
        "allowed_tools": ["Read", "Bash", "Edit", "TodoWrite"],
        "forbidden_tools": ["Task", "Agent"],
        "delegation_required": [],
        "description": "Debugs and fixes issues"
    },
    "analyzer": {
        "type": "analysis",
        "allowed_tools": ["Read", "Bash", "Memory", "TodoRead"],
        "forbidden_tools": ["Write", "Edit", "MultiEdit", "Delete", "Task"],
        "delegation_required": ["implementation"],
        "description": "Analyzes code and performance"
    }
}'

# Get agent role configuration
get_agent_role() {
    local agent_type="${1:-${AGENT_TYPE:-unknown}}"
    
    # Check if role is defined
    if echo "$AGENT_ROLES" | jq -e --arg type "$agent_type" '.[$type]' >/dev/null 2>&1; then
        echo "$AGENT_ROLES" | jq --arg type "$agent_type" '.[$type]'
    else
        # Return default role for unknown agents
        echo '{
            "type": "general",
            "allowed_tools": ["Read", "TodoRead", "Memory"],
            "forbidden_tools": [],
            "delegation_required": [],
            "description": "General purpose agent"
        }'
    fi
}

# Check if tool usage is allowed for agent
check_tool_permission() {
    local agent_type="${1:-${AGENT_TYPE:-unknown}}"
    local tool_name="$2"
    
    local role_config=$(get_agent_role "$agent_type")
    local role_type=$(echo "$role_config" | jq -r '.type')
    local allowed_tools=$(echo "$role_config" | jq -r '.allowed_tools[]?' 2>/dev/null)
    local forbidden_tools=$(echo "$role_config" | jq -r '.forbidden_tools[]?' 2>/dev/null)
    
    # Check forbidden tools first
    if echo "$forbidden_tools" | grep -q "^${tool_name}$"; then
        return 1  # Tool is forbidden
    fi
    
    # Check if tool is explicitly allowed
    if echo "$allowed_tools" | grep -q "^${tool_name}$"; then
        return 0  # Tool is allowed
    fi
    
    # Check role-based permissions
    case "$role_type" in
        "orchestration")
            # Orchestrators should not directly execute
            case "$tool_name" in
                "Write"|"Edit"|"MultiEdit"|"Delete"|"NotebookEdit")
                    return 1
                    ;;
                *)
                    return 0
                    ;;
            esac
            ;;
        "execution")
            # Executors should not orchestrate
            case "$tool_name" in
                "Task"|"Agent")
                    return 1
                    ;;
                *)
                    return 0
                    ;;
            esac
            ;;
        "analysis")
            # Analyzers should only read and analyze
            case "$tool_name" in
                "Write"|"Edit"|"MultiEdit"|"Delete"|"Task"|"Agent")
                    return 1
                    ;;
                *)
                    return 0
                    ;;
            esac
            ;;
        *)
            # General agents have limited permissions
            return 0
            ;;
    esac
}

# Detect delegation requirements
check_delegation_required() {
    local agent_type="${1:-${AGENT_TYPE:-unknown}}"
    local operation="$2"
    
    local role_config=$(get_agent_role "$agent_type")
    local delegation_required=$(echo "$role_config" | jq -r '.delegation_required[]?' 2>/dev/null)
    
    # Check if operation requires delegation
    for required in $delegation_required; do
        if [[ "$operation" =~ $required ]]; then
            return 0  # Delegation required
        fi
    done
    
    return 1  # No delegation required
}

# Record role violation
record_violation() {
    local agent_type="$1"
    local agent_id="$2"
    local tool_name="$3"
    local violation_type="$4"
    local details="$5"
    
    local violation_id="$(date +%s.%N)_${agent_id}"
    local violation_file="${ROLE_VIOLATIONS}/${violation_id}.violation"
    
    jq -n \
        --arg agent_type "$agent_type" \
        --arg agent_id "$agent_id" \
        --arg tool "$tool_name" \
        --arg vtype "$violation_type" \
        --arg details "$details" \
        '{
            violation_id: $ARGS.named.id,
            timestamp: now | floor,
            agent: {
                type: $agent_type,
                id: $agent_id
            },
            tool: $tool,
            violation_type: $vtype,
            details: $details,
            created_at: now | strftime("%Y-%m-%dT%H:%M:%SZ")
        }' \
        --arg id "$violation_id" > "$violation_file"
    
    log_warn "ROLE VIOLATION: $agent_type/$agent_id attempted $violation_type with $tool_name"
}

# Suggest delegation
suggest_delegation() {
    local agent_type="$1"
    local operation="$2"
    local context="$3"
    
    local suggested_agent=""
    local delegation_reason=""
    
    # Determine appropriate agent for delegation
    case "$operation" in
        *implement*|*code*|*write*)
            suggested_agent="coder"
            delegation_reason="Implementation work should be delegated to a coder agent"
            ;;
        *test*|*validate*)
            suggested_agent="tester"
            delegation_reason="Testing should be delegated to a tester agent"
            ;;
        *debug*|*fix*)
            suggested_agent="debugger"
            delegation_reason="Debugging should be delegated to a debugger agent"
            ;;
        *analyze*|*review*)
            suggested_agent="analyzer"
            delegation_reason="Analysis should be delegated to an analyzer agent"
            ;;
        *research*|*investigate*)
            suggested_agent="researcher"
            delegation_reason="Research should be delegated to a researcher agent"
            ;;
    esac
    
    if [[ -n "$suggested_agent" ]]; then
        # Log delegation suggestion
        local delegation_file="${DELEGATION_LOG}/$(date +%s.%N).delegation"
        jq -n \
            --arg from "$agent_type" \
            --arg to "$suggested_agent" \
            --arg op "$operation" \
            --arg reason "$delegation_reason" \
            --arg context "$context" \
            '{
                from_agent: $from,
                to_agent: $to,
                operation: $op,
                reason: $reason,
                context: $context,
                timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ")
            }' > "$delegation_file"
        
        # Broadcast delegation suggestion
        local broadcast_script="${CLAUDE_HOOKS_DIR}/metaclaude/coordination/broadcast.sh"
        if [[ -x "$broadcast_script" ]]; then
            export TOOL_NAME="RoleEnforcer"
            export TOOL_OUTPUT=$(jq -n \
                --arg agent "$agent_type" \
                --arg suggested "$suggested_agent" \
                --arg reason "$delegation_reason" \
                '{
                    type: "delegation_suggestion",
                    from_agent: $agent,
                    suggested_agent: $suggested,
                    reason: $reason,
                    action: "create_task_for_agent"
                }')
            "$broadcast_script"
        fi
        
        log_info "Suggested delegation: $agent_type should delegate '$operation' to $suggested_agent"
    fi
}

# Track delegation patterns
track_delegation_pattern() {
    local from_agent="$1"
    local to_agent="$2"
    local task_type="$3"
    
    local pattern_file="${ROLE_PATTERNS}/${from_agent}_patterns.json"
    
    # Initialize pattern file if needed
    if [[ ! -f "$pattern_file" ]]; then
        echo '{"delegations": {}}' > "$pattern_file"
    fi
    
    # Update delegation pattern
    local temp_file=$(mktemp)
    jq --arg to "$to_agent" --arg task "$task_type" \
        '.delegations[$to] = (.delegations[$to] // {}) |
         .delegations[$to][$task] = ((.delegations[$to][$task] // 0) + 1) |
         .last_updated = now' \
        "$pattern_file" > "$temp_file"
    mv "$temp_file" "$pattern_file"
}

# Analyze role compliance
analyze_role_compliance() {
    local agent_type="${1:-all}"
    local time_window="${2:-3600}"  # Default 1 hour
    
    log_info "Role Compliance Analysis for: $agent_type"
    
    # Count violations
    local total_violations=0
    local violations_by_type='{}'
    
    find "$ROLE_VIOLATIONS" -name "*.violation" -mmin -$((time_window/60)) | while read -r vfile; do
        local v_agent=$(jq -r '.agent.type' "$vfile")
        [[ "$agent_type" == "all" ]] || [[ "$v_agent" == "$agent_type" ]] || continue
        
        local v_type=$(jq -r '.violation_type' "$vfile")
        ((total_violations++))
        
        # Count by type
        violations_by_type=$(echo "$violations_by_type" | jq --arg type "$v_type" \
            '.[$type] = ((.[$type] // 0) + 1)')
    done
    
    echo "Total violations: $total_violations"
    echo "Violations by type:"
    echo "$violations_by_type" | jq '.'
    
    # Show delegation patterns
    if [[ "$agent_type" != "all" ]] && [[ -f "${ROLE_PATTERNS}/${agent_type}_patterns.json" ]]; then
        echo ""
        echo "Delegation patterns for $agent_type:"
        jq '.delegations' "${ROLE_PATTERNS}/${agent_type}_patterns.json"
    fi
}

# PreToolUse hook handler
handle_pre_tool_use() {
    local tool_name="${1:-unknown}"
    local tool_args="${2:-}"
    local agent_type="${AGENT_TYPE:-unknown}"
    local agent_id="${AGENT_ID:-$$}"
    
    # Check tool permission
    if ! check_tool_permission "$agent_type" "$tool_name"; then
        record_violation "$agent_type" "$agent_id" "$tool_name" "forbidden_tool" \
            "Agent type $agent_type is not allowed to use $tool_name"
        
        # Check if this is an orchestration agent trying to execute
        local role_config=$(get_agent_role "$agent_type")
        local role_type=$(echo "$role_config" | jq -r '.type')
        
        if [[ "$role_type" == "orchestration" ]]; then
            # Extract operation context from args
            local operation_context=""
            case "$tool_name" in
                "Write"|"Edit"|"MultiEdit")
                    operation_context="implement code changes"
                    ;;
                "Delete")
                    operation_context="delete files"
                    ;;
                "NotebookEdit")
                    operation_context="modify notebook"
                    ;;
            esac
            
            suggest_delegation "$agent_type" "$operation_context" "$tool_args"
        fi
        
        # Block the tool usage
        log_error "BLOCKED: $agent_type agent cannot use $tool_name"
        return 1
    fi
    
    # Check if delegation is required
    local operation_context=$(echo "$tool_args" | jq -r '.description // .content // ""' 2>/dev/null || echo "")
    if check_delegation_required "$agent_type" "$operation_context"; then
        record_violation "$agent_type" "$agent_id" "$tool_name" "delegation_required" \
            "Operation '$operation_context' should be delegated"
        
        suggest_delegation "$agent_type" "$operation_context" "$tool_args"
    fi
    
    # Track successful delegations
    if [[ "$tool_name" == "Task" ]] || [[ "$tool_name" == "Agent" ]]; then
        local target_agent=$(echo "$tool_args" | jq -r '.agent_type // .type // "unknown"' 2>/dev/null)
        local task_type=$(echo "$tool_args" | jq -r '.task_type // .description // "general"' 2>/dev/null)
        track_delegation_pattern "$agent_type" "$target_agent" "$task_type"
    fi
    
    return 0
}

# Main execution
main() {
    initialize_role_system
    
    if [[ $# -eq 0 ]]; then
        # Running as PreToolUse hook
        local tool_name="${TOOL_NAME:-unknown}"
        local tool_args="${TOOL_ARGS:-}"
        handle_pre_tool_use "$tool_name" "$tool_args"
    else
        # Running as command
        local command="$1"
        shift
        
        case "$command" in
            check)
                local agent_type="${1:-${AGENT_TYPE:-unknown}}"
                local tool_name="$2"
                if check_tool_permission "$agent_type" "$tool_name"; then
                    echo "ALLOWED: $agent_type can use $tool_name"
                else
                    echo "FORBIDDEN: $agent_type cannot use $tool_name"
                fi
                ;;
            role)
                get_agent_role "$@" | jq '.'
                ;;
            violations)
                local agent_filter="${1:-all}"
                find "$ROLE_VIOLATIONS" -name "*.violation" | while read -r vfile; do
                    local v_agent=$(jq -r '.agent.type' "$vfile")
                    [[ "$agent_filter" == "all" ]] || [[ "$v_agent" == "$agent_filter" ]] || continue
                    jq '.' "$vfile"
                done
                ;;
            analyze)
                analyze_role_compliance "$@"
                ;;
            help|*)
                cat <<EOF
Usage: $0 [command] [options]

Commands:
    check <agent_type> <tool_name>
        Check if agent can use tool
    
    role [agent_type]
        Show role configuration
    
    violations [agent_type]
        List role violations
    
    analyze [agent_type] [time_window]
        Analyze role compliance

When run without arguments, acts as PreToolUse hook.

Agent Types:
    orchestrator - Coordinates and delegates tasks
    architect    - Designs system architecture
    coder        - Implements code changes
    tester       - Tests and validates
    researcher   - Researches information
    reviewer     - Reviews code
    debugger     - Debugs issues
    analyzer     - Analyzes performance
EOF
                ;;
        esac
    fi
}

# Execute if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi