#!/bin/bash

# Tool Usage Matrix Enforcement Hook
# Validates tool calls against tool-usage-matrix.md rules
# Returns JSON with validation results and suggestions
# Compatible with bash 3.x

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
MATRIX_FILE="$CLAUDE_ROOT/.claude/patterns/tool-usage-matrix.md"
LOG_FILE="$CLAUDE_ROOT/.claude/logs/metaclaude/tool-enforcement.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to analyze user request
analyze_request() {
    local request="$1"
    local request_lower=$(echo "$request" | tr '[:upper:]' '[:lower:]')
    local suggested_tools=""
    
    # Check for patterns that require specific tools
    if echo "$request_lower" | grep -q "analyze existing\|review current\|view inspiration\|check existing"; then
        suggested_tools="$suggested_tools read_file"
    fi
    
    if echo "$request_lower" | grep -q "save this\|create a file\|create file\|export to"; then
        suggested_tools="$suggested_tools write_file"
    fi
    
    if echo "$request_lower" | grep -q "install\|set up\|configure\|build\|run test"; then
        suggested_tools="$suggested_tools run_shell_command"
    fi
    
    if echo "$request_lower" | grep -q "find\|search for\|locate"; then
        suggested_tools="$suggested_tools search_file_content"
    fi
    
    if echo "$request_lower" | grep -q "list\|show structure"; then
        suggested_tools="$suggested_tools list_files"
    fi
    
    # Remove duplicates
    echo "$suggested_tools" | tr ' ' '\n' | sort -u | grep -v '^$'
}

# Function to validate tool usage
validate_tool_usage() {
    local tool_name="$1"
    local context="$2"
    local validation_result="valid"
    local suggestions=""
    
    # Check if tool exists in our allowed set
    case "$tool_name" in
        read_file|write_file|run_shell_command|search_file_content|list_files)
            validation_result="valid"
            ;;
        Edit|MultiEdit|Read|Write|Bash|Grep|Glob|LS)
            # Claude Code native tools - valid
            validation_result="valid"
            ;;
        *)
            validation_result="unknown"
            suggestions="Unknown tool: $tool_name"
            ;;
    esac
    
    echo "$validation_result|$suggestions"
}

# Function to suggest better alternatives
suggest_alternatives() {
    local current_tool="$1"
    local operation="$2"
    local alternatives=""
    
    case "$operation" in
        *"multiple files"*)
            if [[ "$current_tool" == "read_file" ]]; then
                alternatives="Consider using batch operations or search_file_content for multiple files"
            fi
            ;;
        *"save"*|*"create"*)
            if [[ "$current_tool" != "write_file" && "$current_tool" != "Write" ]]; then
                alternatives="Use write_file or Write for saving content"
            fi
            ;;
        *"analyze"*|*"review"*)
            if [[ "$current_tool" != "read_file" && "$current_tool" != "Read" ]]; then
                alternatives="Use read_file or Read to access existing content"
            fi
            ;;
        *"search"*|*"find"*)
            if [[ "$current_tool" != "search_file_content" && "$current_tool" != "Grep" && "$current_tool" != "Glob" ]]; then
                alternatives="Use search_file_content, Grep, or Glob for searching"
            fi
            ;;
    esac
    
    echo "$alternatives"
}

# Main validation function
main() {
    local input_json="${1:-}"
    
    if [[ -z "$input_json" ]]; then
        # Return empty validation if no input
        cat <<EOF
{
  "status": "no_input",
  "message": "No tool usage to validate",
  "suggestions": []
}
EOF
        return 0
    fi
    
    # Parse input (expecting JSON with tool_name and context)
    local tool_name=$(echo "$input_json" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
    local context=$(echo "$input_json" | jq -r '.context // empty' 2>/dev/null || echo "")
    local user_request=$(echo "$input_json" | jq -r '.user_request // empty' 2>/dev/null || echo "")
    
    # Validate tool usage
    local validation_output=$(validate_tool_usage "$tool_name" "$context")
    local validation_result=$(echo "$validation_output" | cut -d'|' -f1)
    local validation_message=$(echo "$validation_output" | cut -d'|' -f2)
    
    # Analyze user request for required tools
    local required_tools=""
    if [[ -n "$user_request" ]]; then
        required_tools=$(analyze_request "$user_request")
    fi
    
    # Get alternative suggestions
    local alternatives=$(suggest_alternatives "$tool_name" "$context")
    
    # Build suggestions array
    local suggestions_json="[]"
    
    # Add required tools if not using them
    if [[ -n "$required_tools" ]]; then
        while IFS= read -r req_tool; do
            if [[ -n "$req_tool" && "$tool_name" != "$req_tool" ]]; then
                suggestions_json=$(echo "$suggestions_json" | jq ". += [{\"type\": \"required\", \"tool\": \"$req_tool\", \"reason\": \"Required for: $user_request\"}]")
            fi
        done <<< "$required_tools"
    fi
    
    # Add alternatives if any
    if [[ -n "$alternatives" ]]; then
        suggestions_json=$(echo "$suggestions_json" | jq ". += [{\"type\": \"alternative\", \"message\": \"$alternatives\"}]")
    fi
    
    # Log the validation
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Tool: $tool_name, Valid: $validation_result, Context: $context" >> "$LOG_FILE"
    
    # Build required tools JSON array
    local required_tools_json="[]"
    if [[ -n "$required_tools" ]]; then
        while IFS= read -r tool; do
            if [[ -n "$tool" ]]; then
                required_tools_json=$(echo "$required_tools_json" | jq ". += [\"$tool\"]")
            fi
        done <<< "$required_tools"
    fi
    
    # Generate output
    cat <<EOF
{
  "status": "$validation_result",
  "tool_name": "$tool_name",
  "validation": {
    "is_valid": $([ "$validation_result" = "valid" ] && echo "true" || echo "false"),
    "message": "$validation_message"
  },
  "required_tools": $required_tools_json,
  "suggestions": $suggestions_json,
  "best_practices": [
    "Always announce tool usage before executing",
    "Use read_file before editing existing files",
    "Validate changes after write operations",
    "Batch related operations when possible"
  ]
}
EOF
}

# Execute main function with input
main "$@"