#!/bin/bash
#
# Abstract Patterns Hook - Converts domain-specific patterns to universal ones
# Part of MetaClaude Phase 5: Cross-Domain Learning
#

set -euo pipefail

# Source MetaClaude utilities
source "$(dirname "$0")/../../utils/metaclaude-utils.sh"

# Configuration
PATTERNS_DIR="${CLAUDE_HOME:-.claude}/patterns"
EXTRACTED_DIR="$PATTERNS_DIR/extracted"
UNIVERSAL_DIR="$PATTERNS_DIR/universal"
ABSTRACTION_LOG="${CLAUDE_HOME:-.claude}/logs/pattern-abstraction.log"
ABSTRACTION_RULES="${CLAUDE_HOME:-.claude}/config/abstraction-rules.json"

# Initialize directories
mkdir -p "$UNIVERSAL_DIR" "$(dirname "$ABSTRACTION_LOG")"

# Function to log abstraction events
log_abstraction() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$ABSTRACTION_LOG"
}

# Function to load abstraction rules
load_abstraction_rules() {
    if [ -f "$ABSTRACTION_RULES" ]; then
        cat "$ABSTRACTION_RULES"
    else
        # Default abstraction rules
        cat <<'EOF'
{
    "domain_mappings": {
        "file_system": ["path", "directory", "file"],
        "network": ["endpoint", "connection", "protocol"],
        "database": ["table", "query", "transaction"],
        "ui": ["component", "element", "interaction"],
        "api": ["request", "response", "authentication"]
    },
    "concept_generalizations": {
        "resource": ["file", "database_record", "api_endpoint", "ui_component"],
        "container": ["directory", "database", "service", "layout"],
        "operation": ["read", "write", "update", "delete", "transform"],
        "flow": ["sequential", "parallel", "conditional", "iterative"],
        "validation": ["input_check", "type_check", "constraint_check", "business_rule"]
    },
    "abstraction_levels": {
        "implementation": 1,
        "tactical": 2,
        "strategic": 3,
        "architectural": 4,
        "conceptual": 5
    }
}
EOF
    fi
}

# Function to identify domain concepts
identify_domain_concepts() {
    local pattern_data="$1"
    local rules="$2"
    
    # Extract text content from pattern
    local content=$(echo "$pattern_data" | jq -r 'to_entries | map(.value) | @json')
    
    # Find domain-specific terms
    local domains=()
    while IFS= read -r domain; do
        local terms=$(echo "$rules" | jq -r ".domain_mappings.$domain[]")
        while IFS= read -r term; do
            if echo "$content" | grep -qi "$term"; then
                domains+=("$domain")
                break
            fi
        done <<< "$terms"
    done < <(echo "$rules" | jq -r '.domain_mappings | keys[]')
    
    printf '%s\n' "${domains[@]}" | sort -u | jq -R . | jq -s .
}

# Function to abstract implementation details
abstract_implementation() {
    local pattern_data="$1"
    local abstraction_level="$2"
    
    case "$abstraction_level" in
        "tactical")
            # Remove specific values, keep structure
            echo "$pattern_data" | jq '
                walk(
                    if type == "object" then
                        with_entries(
                            if .key | test("value|data|content") then
                                .value = "<abstracted>"
                            else
                                .
                            end
                        )
                    elif type == "string" and (. | test("^/|^http:|^https:|@|\\$")) then
                        "<abstracted_reference>"
                    else
                        .
                    end
                )
            '
            ;;
        "strategic")
            # Keep only high-level structure
            echo "$pattern_data" | jq '
                {
                    pattern_type: .pattern_type,
                    structure: (
                        if .implementation.steps then
                            { steps: [.implementation.steps[] | {action: .action, purpose: .purpose}] }
                        elif .structure.stages then
                            { stages: [.structure.stages[] | {type: .type, dependencies: .dependencies}] }
                        else
                            {}
                        end
                    ),
                    context: {
                        preconditions: (.context.preconditions // [] | length),
                        postconditions: (.context.postconditions // [] | length),
                        constraints: (.context.constraints // [] | length)
                    }
                }
            '
            ;;
        "architectural")
            # Extract only architectural patterns
            echo "$pattern_data" | jq '
                {
                    pattern_type: .pattern_type,
                    components: (
                        [.. | objects | select(has("type") or has("action") or has("stage")) | .type // .action // "component"] | unique
                    ),
                    relationships: (
                        [.. | objects | select(has("dependencies") or has("transitions")) | keys] | add // [] | unique
                    ),
                    qualities: (
                        [.. | objects | keys[] | select(. | test("constraint|validation|error|retry|fallback"))] | unique
                    )
                }
            '
            ;;
        "conceptual")
            # Pure conceptual abstraction
            echo "$pattern_data" | jq '
                {
                    concept: (.pattern_type + "_pattern"),
                    category: (
                        if .pattern_type == "workflow" then "process"
                        elif .pattern_type == "strategy" then "approach"
                        elif .pattern_type == "optimization" then "improvement"
                        else "pattern"
                        end
                    ),
                    characteristics: [
                        if (.structure.parallelism // "sequential") != "sequential" then "concurrent" else empty end,
                        if .error_handling then "resilient" else empty end,
                        if .optimization then "performance-focused" else empty end,
                        if (.context.constraints // [] | length) > 0 then "constrained" else empty end
                    ]
                }
            '
            ;;
        *)
            echo "$pattern_data"
            ;;
    esac
}

# Function to generalize concepts
generalize_concepts() {
    local pattern_data="$1"
    local rules="$2"
    
    # Get concept generalizations
    local generalizations=$(echo "$rules" | jq -r '.concept_generalizations')
    
    # Apply generalizations
    echo "$pattern_data" | jq --argjson gen "$generalizations" '
        walk(
            if type == "string" then
                . as $str |
                ($gen | to_entries | map(
                    select(.value[] | test($str; "i")) | .key
                ) | first) // $str
            else
                .
            end
        )
    '
}

# Function to extract universal principles
extract_universal_principles() {
    local pattern_data="$1"
    
    local principles=()
    
    # Check for common patterns
    if echo "$pattern_data" | jq -e '.implementation.steps[] | select(.conditions)' > /dev/null 2>&1; then
        principles+=("conditional_execution")
    fi
    
    if echo "$pattern_data" | jq -e '.structure.parallelism == "parallel"' > /dev/null 2>&1; then
        principles+=("parallel_processing")
    fi
    
    if echo "$pattern_data" | jq -e '.error_handling.retry_policy' > /dev/null 2>&1; then
        principles+=("fault_tolerance")
    fi
    
    if echo "$pattern_data" | jq -e '.optimization' > /dev/null 2>&1; then
        principles+=("performance_optimization")
    fi
    
    if echo "$pattern_data" | jq -e '.implementation.fallback_strategies[] // .error_handling.compensation[]' > /dev/null 2>&1; then
        principles+=("graceful_degradation")
    fi
    
    printf '%s\n' "${principles[@]}" | jq -R . | jq -s .
}

# Function to create universal pattern
create_universal_pattern() {
    local source_pattern="$1"
    local abstraction_level="$2"
    local domains="$3"
    local principles="$4"
    
    local pattern_id="universal_$(echo "$source_pattern" | jq -r '.pattern_id')_$(date +%s)"
    
    # Abstract the pattern
    local abstracted=$(abstract_implementation "$source_pattern" "$abstraction_level")
    
    # Create universal pattern
    local universal_pattern=$(cat <<EOF
{
    "pattern_id": "$pattern_id",
    "pattern_type": "universal",
    "source_pattern": "$(echo "$source_pattern" | jq -r '.pattern_id')",
    "abstraction_level": "$abstraction_level",
    "name": "$(echo "$source_pattern" | jq -r '.name' | sed 's/[^a-zA-Z0-9 ]//g' | tr '[:lower:]' '[:upper:]' | head -c 50)",
    "description": "Universal pattern abstracted from $(echo "$source_pattern" | jq -r '.pattern_type') implementation",
    "domains": $domains,
    "principles": $principles,
    "structure": $(echo "$abstracted" | jq '.structure // {}'),
    "applicability": {
        "contexts": $(determine_applicable_contexts "$abstracted" "$principles"),
        "constraints": $(extract_universal_constraints "$abstracted"),
        "benefits": $(identify_pattern_benefits "$principles")
    },
    "variations": [],
    "metadata": {
        "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "abstraction_method": "rule_based",
        "confidence": $(calculate_abstraction_confidence "$domains" "$principles"),
        "usage_count": 0,
        "success_rate": null
    }
}
EOF
)
    
    echo "$universal_pattern"
}

# Function to determine applicable contexts
determine_applicable_contexts() {
    local abstracted="$1"
    local principles="$2"
    
    local contexts=()
    
    # Map principles to contexts
    if echo "$principles" | grep -q "parallel_processing"; then
        contexts+=("high_throughput_scenarios")
        contexts+=("independent_task_processing")
    fi
    
    if echo "$principles" | grep -q "fault_tolerance"; then
        contexts+=("unreliable_environments")
        contexts+=("critical_operations")
    fi
    
    if echo "$principles" | grep -q "conditional_execution"; then
        contexts+=("complex_decision_flows")
        contexts+=("adaptive_behaviors")
    fi
    
    printf '%s\n' "${contexts[@]}" | jq -R . | jq -s .
}

# Function to extract universal constraints
extract_universal_constraints() {
    local abstracted="$1"
    
    echo "$abstracted" | jq '
        [
            if .context.preconditions > 0 then
                "requires_preconditions"
            else empty end,
            if .context.constraints > 0 then
                "has_operational_constraints"
            else empty end,
            if .structure.steps then
                "sequential_dependencies"
            else empty end
        ]
    '
}

# Function to identify pattern benefits
identify_pattern_benefits() {
    local principles="$1"
    
    local benefits=()
    
    while IFS= read -r principle; do
        case "$principle" in
            "parallel_processing")
                benefits+=("improved_throughput")
                benefits+=("reduced_latency")
                ;;
            "fault_tolerance")
                benefits+=("increased_reliability")
                benefits+=("error_recovery")
                ;;
            "performance_optimization")
                benefits+=("resource_efficiency")
                benefits+=("faster_execution")
                ;;
            "graceful_degradation")
                benefits+=("system_resilience")
                benefits+=("user_experience_preservation")
                ;;
        esac
    done < <(echo "$principles" | jq -r '.[]')
    
    printf '%s\n' "${benefits[@]}" | jq -R . | jq -s .
}

# Function to calculate abstraction confidence
calculate_abstraction_confidence() {
    local domains="$1"
    local principles="$2"
    
    local domain_count=$(echo "$domains" | jq 'length')
    local principle_count=$(echo "$principles" | jq 'length')
    
    # Base confidence on diversity and principle count
    local confidence=$(awk -v d="$domain_count" -v p="$principle_count" '
        BEGIN {
            domain_score = d > 0 ? (d > 3 ? 1.0 : d / 3.0) : 0.5
            principle_score = p > 0 ? (p > 5 ? 1.0 : p / 5.0) : 0.3
            confidence = domain_score * 0.4 + principle_score * 0.6
            printf "%.2f", confidence
        }
    ')
    
    echo "$confidence"
}

# Function to merge similar patterns
merge_similar_patterns() {
    local pattern1="$1"
    local pattern2="$2"
    
    # Check similarity
    local similarity=$(calculate_pattern_similarity "$pattern1" "$pattern2")
    
    if (( $(echo "$similarity > 0.8" | bc -l) )); then
        # Merge patterns
        local merged_id="universal_merged_$(date +%s)_$$"
        
        cat <<EOF
{
    "pattern_id": "$merged_id",
    "pattern_type": "universal",
    "source_patterns": [
        "$(echo "$pattern1" | jq -r '.pattern_id')",
        "$(echo "$pattern2" | jq -r '.pattern_id')"
    ],
    "name": "$(echo "$pattern1" | jq -r '.name') (Merged)",
    "domains": $(echo "$pattern1 $pattern2" | jq -s 'map(.domains[]) | unique'),
    "principles": $(echo "$pattern1 $pattern2" | jq -s 'map(.principles[]) | unique'),
    "variations": [
        $(echo "$pattern1" | jq '{source: .source_pattern, specifics: .structure}'),
        $(echo "$pattern2" | jq '{source: .source_pattern, specifics: .structure}')
    ]
}
EOF
    else
        echo ""
    fi
}

# Function to calculate pattern similarity
calculate_pattern_similarity() {
    local pattern1="$1"
    local pattern2="$2"
    
    # Compare principles
    local principles1=$(echo "$pattern1" | jq -r '.principles[]' | sort)
    local principles2=$(echo "$pattern2" | jq -r '.principles[]' | sort)
    local common=$(comm -12 <(echo "$principles1") <(echo "$principles2") | wc -l)
    local total=$(echo "$principles1 $principles2" | tr ' ' '\n' | sort -u | wc -l)
    
    if [ "$total" -eq 0 ]; then
        echo "0"
    else
        awk -v c="$common" -v t="$total" 'BEGIN { print c / t }'
    fi
}

# Main abstraction logic
main() {
    local input_pattern="${1:-}"
    
    log_abstraction "INFO" "Starting pattern abstraction process"
    
    # Load abstraction rules
    local rules=$(load_abstraction_rules)
    
    if [ -n "$input_pattern" ] && [ -f "$input_pattern" ]; then
        # Process single pattern
        local pattern_data=$(cat "$input_pattern")
        process_pattern "$pattern_data" "$rules"
    else
        # Process all new extracted patterns
        find "$EXTRACTED_DIR" -name "*.json" -newer "$UNIVERSAL_DIR/.last_abstraction" 2>/dev/null \
            -o -name "*.json" ! -path "$UNIVERSAL_DIR/*" | while read -r pattern_file; do
            
            local pattern_data=$(cat "$pattern_file")
            process_pattern "$pattern_data" "$rules"
        done
        
        # Update timestamp
        touch "$UNIVERSAL_DIR/.last_abstraction"
    fi
    
    # Check for pattern merging opportunities
    merge_similar_universal_patterns
    
    log_abstraction "INFO" "Pattern abstraction complete"
}

# Function to process individual pattern
process_pattern() {
    local pattern_data="$1"
    local rules="$2"
    
    local pattern_id=$(echo "$pattern_data" | jq -r '.pattern_id')
    log_abstraction "INFO" "Processing pattern: $pattern_id"
    
    # Identify domains
    local domains=$(identify_domain_concepts "$pattern_data" "$rules")
    
    # Extract principles
    local principles=$(extract_universal_principles "$pattern_data")
    
    # Create abstractions at different levels
    for level in "tactical" "strategic" "architectural" "conceptual"; do
        local universal=$(create_universal_pattern "$pattern_data" "$level" "$domains" "$principles")
        
        if [ -n "$universal" ]; then
            local universal_id=$(echo "$universal" | jq -r '.pattern_id')
            echo "$universal" | jq '.' > "$UNIVERSAL_DIR/${universal_id}_${level}.json"
            log_abstraction "INFO" "Created $level abstraction: $universal_id"
        fi
    done
}

# Function to merge similar universal patterns
merge_similar_universal_patterns() {
    local merged_count=0
    
    # Find all universal patterns
    local patterns=($(find "$UNIVERSAL_DIR" -name "universal_*.json" -type f))
    
    for ((i=0; i<${#patterns[@]}; i++)); do
        for ((j=i+1; j<${#patterns[@]}; j++)); do
            local pattern1=$(cat "${patterns[i]}")
            local pattern2=$(cat "${patterns[j]}")
            
            local merged=$(merge_similar_patterns "$pattern1" "$pattern2")
            
            if [ -n "$merged" ]; then
                local merged_id=$(echo "$merged" | jq -r '.pattern_id')
                echo "$merged" | jq '.' > "$UNIVERSAL_DIR/${merged_id}.json"
                merged_count=$((merged_count + 1))
                log_abstraction "INFO" "Merged similar patterns into: $merged_id"
            fi
        done
    done
    
    if [ "$merged_count" -gt 0 ]; then
        log_abstraction "INFO" "Merged $merged_count pattern pairs"
    fi
}

# Execute main function
main "$@"