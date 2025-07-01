#!/bin/bash

# Tool Documentation Auto-Update Hook
# Updates tool documentation based on actual usage patterns
# Adds real examples from successful operations

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
USAGE_LOG="$CLAUDE_ROOT/.claude/logs/metaclaude/tool-usage.jsonl"
MATRIX_FILE="$CLAUDE_ROOT/.claude/patterns/tool-usage-matrix.md"
EXAMPLES_DIR="$CLAUDE_ROOT/.claude/docs/tool-examples"
UPDATE_LOG="$CLAUDE_ROOT/.claude/logs/metaclaude/doc-updates.log"

# Ensure directories exist
mkdir -p "$EXAMPLES_DIR" "$(dirname "$UPDATE_LOG")"

# Function to extract successful examples
extract_examples() {
    local tool_name="$1"
    local limit="${2:-5}"
    local examples="[]"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "$examples"
        return
    fi
    
    # Find successful uses of the tool
    local tool_logs=$(jq -c "select(.tool.name == \"$tool_name\" and .execution.status == \"success\")" "$USAGE_LOG" 2>/dev/null | tail -n "$limit")
    
    while IFS= read -r log_entry; do
        if [[ -n "$log_entry" ]]; then
            local context=$(echo "$log_entry" | jq -r '.context.description // ""')
            local params=$(echo "$log_entry" | jq -c '.tool.parameters // {}')
            local operation=$(echo "$log_entry" | jq -r '.context.operation_type // "general"')
            local timestamp=$(echo "$log_entry" | jq -r '.timestamp // ""')
            
            examples=$(echo "$examples" | jq ". += [{
                \"context\": \"$context\",
                \"parameters\": $params,
                \"operation_type\": \"$operation\",
                \"timestamp\": \"$timestamp\"
            }]")
        fi
    done <<< "$tool_logs"
    
    echo "$examples"
}

# Function to generate example markdown
generate_example_md() {
    local tool_name="$1"
    local examples="$2"
    local example_count=$(echo "$examples" | jq '. | length')
    
    if [[ $example_count -eq 0 ]]; then
        echo "No examples available yet."
        return
    fi
    
    cat <<EOF
## Real Usage Examples for $tool_name

Based on actual successful operations:

EOF
    
    local index=1
    echo "$examples" | jq -c '.[]' | while IFS= read -r example; do
        local context=$(echo "$example" | jq -r '.context')
        local operation=$(echo "$example" | jq -r '.operation_type')
        local params=$(echo "$example" | jq '.parameters')
        
        cat <<EOF
### Example $index: ${operation^} Operation
**Context**: $context

\`\`\`json
$params
\`\`\`

EOF
        index=$((index + 1))
    done
}

# Function to update tool-specific documentation
update_tool_docs() {
    local tool_name="$1"
    local doc_file="$EXAMPLES_DIR/${tool_name}-examples.md"
    
    echo "Updating documentation for $tool_name..." >&2
    
    # Extract examples
    local examples=$(extract_examples "$tool_name" 10)
    
    # Generate documentation
    cat > "$doc_file" <<EOF
# $tool_name - Usage Examples

*Auto-generated from actual usage patterns on $(date -u +"%Y-%m-%d %H:%M:%S UTC")*

$(generate_example_md "$tool_name" "$examples")

## Usage Statistics

$(generate_usage_stats "$tool_name")

## Common Patterns

$(generate_common_patterns "$tool_name")

---
*Documentation auto-updated by MetaClaude*
EOF
    
    echo "$doc_file"
}

# Function to generate usage statistics
generate_usage_stats() {
    local tool_name="$1"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "No usage data available."
        return
    fi
    
    # Calculate statistics
    local total_uses=$(jq -r "select(.tool.name == \"$tool_name\") | .tool.name" "$USAGE_LOG" 2>/dev/null | wc -l)
    local success_count=$(jq -r "select(.tool.name == \"$tool_name\" and .execution.status == \"success\") | .tool.name" "$USAGE_LOG" 2>/dev/null | wc -l)
    local avg_time=$(jq -r "select(.tool.name == \"$tool_name\") | .execution.duration_ms // 0" "$USAGE_LOG" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
    
    # Most common operations
    local common_ops=$(jq -r "select(.tool.name == \"$tool_name\") | .context.operation_type // \"unknown\"" "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -5)
    
    cat <<EOF
- **Total Uses**: $total_uses
- **Success Rate**: $(awk "BEGIN {if($total_uses>0) printf \"%.1f%%\", $success_count / $total_uses * 100; else print \"0%\"}")
- **Average Execution Time**: ${avg_time}ms

### Most Common Operations:
$(echo "$common_ops" | while read count op; do echo "- $op: $count times"; done)
EOF
}

# Function to generate common patterns
generate_common_patterns() {
    local tool_name="$1"
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo "No pattern data available."
        return
    fi
    
    # Find tools commonly used before/after
    local prev_tools=$(jq -c '. as $current | 
        if .tool.name == "'"$tool_name"'" then 
            .execution.previous_tool // "none" 
        else empty end' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -3)
    
    # Find common parameter patterns
    local param_patterns=$(jq -c "select(.tool.name == \"$tool_name\") | .tool.parameters | keys | sort | join(\",\")" "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -3)
    
    cat <<EOF
### Frequently Used With:
$(echo "$prev_tools" | while read count tool; do 
    if [[ "$tool" != "none" && "$tool" != "null" ]]; then
        echo "- Often follows: $tool ($count occurrences)"
    fi
done)

### Common Parameter Combinations:
$(echo "$param_patterns" | while read count pattern; do 
    echo "- Parameters: [$pattern] ($count times)"
done)
EOF
}

# Function to update main matrix documentation
update_matrix_docs() {
    local updates_file=$(mktemp)
    local backup_file="${MATRIX_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
    
    echo "Backing up current matrix to $backup_file..." >&2
    cp "$MATRIX_FILE" "$backup_file"
    
    # Extract real-world examples for each section
    echo "## Real-World Usage Examples" > "$updates_file"
    echo "" >> "$updates_file"
    echo "*The following examples are extracted from actual successful operations:*" >> "$updates_file"
    echo "" >> "$updates_file"
    
    # Add examples for each major tool
    local tools=("read_file" "Read" "write_file" "Write" "run_shell_command" "Bash" "search_file_content" "Grep" "Glob" "list_files" "LS")
    
    for tool in "${tools[@]}"; do
        local examples=$(extract_examples "$tool" 2)
        if [[ $(echo "$examples" | jq '. | length') -gt 0 ]]; then
            echo "### $tool" >> "$updates_file"
            echo "$examples" | jq -r '.[] | "- **\(.operation_type)**: \(.context)"' >> "$updates_file"
            echo "" >> "$updates_file"
        fi
    done
    
    # Check if we should append or update existing examples section
    if grep -q "## Real-World Usage Examples" "$MATRIX_FILE"; then
        # Update existing section
        echo "Updating existing examples section..." >&2
        # This is complex, so for now we'll just log it
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Would update examples section in matrix" >> "$UPDATE_LOG"
    else
        # Append new section
        echo "Adding new examples section to matrix..." >&2
        echo "" >> "$MATRIX_FILE"
        cat "$updates_file" >> "$MATRIX_FILE"
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Added examples section to matrix" >> "$UPDATE_LOG"
    fi
    
    rm -f "$updates_file"
}

# Function to generate summary report
generate_summary() {
    local updated_files="$1"
    local total_examples="$2"
    
    cat <<EOF
{
  "status": "success",
  "message": "Documentation updated successfully",
  "updates": {
    "files_updated": $(echo "$updated_files" | jq -s '. | length'),
    "total_examples_added": $total_examples,
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "files": $(echo "$updated_files" | jq -s .)
}
EOF
}

# Main function
main() {
    local mode="${1:-all}"
    local updated_files="[]"
    local total_examples=0
    
    echo "Starting documentation auto-update..." >&2
    
    case "$mode" in
        all)
            # Update documentation for all tools
            local tools=("read_file" "Read" "write_file" "Write" "Edit" "MultiEdit" "run_shell_command" "Bash" "search_file_content" "Grep" "Glob" "list_files" "LS")
            
            for tool in "${tools[@]}"; do
                local doc_file=$(update_tool_docs "$tool")
                updated_files=$(echo "$updated_files" | jq ". += [\"$doc_file\"]")
                
                # Count examples
                local examples=$(extract_examples "$tool" 10)
                local example_count=$(echo "$examples" | jq '. | length')
                total_examples=$((total_examples + example_count))
            done
            
            # Update matrix documentation
            update_matrix_docs
            updated_files=$(echo "$updated_files" | jq ". += [\"$MATRIX_FILE\"]")
            ;;
            
        tool)
            # Update specific tool documentation
            local tool_name="${2:-}"
            if [[ -z "$tool_name" ]]; then
                echo "{\"status\": \"error\", \"message\": \"Tool name required for tool mode\"}"
                return 1
            fi
            
            local doc_file=$(update_tool_docs "$tool_name")
            updated_files=$(echo "$updated_files" | jq ". += [\"$doc_file\"]")
            
            # Count examples
            local examples=$(extract_examples "$tool_name" 10)
            total_examples=$(echo "$examples" | jq '. | length')
            ;;
            
        matrix)
            # Update only matrix documentation
            update_matrix_docs
            updated_files=$(echo "$updated_files" | jq ". += [\"$MATRIX_FILE\"]")
            ;;
            
        *)
            echo "{\"status\": \"error\", \"message\": \"Invalid mode. Use: all, tool, or matrix\"}"
            return 1
            ;;
    esac
    
    # Log update
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Documentation update completed. Mode: $mode, Files: $(echo "$updated_files" | jq -r '. | length')" >> "$UPDATE_LOG"
    
    # Generate summary
    generate_summary "$updated_files" "$total_examples"
}

# Execute main function with arguments
main "$@"