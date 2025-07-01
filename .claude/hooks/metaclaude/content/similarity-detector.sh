#!/bin/bash
# similarity-detector.sh - Content similarity detection using grep patterns
# Outputs JSON with similarity scores for potential duplicate content

set -euo pipefail

# Default paths
CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
PROJECT_ROOT="${HOME}/develop/DesignerClaude/UIDesignerClaude"
LOG_FILE="${HOME}/.claude/hooks/metaclaude/monitoring/similarity.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to calculate similarity score
calculate_similarity() {
    local content="$1"
    local reference_file="$2"
    local pattern="$3"
    
    # Count matching lines
    local content_lines=$(echo "$content" | wc -l)
    local matching_lines=$(echo "$content" | grep -c "$pattern" || true)
    local reference_matches=$(grep -c "$pattern" "$reference_file" 2>/dev/null || true)
    
    # Calculate similarity percentage
    local similarity=0
    if [[ $content_lines -gt 0 ]]; then
        similarity=$((matching_lines * 100 / content_lines))
    fi
    
    echo "$similarity"
}

# Function to detect patterns
detect_patterns() {
    local content="$1"
    local results="[]"
    
    # Key patterns to check (using parallel arrays for compatibility)
    local pattern_names=(
        "configuration"
        "standards"
        "rules"
        "modes"
        "management"
        "integration"
        "workflow"
        "performance"
        "security"
        "architecture"
    )
    
    local pattern_values=(
        "^#.*Configuration|^##.*Config"
        "Standards|##.*Standard"
        "Rules.*:|##.*Rules"
        "Mode.*:|##.*Modes"
        "Management|##.*Manage"
        "Integration|##.*Integrat"
        "Workflow|##.*Workflow"
        "Performance|##.*Perform"
        "Security|##.*Secur"
        "Architecture|##.*Architect"
    )
    
    # Check each pattern
    for i in "${!pattern_names[@]}"; do
        local pattern_name="${pattern_names[$i]}"
        local pattern="${pattern_values[$i]}"
        
        # Check in CLAUDE.md
        if [[ -f "$CLAUDE_MD" ]]; then
            local similarity=$(calculate_similarity "$content" "$CLAUDE_MD" "$pattern")
            
            if [[ $similarity -gt 20 ]]; then
                results=$(echo "$results" | jq --arg name "$pattern_name" \
                    --arg score "$similarity" \
                    --arg file "$CLAUDE_MD" \
                    '. += [{
                        "pattern": $name,
                        "similarity_score": ($score | tonumber),
                        "reference_file": $file,
                        "suggestion": "Consider referencing existing configuration"
                    }]')
            fi
        fi
        
        # Check in project files
        local project_files=$(find "$PROJECT_ROOT" -name "*.md" -o -name "*.yml" -o -name "*.json" 2>/dev/null | head -20)
        while IFS= read -r file; do
            if [[ -f "$file" && "$file" != *"node_modules"* ]]; then
                local similarity=$(calculate_similarity "$content" "$file" "$pattern")
                
                if [[ $similarity -gt 30 ]]; then
                    results=$(echo "$results" | jq --arg name "$pattern_name" \
                        --arg score "$similarity" \
                        --arg file "$file" \
                        '. += [{
                            "pattern": $name,
                            "similarity_score": ($score | tonumber),
                            "reference_file": $file,
                            "suggestion": "Similar content exists in project"
                        }]')
                fi
            fi
        done <<< "$project_files"
    done
    
    echo "$results"
}

# Function to analyze content chunks
analyze_chunks() {
    local content="$1"
    local chunk_results="[]"
    
    # Split content into meaningful chunks (paragraphs/sections)
    local chunks=()
    IFS=$'\n\n' read -ra chunks <<< "$content"
    
    for i in "${!chunks[@]}"; do
        local chunk="${chunks[$i]}"
        if [[ ${#chunk} -gt 50 ]]; then  # Only analyze substantial chunks
            # Extract key terms
            local key_terms=$(echo "$chunk" | grep -oE '[A-Z][a-z]+[A-Z][a-z]+|[A-Z]{2,}' | sort -u | head -5)
            
            if [[ -n "$key_terms" ]]; then
                chunk_results=$(echo "$chunk_results" | jq --arg idx "$i" \
                    --arg terms "$key_terms" \
                    --arg size "${#chunk}" \
                    '. += [{
                        "chunk_index": ($idx | tonumber),
                        "size": ($size | tonumber),
                        "key_terms": ($terms | split("\n")),
                        "type": "content_block"
                    }]')
            fi
        fi
    done
    
    echo "$chunk_results"
}

# Main execution
main() {
    log_message "Similarity detection started"
    
    # Read content from stdin or first argument
    local content=""
    if [[ $# -gt 0 ]]; then
        content="$1"
    else
        content=$(cat)
    fi
    
    if [[ -z "$content" ]]; then
        echo '{"error": "No content provided", "patterns": [], "chunks": []}'
        exit 0
    fi
    
    # Detect patterns
    local pattern_results
    pattern_results=$(detect_patterns "$content")
    
    # Analyze chunks
    local chunk_results
    chunk_results=$(analyze_chunks "$content")
    
    # Combine results
    local final_results
    final_results=$(jq -n \
        --argjson patterns "$pattern_results" \
        --argjson chunks "$chunk_results" \
        '{
            "timestamp": now | strftime("%Y-%m-%d %H:%M:%S"),
            "content_length": 0,
            "patterns": $patterns,
            "chunks": $chunks,
            "summary": {
                "total_patterns": ($patterns | length),
                "high_similarity_count": ($patterns | map(select(.similarity_score > 50)) | length),
                "chunks_analyzed": ($chunks | length)
            }
        }')
    
    # Add content length
    final_results=$(echo "$final_results" | jq --arg len "${#content}" '.content_length = ($len | tonumber)')
    
    # Output results
    echo "$final_results"
    
    # Log summary
    local high_sim_count=$(echo "$final_results" | jq -r '.summary.high_similarity_count')
    log_message "Detection complete: $high_sim_count high similarity patterns found"
}

# Run main function
main "$@"