#!/bin/bash
# MetaClaude Concept Density Analysis Hook
# Analyzes files for repetition of core concepts and calculates density scores

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATTERNS_FILE="$SCRIPT_DIR/concept-patterns.json"
CONCEPTS_DB="$SCRIPT_DIR/../../../data/concept-density.json"

# Initialize data directory
mkdir -p "$(dirname "$CONCEPTS_DB")"

# Function to count words in a file
count_words() {
    local file="$1"
    wc -w < "$file" 2>/dev/null || echo "0"
}

# Function to count concept occurrences
count_concept_occurrences() {
    local file="$1"
    local keywords="$2"
    local count=0
    
    # Count occurrences (case insensitive) for each keyword
    if [ -f "$file" ]; then
        # Split keywords and count each one
        IFS=',' read -ra keyword_array <<< "$keywords"
        for keyword in "${keyword_array[@]}"; do
            local keyword_count=$(grep -i -o -w "$keyword" "$file" 2>/dev/null | wc -l || echo "0")
            count=$((count + keyword_count))
        done
    fi
    
    echo "$count"
}

# Function to calculate density
calculate_density() {
    local count="$1"
    local word_count="$2"
    
    if [ "$word_count" -eq 0 ]; then
        echo "0"
    else
        # Calculate density as occurrences per 1000 words
        echo "scale=6; ($count * 1000) / $word_count" | bc
    fi
}

# Function to determine file type multiplier
get_file_type_multiplier() {
    local file="$1"
    local multiplier="1.0"
    
    case "$file" in
        *.md|README*|DESIGN*|*.txt)
            multiplier="1.0"
            ;;
        *.sh|*.py|*.js|*.ts)
            multiplier="0.5"
            ;;
        *.json|*.yaml|*.yml|*.config)
            multiplier="0.3"
            ;;
    esac
    
    echo "$multiplier"
}

# Function to analyze a single file
analyze_file() {
    local file="$1"
    local relative_path="${file#./}"
    
    if [ ! -f "$file" ]; then
        return
    fi
    
    # Count total words
    local word_count=$(count_words "$file")
    
    # Get file type multiplier
    local file_multiplier=$(get_file_type_multiplier "$file")
    
    # Initialize JSON output
    local json_output="{\"file\":\"$relative_path\",\"word_count\":$word_count,\"file_type_multiplier\":$file_multiplier,\"concepts\":{"
    
    # Analyze each concept
    local first=true
    while IFS= read -r concept; do
        # Extract concept details from patterns file
        local keywords=$(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    if '$concept' in data['core_concepts']:
        print(','.join(data['core_concepts']['$concept']['keywords']))
" 2>/dev/null || echo "")
        
        if [ -n "$keywords" ]; then
            # Count occurrences
            local count=$(count_concept_occurrences "$file" "$keywords")
            local density=$(calculate_density "$count" "$word_count")
            
            # Get optimal density range
            local min_density=$(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    print(data['core_concepts']['$concept']['optimal_density']['min'])
" 2>/dev/null || echo "0")
            
            local max_density=$(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    print(data['core_concepts']['$concept']['optimal_density']['max'])
" 2>/dev/null || echo "0")
            
            # Adjust density based on file type
            local adjusted_density=$(echo "scale=6; $density * $file_multiplier" | bc)
            
            # Determine status
            local status="optimal"
            if [ "$(echo "$adjusted_density < $min_density" | bc)" -eq 1 ]; then
                status="under"
            elif [ "$(echo "$adjusted_density > $max_density" | bc)" -eq 1 ]; then
                status="over"
            fi
            
            # Add to JSON
            if [ "$first" = false ]; then
                json_output="$json_output,"
            fi
            json_output="$json_output\"$concept\":{\"count\":$count,\"density\":$density,\"adjusted_density\":$adjusted_density,\"status\":\"$status\"}"
            first=false
        fi
    done < <(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    for concept in data['core_concepts']:
        print(concept)
")
    
    json_output="$json_output}}"
    echo "$json_output"
}

# Function to generate recommendations
generate_recommendations() {
    local analysis="$1"
    local recommendations=()
    
    # Parse analysis and generate recommendations
    while IFS= read -r line; do
        local file=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['file'])")
        local has_issues=false
        local over_concepts=()
        local under_concepts=()
        
        # Check each concept
        for concept in transparency adaptability user_centricity orchestration metacognition evolution autonomy; do
            local status=$(echo "$line" | python3 -c "
import json,sys
try:
    data = json.loads(sys.stdin.read())
    print(data['concepts'].get('$concept', {}).get('status', 'unknown'))
except:
    print('unknown')
" 2>/dev/null || echo "unknown")
            
            if [ "$status" = "over" ]; then
                over_concepts+=("$concept")
                has_issues=true
            elif [ "$status" = "under" ]; then
                under_concepts+=("$concept")
                has_issues=true
            fi
        done
        
        # Generate recommendations for this file
        if [ "$has_issues" = true ]; then
            local rec="{\"file\":\"$file\",\"recommendations\":["
            local first=true
            
            # Over-emphasized concepts
            if [ ${#over_concepts[@]} -gt 0 ]; then
                if [ "$first" = false ]; then rec="$rec,"; fi
                rec="$rec{\"type\":\"reduce\",\"concepts\":[\"${over_concepts[*]}\"],\"action\":\"Consider consolidating or referencing central definitions\"}"
                first=false
            fi
            
            # Under-emphasized concepts
            if [ ${#under_concepts[@]} -gt 0 ]; then
                if [ "$first" = false ]; then rec="$rec,"; fi
                rec="$rec{\"type\":\"increase\",\"concepts\":[\"${under_concepts[*]}\"],\"action\":\"Consider adding more context or examples\"}"
                first=false
            fi
            
            rec="$rec]}"
            recommendations+=("$rec")
        fi
    done <<< "$analysis"
    
    # Output recommendations
    if [ ${#recommendations[@]} -gt 0 ]; then
        echo "["
        for i in "${!recommendations[@]}"; do
            echo -n "${recommendations[$i]}"
            if [ $i -lt $((${#recommendations[@]} - 1)) ]; then
                echo ","
            else
                echo ""
            fi
        done
        echo "]"
    else
        echo "[]"
    fi
}

# Main execution
main() {
    local target="${1:-.}"
    local output_format="${2:-json}"
    
    # Find all relevant files
    local files=()
    if [ -f "$target" ]; then
        files=("$target")
    else
        # Find files based on patterns
        while IFS= read -r file; do
            files+=("$file")
        done < <(find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.json" -o -name "README*" \) 2>/dev/null | grep -v node_modules | grep -v .git)
    fi
    
    # Analyze files
    local all_analysis=""
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "{\"timestamp\":\"$timestamp\",\"analysis\":["
    
    local first=true
    for file in "${files[@]}"; do
        local analysis=$(analyze_file "$file")
        if [ -n "$analysis" ]; then
            if [ "$first" = false ]; then
                echo ","
            fi
            echo -n "$analysis"
            all_analysis="$all_analysis$analysis\n"
            first=false
        fi
    done
    
    echo "],"
    
    # Generate recommendations
    echo "\"recommendations\":"
    generate_recommendations "$all_analysis"
    
    echo "}"
    
    # Store results in database
    if [ -n "$all_analysis" ]; then
        echo "{\"timestamp\":\"$timestamp\",\"files_analyzed\":${#files[@]}}" >> "$CONCEPTS_DB"
    fi
}

# Execute main function
main "$@"