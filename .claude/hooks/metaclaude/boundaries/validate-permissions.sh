#!/bin/bash
# MetaClaude Permission Validation Hook
# Validates agent operations against the permission matrix
# Exit codes: 0 = allowed, 2 = blocked

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERMISSION_MATRIX="${SCRIPT_DIR}/permission-matrix.json"
LOG_DIR="${SCRIPT_DIR}/../../../logs/metaclaude"
VALIDATION_LOG="${LOG_DIR}/permission-validations.jsonl"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Function to log validation attempts
log_validation() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local result="$1"
    local agent="$2"
    local operation="$3"
    local resource="$4"
    local reason="${5:-}"
    
    echo "{\"timestamp\":\"${timestamp}\",\"result\":\"${result}\",\"agent\":\"${agent}\",\"operation\":\"${operation}\",\"resource\":\"${resource}\",\"reason\":\"${reason}\"}" >> "${VALIDATION_LOG}"
}

# Function to check if agent has permission
check_permission() {
    local agent_type="$1"
    local operation="$2"
    local resource="$3"
    
    # Extract permissions for the agent type
    local permissions=$(jq -r ".agent_types.\"${agent_type}\".permissions" "${PERMISSION_MATRIX}" 2>/dev/null)
    
    if [ "${permissions}" = "null" ] || [ -z "${permissions}" ]; then
        echo "ERROR: Unknown agent type: ${agent_type}" >&2
        return 2
    fi
    
    # Check tool permissions
    if [[ "${operation}" == "tool:"* ]]; then
        local tool="${operation#tool:}"
        local allowed_tools=$(echo "${permissions}" | jq -r '.tools[]' 2>/dev/null)
        
        # Check for wildcard permission
        if echo "${allowed_tools}" | grep -q '^\*$'; then
            return 0
        fi
        
        # Check for specific tool permission
        if echo "${allowed_tools}" | grep -q "^${tool}$"; then
            return 0
        fi
        
        return 2
    fi
    
    # Check file permissions
    if [[ "${operation}" == "file:"* ]]; then
        local action="${operation#file:}"
        local allowed_files=$(echo "${permissions}" | jq -r '.files[]' 2>/dev/null)
        
        # Check for general file permission
        if echo "${allowed_files}" | grep -q "^${action}$"; then
            return 0
        fi
        
        # Check for pattern-based file permission (e.g., write:*.css)
        while IFS= read -r perm; do
            if [[ "${perm}" == "${action}:"* ]]; then
                local pattern="${perm#${action}:}"
                if [[ "${resource}" == ${pattern} ]]; then
                    return 0
                fi
            fi
        done <<< "${allowed_files}"
        
        return 2
    fi
    
    # Check memory permissions
    if [[ "${operation}" == "memory:"* ]]; then
        local action="${operation#memory:}"
        local allowed_memory=$(echo "${permissions}" | jq -r '.memory[]' 2>/dev/null)
        
        # Check for general memory permission
        if echo "${allowed_memory}" | grep -q "^${action}$"; then
            return 0
        fi
        
        # Check for namespace-specific permission (e.g., write:analysis_results)
        if echo "${allowed_memory}" | grep -q "^${action}:${resource}$"; then
            return 0
        fi
        
        return 2
    fi
    
    # Check agent interaction permissions
    if [[ "${operation}" == "agent:"* ]]; then
        local action="${operation#agent:}"
        local allowed_agents=$(echo "${permissions}" | jq -r '.agents[]' 2>/dev/null)
        
        if echo "${allowed_agents}" | grep -q "^${action}$"; then
            return 0
        fi
        
        return 2
    fi
    
    # Check workflow permissions
    if [[ "${operation}" == "workflow:"* ]]; then
        local action="${operation#workflow:}"
        local allowed_workflows=$(echo "${permissions}" | jq -r '.workflows[]' 2>/dev/null)
        
        if echo "${allowed_workflows}" | grep -q "^${action}$"; then
            return 0
        fi
        
        return 2
    fi
    
    # Unknown operation type
    return 2
}

# Main validation logic
main() {
    # Parse environment variables or command line arguments
    local agent_type="${METACLAUDE_AGENT_TYPE:-unknown}"
    local operation="${METACLAUDE_OPERATION:-unknown}"
    local resource="${METACLAUDE_RESOURCE:-unknown}"
    
    # Override with command line arguments if provided
    if [ $# -ge 3 ]; then
        agent_type="$1"
        operation="$2"
        resource="$3"
    fi
    
    # Validate inputs
    if [ "${agent_type}" = "unknown" ] || [ "${operation}" = "unknown" ]; then
        echo "ERROR: Missing required environment variables or arguments" >&2
        echo "Usage: $0 <agent_type> <operation> <resource>" >&2
        echo "Or set: METACLAUDE_AGENT_TYPE, METACLAUDE_OPERATION, METACLAUDE_RESOURCE" >&2
        log_validation "error" "${agent_type}" "${operation}" "${resource}" "missing_parameters"
        exit 2
    fi
    
    # Check permission
    if check_permission "${agent_type}" "${operation}" "${resource}"; then
        log_validation "allowed" "${agent_type}" "${operation}" "${resource}" "permission_granted"
        echo "Permission granted: ${agent_type} can perform ${operation} on ${resource}" >&2
        exit 0
    else
        log_validation "blocked" "${agent_type}" "${operation}" "${resource}" "permission_denied"
        echo "ERROR: Permission denied: ${agent_type} cannot perform ${operation} on ${resource}" >&2
        echo "Please check the permission matrix for allowed operations." >&2
        exit 2
    fi
}

# Run main function
main "$@"