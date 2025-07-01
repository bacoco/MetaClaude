#!/bin/bash
# MetaClaude Handoff Tracking System
# Logs all cross-agent communications and handoffs

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../../../logs/metaclaude"
HANDOFF_LOG="${LOG_DIR}/handoffs.jsonl"
PERMISSION_MATRIX="${SCRIPT_DIR}/permission-matrix.json"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Function to generate unique handoff ID
generate_handoff_id() {
    echo "handoff_$(date +%s)_${RANDOM}"
}

# Function to log handoff
log_handoff() {
    local handoff_id="$1"
    local timestamp="$2"
    local source_agent="$3"
    local target_agent="$4"
    local operation="$5"
    local payload="$6"
    local status="$7"
    local metadata="${8:-{}}"
    
    # Create handoff record
    local handoff_record=$(jq -n \
        --arg id "${handoff_id}" \
        --arg ts "${timestamp}" \
        --arg src "${source_agent}" \
        --arg tgt "${target_agent}" \
        --arg op "${operation}" \
        --arg pl "${payload}" \
        --arg st "${status}" \
        --argjson md "${metadata}" \
        '{
            id: $id,
            timestamp: $ts,
            source_agent: $src,
            target_agent: $tgt,
            operation: $op,
            payload: $pl,
            status: $st,
            metadata: $md
        }')
    
    echo "${handoff_record}" >> "${HANDOFF_LOG}"
}

# Function to validate handoff permission
validate_handoff() {
    local source_agent="$1"
    local target_agent="$2"
    local operation="$3"
    
    # Check delegation rules from permission matrix
    local delegation_rule=$(jq -r ".cross_agent_rules.delegation.\"${source_agent}_to_${target_agent}\"" "${PERMISSION_MATRIX}" 2>/dev/null)
    
    if [ "${delegation_rule}" = "null" ]; then
        # Check generic rules
        if [ "${source_agent}" = "orchestrator" ]; then
            delegation_rule=$(jq -r '.cross_agent_rules.delegation.orchestrator_to_specialist' "${PERMISSION_MATRIX}" 2>/dev/null)
        elif [ "${target_agent}" = "orchestrator" ]; then
            delegation_rule=$(jq -r '.cross_agent_rules.delegation.specialist_to_orchestrator' "${PERMISSION_MATRIX}" 2>/dev/null)
        else
            delegation_rule=$(jq -r '.cross_agent_rules.delegation.specialist_to_specialist' "${PERMISSION_MATRIX}" 2>/dev/null)
        fi
    fi
    
    case "${delegation_rule}" in
        "always_allowed")
            return 0
            ;;
        "requires_orchestrator_approval")
            # In a real implementation, this would check for approval
            # For now, we'll log it as pending approval
            return 1
            ;;
        "request_only")
            # Allowed but marked as request
            return 0
            ;;
        *)
            return 2
            ;;
    esac
}

# Function to track handoff
track_handoff() {
    local source_agent="$1"
    local target_agent="$2"
    local operation="$3"
    local payload="${4:-}"
    local metadata="${5:-{}}"
    
    local handoff_id=$(generate_handoff_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local status="initiated"
    
    # Validate handoff permission
    if validate_handoff "${source_agent}" "${target_agent}" "${operation}"; then
        status="approved"
    else
        status="requires_approval"
    fi
    
    # Log the handoff
    log_handoff "${handoff_id}" "${timestamp}" "${source_agent}" "${target_agent}" \
                "${operation}" "${payload}" "${status}" "${metadata}"
    
    # Return handoff ID for tracking
    echo "${handoff_id}"
}

# Function to update handoff status
update_handoff_status() {
    local handoff_id="$1"
    local new_status="$2"
    local completion_metadata="${3:-{}}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create status update record
    local update_record=$(jq -n \
        --arg id "${handoff_id}" \
        --arg ts "${timestamp}" \
        --arg st "${new_status}" \
        --argjson md "${completion_metadata}" \
        '{
            handoff_id: $id,
            timestamp: $ts,
            status_update: $st,
            completion_metadata: $md
        }')
    
    echo "${update_record}" >> "${HANDOFF_LOG}"
}

# Function to generate handoff summary
generate_summary() {
    local since="${1:-1hour}"
    local summary_file="${LOG_DIR}/handoff_summary_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "MetaClaude Handoff Summary" > "${summary_file}"
    echo "=========================" >> "${summary_file}"
    echo "Generated: $(date)" >> "${summary_file}"
    echo "" >> "${summary_file}"
    
    # Count handoffs by status
    echo "Handoffs by Status:" >> "${summary_file}"
    jq -s 'map(select(.status)) | group_by(.status) | map({status: .[0].status, count: length})' \
        "${HANDOFF_LOG}" 2>/dev/null >> "${summary_file}"
    
    echo "" >> "${summary_file}"
    echo "Handoffs by Agent Pair:" >> "${summary_file}"
    jq -s 'map(select(.source_agent and .target_agent)) | 
           group_by(.source_agent + " -> " + .target_agent) | 
           map({pair: .[0].source_agent + " -> " + .[0].target_agent, count: length})' \
        "${HANDOFF_LOG}" 2>/dev/null >> "${summary_file}"
    
    echo "" >> "${summary_file}"
    echo "Recent Handoffs:" >> "${summary_file}"
    tail -n 10 "${HANDOFF_LOG}" | jq '.' >> "${summary_file}"
    
    echo "Summary saved to: ${summary_file}"
}

# Main function
main() {
    local command="${1:-track}"
    
    case "${command}" in
        "track")
            if [ $# -lt 4 ]; then
                echo "Usage: $0 track <source_agent> <target_agent> <operation> [payload] [metadata]" >&2
                exit 1
            fi
            track_handoff "${2}" "${3}" "${4}" "${5:-}" "${6:-{}}"
            ;;
        "update")
            if [ $# -lt 3 ]; then
                echo "Usage: $0 update <handoff_id> <new_status> [metadata]" >&2
                exit 1
            fi
            update_handoff_status "${2}" "${3}" "${4:-{}}"
            ;;
        "summary")
            generate_summary "${2:-1hour}"
            ;;
        *)
            echo "Usage: $0 {track|update|summary} [args...]" >&2
            exit 1
            ;;
    esac
}

# Run main function
main "$@"