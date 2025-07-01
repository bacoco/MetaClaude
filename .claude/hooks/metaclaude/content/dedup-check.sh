#!/bin/bash
# dedup-check.sh - Content deduplication hook for MetaClaude
# Validates content before Write/Edit operations to prevent redundancy

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Default paths
CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
LOG_FILE="${HOME}/.claude/hooks/metaclaude/monitoring/dedup.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to extract content from tool parameters
extract_content() {
    local tool_params="$1"
    local content=""
    
    # Extract content based on tool type
    if echo "$tool_params" | jq -e '.content' >/dev/null 2>&1; then
        content=$(echo "$tool_params" | jq -r '.content')
    elif echo "$tool_params" | jq -e '.new_string' >/dev/null 2>&1; then
        content=$(echo "$tool_params" | jq -r '.new_string')
    fi
    
    echo "$content"
}

# Function to check for duplicate principles
check_duplicate_principles() {
    local content="$1"
    local duplicates=()
    
    # Common operating principle patterns
    local patterns=(
        "Core Configuration"
        "Thinking Modes"
        "Token Economy"
        "Task Management"
        "Performance Standards"
        "Session Management"
        "Evidence-Based Standards"
        "Security Standards"
        "Model Context Protocol"
        "Cognitive Archetypes"
    )
    
    # Check each pattern in content
    for pattern in "${patterns[@]}"; do
        if echo "$content" | grep -qi "$pattern"; then
            # Check if already in CLAUDE.md
            if grep -qi "$pattern" "$CLAUDE_MD" 2>/dev/null; then
                duplicates+=("$pattern")
            fi
        fi
    done
    
    echo "${duplicates[@]}"
}

# Function to suggest references
suggest_references() {
    local duplicates=("$@")
    local suggestions=""
    
    for dup in "${duplicates[@]}"; do
        suggestions+="- Instead of duplicating '$dup', reference: @include shared/superclaude-*.yml#${dup// /_}\n"
    done
    
    echo -e "$suggestions"
}

# Main execution
main() {
    log_message "Dedup check started"
    
    # Read tool parameters from stdin
    local tool_params
    if ! tool_params=$(cat); then
        log_message "ERROR: Failed to read tool parameters"
        exit 1
    fi
    
    # Extract content
    local content
    content=$(extract_content "$tool_params")
    
    if [[ -z "$content" ]]; then
        log_message "No content to check"
        exit 0
    fi
    
    # Check for duplicates
    local duplicates
    duplicates=($(check_duplicate_principles "$content"))
    
    if [[ ${#duplicates[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Potential duplicate content detected!${NC}"
        echo -e "${YELLOW}Found duplicates for: ${duplicates[*]}${NC}"
        echo -e "\n${GREEN}Suggestions:${NC}"
        suggest_references "${duplicates[@]}"
        
        log_message "Duplicates found: ${duplicates[*]}"
        
        # Return warning (non-zero but not failure)
        exit 2
    else
        log_message "No duplicates found"
        exit 0
    fi
}

# Run main function
main "$@"