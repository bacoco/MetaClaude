#!/bin/bash
# MetaClaude Consolidation Suggestion Hook
# Identifies over-explained concepts and suggests consolidation strategies

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATTERNS_FILE="$SCRIPT_DIR/concept-patterns.json"
CONSOLIDATION_DB="$SCRIPT_DIR/../../../data/consolidation-suggestions.json"

# Initialize data directory
mkdir -p "$(dirname "$CONSOLIDATION_DB")"

# Function to find repeated definitions
find_repeated_definitions() {
    local file="$1"
    local concept="$2"
    local keywords="$3"
    
    # Find lines containing concept keywords with context
    local occurrences=()
    local line_numbers=()
    
    # Get line numbers and content for each keyword
    IFS=',' read -ra keyword_array <<< "$keywords"
    for keyword in "${keyword_array[@]}"; do
        while IFS=: read -r line_num content; do
            line_numbers+=("$line_num")
            occurrences+=("$content")
        done < <(grep -n -i -w "$keyword" "$file" 2>/dev/null || true)
    done
    
    # Check for repeated definitions
    local repetitions=0
    local first_def_line=""
    local suggestions=()
    
    for i in "${!occurrences[@]}"; do
        local content="${occurrences[$i]}"
        local line="${line_numbers[$i]}"
        
        # Check if this is a definition (contains "is", "means", "refers to", etc.)
        if echo "$content" | grep -i -E "(is |means |refers to |defined as |describes )" >/dev/null 2>&1; then
            if [ -z "$first_def_line" ]; then
                first_def_line="$line"
            else
                repetitions=$((repetitions + 1))
                suggestions+=("{\"line\":$line,\"type\":\"repeated_definition\",\"reference_line\":$first_def_line}")
            fi
        fi
    done
    
    echo "$repetitions" "${suggestions[@]}"
}

# Function to analyze consolidation opportunities
analyze_consolidation() {
    local file="$1"
    local density_analysis="$2"
    
    local relative_path="${file#./}"
    local suggestions=()
    
    # Extract concepts that are over-emphasized
    local over_concepts=$(echo "$density_analysis" | python3 -c "
import json, sys
try:
    for line in sys.stdin:
        data = json.loads(line)
        if data.get('file') == '$relative_path':
            over = []
            for concept, details in data.get('concepts', {}).items():
                if details.get('status') == 'over':
                    over.append(concept)
            print(','.join(over))
            break
except:
    pass
" 2>/dev/null || echo "")
    
    if [ -z "$over_concepts" ]; then
        return
    fi
    
    # Analyze each over-emphasized concept
    IFS=',' read -ra concepts <<< "$over_concepts"
    for concept in "${concepts[@]}"; do
        # Get keywords for this concept
        local keywords=$(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    if '$concept' in data['core_concepts']:
        print(','.join(data['core_concepts']['$concept']['keywords']))
" 2>/dev/null || echo "")
        
        if [ -n "$keywords" ]; then
            # Find repeated definitions
            local result=$(find_repeated_definitions "$file" "$concept" "$keywords")
            local repetitions=$(echo "$result" | cut -d' ' -f1)
            
            if [ "$repetitions" -gt 0 ]; then
                suggestions+=("{\"concept\":\"$concept\",\"repetitions\":$repetitions,\"strategy\":\"consolidate\"}")
            fi
        fi
    done
    
    # Output suggestions
    if [ ${#suggestions[@]} -gt 0 ]; then
        echo "{\"file\":\"$relative_path\",\"suggestions\":[${suggestions[*]}]}"
    fi
}

# Function to generate consolidation strategies
generate_strategies() {
    local file="$1"
    local concept="$2"
    
    local strategies=()
    
    # Strategy 1: Create central definition reference
    strategies+=("{\"type\":\"central_reference\",\"action\":\"Create a central definition in README.md or DESIGN.md and reference it\",\"priority\":\"high\"}")
    
    # Strategy 2: Use implicit understanding
    strategies+=("{\"type\":\"implicit\",\"action\":\"After initial definition, use the concept without re-explaining\",\"priority\":\"medium\"}")
    
    # Strategy 3: Link to documentation
    strategies+=("{\"type\":\"documentation_link\",\"action\":\"Replace inline explanations with links to detailed documentation\",\"priority\":\"medium\"}")
    
    # Strategy 4: Use consistent terminology
    strategies+=("{\"type\":\"terminology\",\"action\":\"Use consistent terms throughout without re-defining\",\"priority\":\"low\"}")
    
    echo "[${strategies[*]}]"
}

# Function to analyze implicit vs explicit strategies
analyze_documentation_strategy() {
    local file="$1"
    local concept_density="$2"
    
    # Determine if file should use implicit or explicit documentation
    local file_type="unknown"
    case "$file" in
        *.md|README*|DESIGN*)
            file_type="documentation"
            ;;
        *.sh|*.py|*.js|*.ts)
            file_type="code"
            ;;
        *.json|*.yaml|*.yml)
            file_type="configuration"
            ;;
    esac
    
    # Analyze appropriate strategy
    local strategy="balanced"
    local reasoning=""
    
    if [ "$file_type" = "documentation" ]; then
        strategy="explicit"
        reasoning="Documentation files should explicitly define concepts"
    elif [ "$file_type" = "code" ]; then
        # Check if density is high
        local high_density_count=$(echo "$concept_density" | grep -c "\"status\":\"over\"" || echo "0")
        if [ "$high_density_count" -gt 2 ]; then
            strategy="implicit"
            reasoning="Code with high concept density should use implicit references"
        else
            strategy="balanced"
            reasoning="Code should balance clarity with conciseness"
        fi
    elif [ "$file_type" = "configuration" ]; then
        strategy="implicit"
        reasoning="Configuration files should minimize explanatory text"
    fi
    
    echo "{\"file\":\"$file\",\"file_type\":\"$file_type\",\"recommended_strategy\":\"$strategy\",\"reasoning\":\"$reasoning\"}"
}

# Main execution
main() {
    local target="${1:-.}"
    
    # First, run concept density analysis
    local density_output=$("$SCRIPT_DIR/concept-density.sh" "$target" 2>/dev/null || echo "{}")
    
    # Extract analysis data
    local analysis=$(echo "$density_output" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    for item in data.get('analysis', []):
        print(json.dumps(item))
except:
    pass
" 2>/dev/null || echo "")
    
    if [ -z "$analysis" ]; then
        echo "{\"error\":\"No density analysis available\"}"
        return
    fi
    
    # Output consolidation suggestions
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"timestamp\":\"$timestamp\",\"consolidation_suggestions\":["
    
    local first=true
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local file=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['file'])" 2>/dev/null || echo "")
            if [ -n "$file" ] && [ -f "$file" ]; then
                local suggestion=$(analyze_consolidation "$file" "$line")
                if [ -n "$suggestion" ]; then
                    if [ "$first" = false ]; then
                        echo ","
                    fi
                    echo -n "$suggestion"
                    first=false
                fi
            fi
        fi
    done <<< "$analysis"
    
    echo "],"
    
    # Add documentation strategy recommendations
    echo "\"documentation_strategies\":["
    
    first=true
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local file=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['file'])" 2>/dev/null || echo "")
            if [ -n "$file" ] && [ -f "$file" ]; then
                if [ "$first" = false ]; then
                    echo ","
                fi
                analyze_documentation_strategy "$file" "$line"
                first=false
            fi
        fi
    done <<< "$analysis"
    
    echo "],"
    
    # Add general recommendations
    echo "\"general_recommendations\":["
    echo "{\"type\":\"central_definitions\",\"action\":\"Create a central glossary or concepts document\",\"benefit\":\"Reduces repetition across files\"},"
    echo "{\"type\":\"reference_patterns\",\"action\":\"Use 'See [concept] in [file]' patterns\",\"benefit\":\"Maintains clarity without redundancy\"},"
    echo "{\"type\":\"progressive_disclosure\",\"action\":\"Introduce concepts once, then assume knowledge\",\"benefit\":\"Improves readability for experienced users\"}"
    echo "]}"
    
    # Log to database
    echo "{\"timestamp\":\"$timestamp\",\"suggestions_generated\":true}" >> "$CONSOLIDATION_DB"
}

# Execute main function
main "$@"