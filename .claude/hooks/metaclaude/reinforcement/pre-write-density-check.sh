#!/bin/bash
# MetaClaude Pre-Write Density Check Hook
# Checks concept density before Write/Edit operations

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DENSITY_CHECKER="$SCRIPT_DIR/concept-density.sh"
BALANCE_CHECKER="$SCRIPT_DIR/balance-checker.sh"

# Function to check if file should be analyzed
should_analyze_file() {
    local file="$1"
    
    # Skip non-text files
    case "$file" in
        *.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.tar|*.gz)
            return 1
            ;;
        */node_modules/*|*/.git/*|*/dist/*|*/build/*)
            return 1
            ;;
    esac
    
    return 0
}

# Function to analyze proposed content
analyze_proposed_content() {
    local file="$1"
    local content="$2"
    
    # Create temporary file with proposed content
    local temp_file="/tmp/metaclaude_density_check_$$"
    echo "$content" > "$temp_file"
    
    # Run density analysis on proposed content
    local density_result=$("$DENSITY_CHECKER" "$temp_file" 2>/dev/null || echo "{}")
    
    # Clean up
    rm -f "$temp_file"
    
    # Extract any over-emphasized concepts
    local over_concepts=$(echo "$density_result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    over = []
    for item in data.get('analysis', []):
        for concept, details in item.get('concepts', {}).items():
            if details.get('status') == 'over':
                over.append(concept)
    if over:
        print(','.join(over))
except:
    pass
" 2>/dev/null || echo "")
    
    echo "$over_concepts"
}

# Main hook logic
main() {
    local tool_name="$1"
    local file_path="$2"
    local content="${3:-}"
    
    # Only process Write and Edit operations
    if [ "$tool_name" != "Write" ] && [ "$tool_name" != "Edit" ] && [ "$tool_name" != "MultiEdit" ]; then
        exit 0
    fi
    
    # Check if file should be analyzed
    if ! should_analyze_file "$file_path"; then
        exit 0
    fi
    
    # For new files or significant edits, check proposed density
    if [ -n "$content" ]; then
        local over_concepts=$(analyze_proposed_content "$file_path" "$content")
        
        if [ -n "$over_concepts" ]; then
            # Log warning but don't block the operation
            echo "⚠️  Concept Density Warning for $file_path" >&2
            echo "   Over-emphasized concepts detected: $over_concepts" >&2
            echo "   Consider using references to existing definitions or implicit understanding." >&2
            echo "" >&2
        fi
    fi
    
    # Always allow the operation to proceed
    exit 0
}

# Execute main function
main "$@"