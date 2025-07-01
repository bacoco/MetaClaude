#!/bin/bash
# MetaClaude Balance Enforcement System
# Ensures concepts are adequately represented without over-emphasis

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATTERNS_FILE="$SCRIPT_DIR/concept-patterns.json"
BALANCE_DB="$SCRIPT_DIR/../../../data/balance-scores.json"

# Initialize data directory
mkdir -p "$(dirname "$BALANCE_DB")"

# Function to calculate balance score
calculate_balance_score() {
    local density="$1"
    local min_density="$2"
    local max_density="$3"
    
    # Balance score: 0 = perfectly balanced, negative = under, positive = over
    if [ "$(echo "$density < $min_density" | bc)" -eq 1 ]; then
        # Under-emphasized: calculate how far below minimum
        echo "scale=4; ($density - $min_density) / $min_density" | bc
    elif [ "$(echo "$density > $max_density" | bc)" -eq 1 ]; then
        # Over-emphasized: calculate how far above maximum
        echo "scale=4; ($density - $max_density) / $max_density" | bc
    else
        # Within range: calculate position within range (0 = perfect center)
        local center=$(echo "scale=4; ($min_density + $max_density) / 2" | bc)
        echo "scale=4; ($density - $center) / $center" | bc
    fi
}

# Function to get weight-adjusted score
get_weighted_score() {
    local concept="$1"
    local balance_score="$2"
    
    # Get concept weight
    local weight=$(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    print(data['core_concepts'].get('$concept', {}).get('weight', 1.0))
" 2>/dev/null || echo "1.0")
    
    echo "scale=4; $balance_score * $weight" | bc
}

# Function to analyze file balance
analyze_file_balance() {
    local file="$1"
    local density_data="$2"
    
    local total_score=0
    local concept_count=0
    local issues=()
    
    # Process each concept
    for concept in transparency adaptability user_centricity orchestration metacognition evolution autonomy; do
        # Extract density data for this concept
        local density=$(echo "$density_data" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data['concepts'].get('$concept', {}).get('adjusted_density', 0))
except:
    print(0)
" 2>/dev/null || echo "0")
        
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
        
        # Calculate balance score
        local balance_score=$(calculate_balance_score "$density" "$min_density" "$max_density")
        local weighted_score=$(get_weighted_score "$concept" "$balance_score")
        
        # Accumulate total
        total_score=$(echo "scale=4; $total_score + $weighted_score" | bc)
        concept_count=$((concept_count + 1))
        
        # Check for issues
        if [ "$(echo "$balance_score < -0.5" | bc)" -eq 1 ]; then
            issues+=("{\"concept\":\"$concept\",\"issue\":\"severely_under\",\"score\":$balance_score}")
        elif [ "$(echo "$balance_score > 0.5" | bc)" -eq 1 ]; then
            issues+=("{\"concept\":\"$concept\",\"issue\":\"severely_over\",\"score\":$balance_score}")
        fi
    done
    
    # Calculate average balance
    local avg_balance=$(echo "scale=4; $total_score / $concept_count" | bc)
    
    # Determine overall status
    local status="balanced"
    if [ "$(echo "$avg_balance < -0.2" | bc)" -eq 1 ]; then
        status="under_balanced"
    elif [ "$(echo "$avg_balance > 0.2" | bc)" -eq 1 ]; then
        status="over_balanced"
    fi
    
    # Output results
    echo -n "{\"file\":\"$file\",\"average_balance\":$avg_balance,\"status\":\"$status\""
    if [ ${#issues[@]} -gt 0 ]; then
        echo -n ",\"issues\":[$(IFS=,; echo "${issues[*]}")]"
    fi
    echo "}"
}

# Function to generate balance recommendations
generate_balance_recommendations() {
    local balance_data="$1"
    
    local recommendations=()
    
    # Process each file's balance data
    while IFS= read -r line; do
        local file=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['file'])" 2>/dev/null || echo "")
        local status=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['status'])" 2>/dev/null || echo "")
        
        if [ "$status" = "under_balanced" ]; then
            recommendations+=("{\"file\":\"$file\",\"action\":\"increase_emphasis\",\"suggestion\":\"Add more context and examples for under-represented concepts\"}")
        elif [ "$status" = "over_balanced" ]; then
            recommendations+=("{\"file\":\"$file\",\"action\":\"reduce_emphasis\",\"suggestion\":\"Consolidate or reference existing definitions for over-represented concepts\"}")
        fi
        
        # Check for specific concept issues
        local issues=$(echo "$line" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    for issue in data.get('issues', []):
        print(json.dumps(issue))
except:
    pass
" 2>/dev/null || echo "")
        
        while IFS= read -r issue; do
            if [ -n "$issue" ]; then
                local concept=$(echo "$issue" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['concept'])" 2>/dev/null || echo "")
                local issue_type=$(echo "$issue" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['issue'])" 2>/dev/null || echo "")
                
                if [ "$issue_type" = "severely_under" ]; then
                    recommendations+=("{\"file\":\"$file\",\"concept\":\"$concept\",\"action\":\"urgent_increase\",\"suggestion\":\"Concept '$concept' is severely under-represented and needs immediate attention\"}")
                elif [ "$issue_type" = "severely_over" ]; then
                    recommendations+=("{\"file\":\"$file\",\"concept\":\"$concept\",\"action\":\"urgent_reduce\",\"suggestion\":\"Concept '$concept' is over-emphasized and should be consolidated\"}")
                fi
            fi
        done <<< "$issues"
    done <<< "$balance_data"
    
    # Output recommendations
    echo "[$(IFS=,; echo "${recommendations[*]}")]"
}

# Function to calculate project-wide balance
calculate_project_balance() {
    local all_balances="$1"
    
    # Calculate aggregate statistics
    local total_files=0
    local balanced_files=0
    local under_balanced=0
    local over_balanced=0
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            total_files=$((total_files + 1))
            local status=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['status'])" 2>/dev/null || echo "")
            
            case "$status" in
                "balanced")
                    balanced_files=$((balanced_files + 1))
                    ;;
                "under_balanced")
                    under_balanced=$((under_balanced + 1))
                    ;;
                "over_balanced")
                    over_balanced=$((over_balanced + 1))
                    ;;
            esac
        fi
    done <<< "$all_balances"
    
    # Calculate percentages
    local balanced_pct=0
    if [ $total_files -gt 0 ]; then
        balanced_pct=$(echo "scale=2; ($balanced_files * 100) / $total_files" | bc)
    fi
    
    # Determine project health
    local health="good"
    if [ "$(echo "$balanced_pct < 50" | bc)" -eq 1 ]; then
        health="poor"
    elif [ "$(echo "$balanced_pct < 75" | bc)" -eq 1 ]; then
        health="fair"
    fi
    
    echo "{\"total_files\":$total_files,\"balanced\":$balanced_files,\"under_balanced\":$under_balanced,\"over_balanced\":$over_balanced,\"balance_percentage\":$balanced_pct,\"health\":\"$health\"}"
}

# Main execution
main() {
    local target="${1:-.}"
    
    # Run concept density analysis first
    local density_output=$("$SCRIPT_DIR/concept-density.sh" "$target" 2>/dev/null || echo "{}")
    
    # Extract density analysis
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
    
    # Analyze balance for each file
    local all_balances=""
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "{\"timestamp\":\"$timestamp\",\"balance_analysis\":["
    
    local first=true
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local file=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['file'])" 2>/dev/null || echo "")
            if [ -n "$file" ]; then
                local balance=$(analyze_file_balance "$file" "$line")
                if [ -n "$balance" ]; then
                    if [ "$first" = false ]; then
                        echo ","
                    fi
                    echo -n "$balance"
                    all_balances="$all_balances$balance\n"
                    first=false
                fi
            fi
        fi
    done <<< "$analysis"
    
    echo "],"
    
    # Generate recommendations
    echo "\"recommendations\":"
    generate_balance_recommendations "$all_balances"
    echo ","
    
    # Calculate project-wide balance
    echo "\"project_balance\":"
    calculate_project_balance "$all_balances"
    
    echo "}"
    
    # Store results
    echo "{\"timestamp\":\"$timestamp\",\"balance_checked\":true}" >> "$BALANCE_DB"
}

# Execute main function
main "$@"