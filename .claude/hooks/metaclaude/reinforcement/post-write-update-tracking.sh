#!/bin/bash
# MetaClaude Post-Write Update Tracking Hook
# Updates concept tracking after Write/Edit operations

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRACKING_DB="$SCRIPT_DIR/../../../data/concept-tracking.json"
DENSITY_CHECKER="$SCRIPT_DIR/concept-density.sh"

# Initialize data directory
mkdir -p "$(dirname "$TRACKING_DB")"

# Function to update tracking database
update_tracking() {
    local file="$1"
    local operation="$2"
    local timestamp="$3"
    
    # Run density analysis on the updated file
    local density_result=$("$DENSITY_CHECKER" "$file" 2>/dev/null || echo "{}")
    
    # Extract concept counts
    local concept_summary=$(echo "$density_result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    summary = {}
    for item in data.get('analysis', []):
        if item.get('file') == '$file':
            for concept, details in item.get('concepts', {}).items():
                summary[concept] = {
                    'count': details.get('count', 0),
                    'density': details.get('density', 0),
                    'status': details.get('status', 'unknown')
                }
            break
    print(json.dumps(summary))
except:
    print('{}')
" 2>/dev/null || echo "{}")
    
    # Create tracking entry
    local tracking_entry="{\"timestamp\":\"$timestamp\",\"file\":\"$file\",\"operation\":\"$operation\",\"concepts\":$concept_summary}"
    
    # Append to tracking database
    echo "$tracking_entry" >> "$TRACKING_DB"
}

# Function to check tracking trends
check_trends() {
    local file="$1"
    
    if [ ! -f "$TRACKING_DB" ]; then
        return
    fi
    
    # Analyze recent trends for this file
    local trend_data=$(tail -n 20 "$TRACKING_DB" | grep "\"file\":\"$file\"" 2>/dev/null || echo "")
    
    if [ -z "$trend_data" ]; then
        return
    fi
    
    # Check if concepts are consistently over-emphasized
    local persistent_issues=$(echo "$trend_data" | python3 -c "
import json, sys

issues = {}
entries = 0

for line in sys.stdin:
    try:
        data = json.loads(line.strip())
        entries += 1
        for concept, details in data.get('concepts', {}).items():
            if details.get('status') == 'over':
                issues[concept] = issues.get(concept, 0) + 1
    except:
        pass

# Report concepts that are over-emphasized in >50% of recent entries
if entries > 0:
    for concept, count in issues.items():
        if count / entries > 0.5:
            print(f'{concept}: {count}/{entries} entries')
" 2>/dev/null || echo "")
    
    if [ -n "$persistent_issues" ]; then
        echo "📊 Concept Density Trends for $file:" >&2
        echo "$persistent_issues" | while IFS= read -r issue; do
            echo "   - $issue show persistent over-emphasis" >&2
        done
        echo "   Consider running: $SCRIPT_DIR/suggest-consolidation.sh $file" >&2
        echo "" >&2
    fi
}

# Function to trigger consolidation suggestions
suggest_consolidation_if_needed() {
    local file="$1"
    local timestamp="$2"
    
    # Check if file has multiple over-emphasized concepts
    local issue_count=$(grep "\"file\":\"$file\"" "$TRACKING_DB" 2>/dev/null | tail -n 1 | grep -o "\"status\":\"over\"" | wc -l || echo "0")
    
    if [ "$issue_count" -gt 2 ]; then
        # Run consolidation suggestions
        local suggestions=$("$SCRIPT_DIR/suggest-consolidation.sh" "$file" 2>/dev/null || echo "{}")
        
        # Log suggestion timestamp
        echo "{\"timestamp\":\"$timestamp\",\"file\":\"$file\",\"consolidation_suggested\":true}" >> "$TRACKING_DB"
    fi
}

# Main hook logic
main() {
    local tool_name="$1"
    local file_path="$2"
    local success="${3:-true}"
    
    # Only process successful Write/Edit operations
    if [ "$tool_name" != "Write" ] && [ "$tool_name" != "Edit" ] && [ "$tool_name" != "MultiEdit" ]; then
        exit 0
    fi
    
    if [ "$success" != "true" ]; then
        exit 0
    fi
    
    # Skip non-relevant files
    case "$file_path" in
        *.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.tar|*.gz)
            exit 0
            ;;
        */node_modules/*|*/.git/*|*/dist/*|*/build/*)
            exit 0
            ;;
    esac
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Update tracking
    update_tracking "$file_path" "$tool_name" "$timestamp"
    
    # Check trends
    check_trends "$file_path"
    
    # Suggest consolidation if needed
    suggest_consolidation_if_needed "$file_path" "$timestamp"
    
    exit 0
}

# Execute main function
main "$@"