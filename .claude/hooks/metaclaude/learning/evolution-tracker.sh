#!/bin/bash
#
# Evolution Tracker Hook - Tracks pattern evolution and lineage over time
# Part of MetaClaude Phase 5: Cross-Domain Learning
#

set -euo pipefail

# Source MetaClaude utilities
source "$(dirname "$0")/../../utils/metaclaude-utils.sh"

# Configuration
PATTERNS_DIR="${CLAUDE_HOME:-.claude}/patterns"
EVOLUTION_DIR="${CLAUDE_HOME:-.claude}/learning/evolution"
LINEAGE_DIR="$EVOLUTION_DIR/lineage"
EMERGENCE_DIR="$EVOLUTION_DIR/emergence"
HISTORY_DIR="$EVOLUTION_DIR/history"
EVOLUTION_LOG="${CLAUDE_HOME:-.claude}/logs/pattern-evolution.log"
EVOLUTION_DB="$EVOLUTION_DIR/evolution-database.json"

# Initialize directories
mkdir -p "$LINEAGE_DIR" "$EMERGENCE_DIR" "$HISTORY_DIR" "$(dirname "$EVOLUTION_LOG")"

# Function to log evolution events
log_evolution() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$EVOLUTION_LOG"
}

# Function to track pattern modifications
track_pattern_modification() {
    local pattern_id="$1"
    local old_version="$2"
    local new_version="$3"
    local modification_type="$4"
    local reason="$5"
    
    local modification_id="mod_${pattern_id}_$(date +%s)"
    
    # Analyze changes
    local changes=$(analyze_pattern_changes "$old_version" "$new_version")
    
    # Create modification record
    local modification=$(cat <<EOF
{
    "modification_id": "$modification_id",
    "pattern_id": "$pattern_id",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "modification_type": "$modification_type",
    "reason": "$reason",
    "changes": $changes,
    "version_transition": {
        "from_version": "$(echo "$old_version" | jq -r '.metadata.version // "1.0.0"')",
        "to_version": "$(generate_new_version "$old_version" "$modification_type")"
    },
    "impact_analysis": $(analyze_modification_impact "$pattern_id" "$changes")
}
EOF
)
    
    # Save to history
    echo "$modification" | jq '.' > "$HISTORY_DIR/$modification_id.json"
    
    # Update lineage
    update_pattern_lineage "$pattern_id" "$modification"
    
    log_evolution "INFO" "Tracked modification for pattern $pattern_id: $modification_type"
    
    echo "$modification_id"
}

# Function to analyze pattern changes
analyze_pattern_changes() {
    local old_version="$1"
    local new_version="$2"
    
    # Compare structures
    local structural_changes=$(jq -n --argjson old "$old_version" --argjson new "$new_version" '
        {
            added_fields: ($new | keys) - ($old | keys),
            removed_fields: ($old | keys) - ($new | keys),
            modified_fields: [
                ($old | keys) as $old_keys |
                ($new | keys) as $new_keys |
                ($old_keys - ($old_keys - $new_keys))[] |
                select($old[.] != $new[.])
            ]
        }
    ')
    
    # Compare principles
    local principle_changes=$(jq -n --argjson old "$old_version" --argjson new "$new_version" '
        {
            added_principles: ($new.principles // []) - ($old.principles // []),
            removed_principles: ($old.principles // []) - ($new.principles // []),
            unchanged_principles: (($old.principles // []) - (($old.principles // []) - ($new.principles // [])))
        }
    ')
    
    # Compare domains
    local domain_changes=$(jq -n --argjson old "$old_version" --argjson new "$new_version" '
        {
            added_domains: ($new.domains // []) - ($old.domains // []),
            removed_domains: ($old.domains // []) - ($new.domains // []),
            domain_expansion: (($new.domains // []) | length) > (($old.domains // []) | length)
        }
    ')
    
    # Analyze semantic changes
    local semantic_changes=$(analyze_semantic_changes "$old_version" "$new_version")
    
    cat <<EOF
{
    "structural": $structural_changes,
    "principles": $principle_changes,
    "domains": $domain_changes,
    "semantic": $semantic_changes,
    "change_magnitude": $(calculate_change_magnitude "$structural_changes" "$principle_changes" "$domain_changes")
}
EOF
}

# Function to analyze semantic changes
analyze_semantic_changes() {
    local old_version="$1"
    local new_version="$2"
    
    # Detect changes in pattern intent
    local old_desc=$(echo "$old_version" | jq -r '.description // ""' | tr '[:upper:]' '[:lower:]')
    local new_desc=$(echo "$new_version" | jq -r '.description // ""' | tr '[:upper:]' '[:lower:]')
    
    local intent_changed="false"
    if [ "$old_desc" != "$new_desc" ]; then
        # Simple keyword analysis for intent change
        local old_keywords=$(echo "$old_desc" | grep -oE '\b(process|transform|validate|optimize|manage|control)\b' | sort -u)
        local new_keywords=$(echo "$new_desc" | grep -oE '\b(process|transform|validate|optimize|manage|control)\b' | sort -u)
        
        if [ "$old_keywords" != "$new_keywords" ]; then
            intent_changed="true"
        fi
    fi
    
    cat <<EOF
{
    "intent_changed": $intent_changed,
    "complexity_change": $(compare_complexity "$old_version" "$new_version"),
    "scope_change": $(compare_scope "$old_version" "$new_version")
}
EOF
}

# Function to compare pattern complexity
compare_complexity() {
    local old_version="$1"
    local new_version="$2"
    
    # Calculate complexity metrics
    local old_steps=$(echo "$old_version" | jq '.implementation.steps // [] | length')
    local new_steps=$(echo "$new_version" | jq '.implementation.steps // [] | length')
    
    local old_conditions=$(echo "$old_version" | jq '[.. | objects | select(has("conditions"))] | length')
    local new_conditions=$(echo "$new_version" | jq '[.. | objects | select(has("conditions"))] | length')
    
    local complexity_delta=$(awk -v os="$old_steps" -v ns="$new_steps" -v oc="$old_conditions" -v nc="$new_conditions" '
        BEGIN {
            old_complexity = os + oc * 2
            new_complexity = ns + nc * 2
            if (old_complexity > 0) {
                delta = (new_complexity - old_complexity) / old_complexity
            } else {
                delta = new_complexity > 0 ? 1.0 : 0
            }
            print delta
        }
    ')
    
    echo "$complexity_delta"
}

# Function to compare pattern scope
compare_scope() {
    local old_version="$1"
    local new_version="$2"
    
    local old_domains=$(echo "$old_version" | jq '.domains // [] | length')
    local new_domains=$(echo "$new_version" | jq '.domains // [] | length')
    
    local old_contexts=$(echo "$old_version" | jq '.applicability.contexts // [] | length')
    local new_contexts=$(echo "$new_version" | jq '.applicability.contexts // [] | length')
    
    if [ "$new_domains" -gt "$old_domains" ] || [ "$new_contexts" -gt "$old_contexts" ]; then
        echo "\"expanded\""
    elif [ "$new_domains" -lt "$old_domains" ] || [ "$new_contexts" -lt "$old_contexts" ]; then
        echo "\"narrowed\""
    else
        echo "\"unchanged\""
    fi
}

# Function to calculate change magnitude
calculate_change_magnitude() {
    local structural="$1"
    local principles="$2"
    local domains="$3"
    
    # Count changes
    local struct_count=$(echo "$structural" | jq '
        (.added_fields | length) + 
        (.removed_fields | length) + 
        (.modified_fields | length)
    ')
    
    local principle_count=$(echo "$principles" | jq '
        (.added_principles | length) + 
        (.removed_principles | length)
    ')
    
    local domain_count=$(echo "$domains" | jq '
        (.added_domains | length) + 
        (.removed_domains | length)
    ')
    
    # Calculate magnitude
    local magnitude=$(awk -v s="$struct_count" -v p="$principle_count" -v d="$domain_count" '
        BEGIN {
            total = s * 0.4 + p * 0.4 + d * 0.2
            if (total > 10) print "major"
            else if (total > 5) print "moderate"
            else if (total > 0) print "minor"
            else print "none"
        }
    ')
    
    echo "\"$magnitude\""
}

# Function to generate new version number
generate_new_version() {
    local old_version="$1"
    local modification_type="$2"
    
    local current_version=$(echo "$old_version" | jq -r '.metadata.version // "1.0.0"')
    
    # Parse version
    local major=$(echo "$current_version" | cut -d. -f1)
    local minor=$(echo "$current_version" | cut -d. -f2)
    local patch=$(echo "$current_version" | cut -d. -f3)
    
    case "$modification_type" in
        "major_revision"|"breaking_change")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "feature_addition"|"expansion")
            minor=$((minor + 1))
            patch=0
            ;;
        *)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Function to analyze modification impact
analyze_modification_impact() {
    local pattern_id="$1"
    local changes="$2"
    
    # Check dependent patterns
    local dependent_patterns=$(find_dependent_patterns "$pattern_id")
    local dependent_count=$(echo "$dependent_patterns" | jq 'length')
    
    # Assess impact level
    local change_magnitude=$(echo "$changes" | jq -r '.change_magnitude')
    local impact_level="low"
    
    if [ "$change_magnitude" = "major" ] && [ "$dependent_count" -gt 5 ]; then
        impact_level="high"
    elif [ "$change_magnitude" = "moderate" ] || [ "$dependent_count" -gt 2 ]; then
        impact_level="medium"
    fi
    
    cat <<EOF
{
    "impact_level": "$impact_level",
    "affected_patterns": $dependent_count,
    "change_magnitude": $change_magnitude,
    "requires_propagation": $([ "$impact_level" != "low" ] && echo "true" || echo "false"),
    "recommended_actions": $(recommend_evolution_actions "$impact_level" "$change_magnitude")
}
EOF
}

# Function to find dependent patterns
find_dependent_patterns() {
    local pattern_id="$1"
    
    # Search for patterns that reference this pattern
    local dependents=()
    
    if [ -d "$PATTERNS_DIR" ]; then
        while IFS= read -r pattern_file; do
            if grep -q "$pattern_id" "$pattern_file" 2>/dev/null; then
                local dep_id=$(jq -r '.pattern_id // ""' "$pattern_file")
                [ -n "$dep_id" ] && [ "$dep_id" != "$pattern_id" ] && dependents+=("\"$dep_id\"")
            fi
        done < <(find "$PATTERNS_DIR" -name "*.json" -type f)
    fi
    
    printf '%s\n' "${dependents[@]}" | jq -s '.'
}

# Function to recommend evolution actions
recommend_evolution_actions() {
    local impact_level="$1"
    local change_magnitude="$2"
    
    local actions=()
    
    case "$impact_level" in
        "high")
            actions+=("\"notify_all_implementations\"")
            actions+=("\"create_migration_guide\"")
            actions+=("\"test_dependent_patterns\"")
            ;;
        "medium")
            actions+=("\"update_documentation\"")
            actions+=("\"notify_active_users\"")
            ;;
        "low")
            actions+=("\"log_change\"")
            ;;
    esac
    
    if [ "$change_magnitude" = "major" ]; then
        actions+=("\"create_compatibility_layer\"")
    fi
    
    printf '%s\n' "${actions[@]}" | jq -s '.'
}

# Function to update pattern lineage
update_pattern_lineage() {
    local pattern_id="$1"
    local modification="$2"
    
    local lineage_file="$LINEAGE_DIR/${pattern_id}_lineage.json"
    
    # Load or create lineage
    local lineage="{}"
    if [ -f "$lineage_file" ]; then
        lineage=$(cat "$lineage_file")
    else
        lineage=$(cat <<EOF
{
    "pattern_id": "$pattern_id",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "origin": "unknown",
    "evolution_history": [],
    "current_version": "1.0.0",
    "total_modifications": 0
}
EOF
)
    fi
    
    # Update lineage
    lineage=$(echo "$lineage" | jq --argjson mod "$modification" '
        .evolution_history += [$mod] |
        .current_version = $mod.version_transition.to_version |
        .total_modifications += 1 |
        .last_modified = $mod.timestamp
    ')
    
    # Save updated lineage
    echo "$lineage" | jq '.' > "$lineage_file"
}

# Function to detect emerging patterns
detect_emerging_patterns() {
    # Analyze recent pattern creations and modifications
    local emergence_window="${1:-7}"  # Days to look back
    
    local recent_patterns=()
    local pattern_clusters=()
    
    # Find recently created patterns
    if [ -d "$PATTERNS_DIR" ]; then
        while IFS= read -r pattern_file; do
            local pattern=$(cat "$pattern_file")
            local pattern_id=$(echo "$pattern" | jq -r '.pattern_id // ""')
            
            recent_patterns+=("$pattern")
        done < <(find "$PATTERNS_DIR" -name "*.json" -type f -mtime -"$emergence_window")
    fi
    
    # Cluster patterns by similarity
    if [ ${#recent_patterns[@]} -gt 0 ]; then
        pattern_clusters=$(cluster_patterns_by_similarity "${recent_patterns[@]}")
    fi
    
    # Identify emerging trends
    local emerging_trends=$(identify_emerging_trends "$pattern_clusters")
    
    # Save emergence analysis
    local emergence_id="emergence_$(date +%s)"
    cat <<EOF > "$EMERGENCE_DIR/$emergence_id.json"
{
    "emergence_id": "$emergence_id",
    "analysis_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "analysis_window_days": $emergence_window,
    "patterns_analyzed": ${#recent_patterns[@]},
    "clusters_found": $(echo "$pattern_clusters" | jq 'length'),
    "emerging_trends": $emerging_trends,
    "recommendations": $(generate_emergence_recommendations "$emerging_trends")
}
EOF
    
    log_evolution "INFO" "Detected $(echo "$emerging_trends" | jq 'length') emerging pattern trends"
    
    echo "$emerging_trends"
}

# Function to cluster patterns by similarity
cluster_patterns_by_similarity() {
    local patterns=("$@")
    
    # Simple clustering based on shared principles and domains
    local clusters="[]"
    
    for pattern in "${patterns[@]}"; do
        local pattern_id=$(echo "$pattern" | jq -r '.pattern_id')
        local principles=$(echo "$pattern" | jq '.principles // []')
        local domains=$(echo "$pattern" | jq '.domains // []')
        
        # Find matching cluster
        local matched="false"
        local cluster_idx=0
        
        while [ "$cluster_idx" -lt "$(echo "$clusters" | jq 'length')" ]; do
            local cluster=$(echo "$clusters" | jq ".[$cluster_idx]")
            local cluster_principles=$(echo "$cluster" | jq '.shared_principles')
            local cluster_domains=$(echo "$cluster" | jq '.shared_domains')
            
            # Check for overlap
            local principle_overlap=$(jq -n --argjson p1 "$principles" --argjson p2 "$cluster_principles" '
                ($p1 - ($p1 - $p2)) | length
            ')
            
            local domain_overlap=$(jq -n --argjson d1 "$domains" --argjson d2 "$cluster_domains" '
                ($d1 - ($d1 - $d2)) | length
            ')
            
            if [ "$principle_overlap" -gt 1 ] || [ "$domain_overlap" -gt 1 ]; then
                # Add to existing cluster
                clusters=$(echo "$clusters" | jq --arg idx "$cluster_idx" --arg pid "$pattern_id" --argjson p "$principles" --argjson d "$domains" '
                    .[$idx | tonumber].patterns += [$pid] |
                    .[$idx | tonumber].shared_principles = (.[$idx | tonumber].shared_principles + $p | unique) |
                    .[$idx | tonumber].shared_domains = (.[$idx | tonumber].shared_domains + $d | unique)
                ')
                matched="true"
                break
            fi
            
            cluster_idx=$((cluster_idx + 1))
        done
        
        # Create new cluster if no match
        if [ "$matched" = "false" ]; then
            clusters=$(echo "$clusters" | jq --arg pid "$pattern_id" --argjson p "$principles" --argjson d "$domains" '
                . + [{
                    cluster_id: ("cluster_" + (length | tostring)),
                    patterns: [$pid],
                    shared_principles: $p,
                    shared_domains: $d,
                    size: 1
                }]
            ')
        fi
    done
    
    # Update cluster sizes
    clusters=$(echo "$clusters" | jq 'map(. + {size: (.patterns | length)})')
    
    echo "$clusters"
}

# Function to identify emerging trends
identify_emerging_trends() {
    local clusters="$1"
    
    # Analyze clusters for trends
    local trends=$(echo "$clusters" | jq '
        map(select(.size > 2)) |
        map({
            trend_id: ("trend_" + .cluster_id),
            pattern_count: .size,
            common_principles: .shared_principles,
            common_domains: .shared_domains,
            trend_type: (
                if (.shared_principles | contains(["optimization"])) then "performance_focus"
                elif (.shared_principles | contains(["fault_tolerance", "graceful_degradation"])) then "resilience_focus"
                elif (.shared_domains | length) > 3 then "cross_domain_expansion"
                else "general_evolution"
                end
            ),
            strength: (
                if .size > 10 then "strong"
                elif .size > 5 then "moderate"
                else "emerging"
                end
            )
        })
    ')
    
    echo "$trends"
}

# Function to generate emergence recommendations
generate_emergence_recommendations() {
    local trends="$1"
    
    local recommendations=()
    
    # Analyze each trend
    while IFS= read -r trend; do
        local trend_type=$(echo "$trend" | jq -r '.trend_type')
        local strength=$(echo "$trend" | jq -r '.strength')
        
        case "$trend_type" in
            "performance_focus")
                recommendations+=("{
                    \"action\": \"develop_performance_framework\",
                    \"priority\": \"$([ "$strength" = "strong" ] && echo "high" || echo "medium")\",
                    \"description\": \"Create specialized performance optimization patterns\"
                }")
                ;;
            "resilience_focus")
                recommendations+=("{
                    \"action\": \"enhance_error_handling\",
                    \"priority\": \"high\",
                    \"description\": \"Strengthen error recovery and fault tolerance mechanisms\"
                }")
                ;;
            "cross_domain_expansion")
                recommendations+=("{
                    \"action\": \"create_universal_adapters\",
                    \"priority\": \"medium\",
                    \"description\": \"Develop domain adaptation layers for pattern portability\"
                }")
                ;;
        esac
    done < <(echo "$trends" | jq -c '.[]')
    
    printf '%s\n' "${recommendations[@]}" | jq -s '.'
}

# Function to track evolution metrics
track_evolution_metrics() {
    # Load or create evolution database
    local db="{}"
    if [ -f "$EVOLUTION_DB" ]; then
        db=$(cat "$EVOLUTION_DB")
    fi
    
    # Calculate current metrics
    local total_patterns=$(find "$PATTERNS_DIR" -name "*.json" -type f | wc -l)
    local evolved_patterns=$(find "$LINEAGE_DIR" -name "*_lineage.json" -type f | wc -l)
    local avg_evolution_rate=$(calculate_average_evolution_rate)
    local emerging_trends=$(find "$EMERGENCE_DIR" -name "*.json" -type f -mtime -30 | wc -l)
    
    # Update database
    db=$(echo "$db" | jq --arg tp "$total_patterns" --arg ep "$evolved_patterns" --arg aer "$avg_evolution_rate" --arg et "$emerging_trends" '
        .metrics = {
            timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            total_patterns: ($tp | tonumber),
            evolved_patterns: ($ep | tonumber),
            evolution_percentage: (($ep | tonumber) / ($tp | tonumber) * 100),
            average_evolution_rate: ($aer | tonumber),
            emerging_trends_30d: ($et | tonumber)
        } |
        .history = ((.history // []) + [.metrics]) |
        if (.history | length) > 365 then
            .history = .history[-365:]
        else . end
    ')
    
    # Save updated database
    echo "$db" | jq '.' > "$EVOLUTION_DB"
}

# Function to calculate average evolution rate
calculate_average_evolution_rate() {
    local total_modifications=0
    local pattern_count=0
    
    # Sum modifications across all lineages
    if [ -d "$LINEAGE_DIR" ]; then
        while IFS= read -r lineage_file; do
            local mods=$(jq -r '.total_modifications // 0' "$lineage_file")
            total_modifications=$((total_modifications + mods))
            pattern_count=$((pattern_count + 1))
        done < <(find "$LINEAGE_DIR" -name "*_lineage.json" -type f)
    fi
    
    if [ "$pattern_count" -gt 0 ]; then
        awk -v t="$total_modifications" -v p="$pattern_count" 'BEGIN { printf "%.2f", t / p }'
    else
        echo "0"
    fi
}

# Function to generate evolution report
generate_evolution_report() {
    local report_file="$EVOLUTION_DIR/evolution-report.json"
    
    # Load current metrics
    local metrics="{}"
    if [ -f "$EVOLUTION_DB" ]; then
        metrics=$(jq '.metrics // {}' "$EVOLUTION_DB")
    fi
    
    # Analyze evolution patterns
    local evolution_patterns=$(analyze_evolution_patterns)
    
    # Generate report
    cat <<EOF > "$report_file"
{
    "report_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "evolution_metrics": $metrics,
    "evolution_patterns": $evolution_patterns,
    "lineage_summary": {
        "patterns_with_lineage": $(find "$LINEAGE_DIR" -name "*_lineage.json" | wc -l),
        "average_modifications_per_pattern": $(calculate_average_evolution_rate),
        "most_evolved_patterns": $(find_most_evolved_patterns)
    },
    "emergence_summary": {
        "active_trends": $(detect_emerging_patterns 7 | jq 'length'),
        "trend_categories": $(find "$EMERGENCE_DIR" -name "*.json" -mtime -30 -exec jq -r '.emerging_trends[].trend_type' {} \; | sort -u | jq -R . | jq -s .)
    },
    "recommendations": {
        "patterns_needing_update": $(find_patterns_needing_update),
        "consolidation_opportunities": $(find_consolidation_opportunities),
        "expansion_candidates": $(find_expansion_candidates)
    }
}
EOF
}

# Function to analyze evolution patterns
analyze_evolution_patterns() {
    if [ ! -d "$HISTORY_DIR" ]; then
        echo "[]"
        return
    fi
    
    # Analyze modification types
    local mod_types=$(find "$HISTORY_DIR" -name "*.json" -type f -exec jq -r '.modification_type' {} \; | sort | uniq -c | sort -nr | jq -R 'split(" ") | {count: .[0] | ltrimstr(" ") | tonumber, type: .[1]}' | jq -s .)
    
    # Analyze reasons for evolution
    local evolution_reasons=$(find "$HISTORY_DIR" -name "*.json" -type f -exec jq -r '.reason' {} \; | sort | uniq -c | sort -nr | head -10 | jq -R 'split(" ") | {count: .[0] | ltrimstr(" ") | tonumber, reason: (.[1:] | join(" "))}' | jq -s .)
    
    cat <<EOF
{
    "modification_distribution": $mod_types,
    "top_evolution_reasons": $evolution_reasons,
    "evolution_velocity": $(calculate_evolution_velocity),
    "stability_index": $(calculate_stability_index)
}
EOF
}

# Function to calculate evolution velocity
calculate_evolution_velocity() {
    # Modifications in last 30 days vs previous 30 days
    local recent=$(find "$HISTORY_DIR" -name "*.json" -mtime -30 | wc -l)
    local previous=$(find "$HISTORY_DIR" -name "*.json" -mtime +30 -mtime -60 | wc -l)
    
    if [ "$previous" -gt 0 ]; then
        awk -v r="$recent" -v p="$previous" 'BEGIN { printf "%.2f", (r - p) / p * 100 }'
    else
        echo "0"
    fi
}

# Function to calculate stability index
calculate_stability_index() {
    # Patterns unchanged for >90 days
    local stable=$(find "$PATTERNS_DIR" -name "*.json" -mtime +90 | wc -l)
    local total=$(find "$PATTERNS_DIR" -name "*.json" | wc -l)
    
    if [ "$total" -gt 0 ]; then
        awk -v s="$stable" -v t="$total" 'BEGIN { printf "%.2f", s / t }'
    else
        echo "0"
    fi
}

# Function to find most evolved patterns
find_most_evolved_patterns() {
    if [ ! -d "$LINEAGE_DIR" ]; then
        echo "[]"
        return
    fi
    
    find "$LINEAGE_DIR" -name "*_lineage.json" -type f -exec jq '{pattern_id: .pattern_id, modifications: .total_modifications}' {} \; | jq -s 'sort_by(-.modifications) | limit(5; .[])'
}

# Function to find patterns needing update
find_patterns_needing_update() {
    # Patterns with low effectiveness but not recently modified
    local candidates=()
    
    if [ -f "${CLAUDE_HOME:-.claude}/data/pattern-metrics.json" ]; then
        while IFS= read -r pattern_id; do
            local last_mod=$(find "$HISTORY_DIR" -name "mod_${pattern_id}_*.json" -type f -printf '%T@\n' | sort -n | tail -1)
            local days_since_mod="999"
            
            if [ -n "$last_mod" ]; then
                days_since_mod=$(awk -v lm="$last_mod" -v now="$(date +%s)" 'BEGIN { print int((now - lm) / 86400) }')
            fi
            
            if [ "$days_since_mod" -gt 60 ]; then
                candidates+=("\"$pattern_id\"")
            fi
        done < <(jq -r '.patterns | to_entries[] | select(.value.effectiveness_score < 0.5) | .key' "${CLAUDE_HOME:-.claude}/data/pattern-metrics.json")
    fi
    
    printf '%s\n' "${candidates[@]}" | jq -s '.'
}

# Function to find consolidation opportunities
find_consolidation_opportunities() {
    # Patterns with high similarity that could be merged
    echo '["pattern_123_pattern_456", "pattern_789_pattern_012"]'  # Placeholder
}

# Function to find expansion candidates
find_expansion_candidates() {
    # High-performing patterns in single domain
    echo '["pattern_abc", "pattern_def"]'  # Placeholder
}

# Main evolution tracking logic
main() {
    log_evolution "INFO" "Starting evolution tracking process"
    
    # Track any pending modifications
    local pending_mods="${CLAUDE_HOME:-.claude}/evolution/pending"
    if [ -d "$pending_mods" ]; then
        while IFS= read -r mod_file; do
            local mod_data=$(cat "$mod_file")
            local pattern_id=$(echo "$mod_data" | jq -r '.pattern_id')
            local old_version=$(echo "$mod_data" | jq '.old_version')
            local new_version=$(echo "$mod_data" | jq '.new_version')
            local mod_type=$(echo "$mod_data" | jq -r '.modification_type // "update"')
            local reason=$(echo "$mod_data" | jq -r '.reason // "Manual update"')
            
            track_pattern_modification "$pattern_id" "$old_version" "$new_version" "$mod_type" "$reason"
            
            rm -f "$mod_file"
        done < <(find "$pending_mods" -name "*.json" -type f)
    fi
    
    # Detect emerging patterns
    detect_emerging_patterns
    
    # Track evolution metrics
    track_evolution_metrics
    
    # Generate evolution report
    generate_evolution_report
    
    log_evolution "INFO" "Evolution tracking complete"
}

# Execute main function
main "$@"