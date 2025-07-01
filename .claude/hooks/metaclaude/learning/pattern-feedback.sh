#!/bin/bash
#
# Pattern Feedback Hook - Collects feedback on pattern effectiveness
# Part of MetaClaude Phase 5: Cross-Domain Learning
#

set -euo pipefail

# Source MetaClaude utilities
source "$(dirname "$0")/../../utils/metaclaude-utils.sh"

# Configuration
PATTERNS_DIR="${CLAUDE_HOME:-.claude}/patterns"
LIBRARY_DIR="$PATTERNS_DIR/library"
FEEDBACK_DIR="$PATTERNS_DIR/feedback"
ARCHIVE_DIR="$PATTERNS_DIR/archive"
FEEDBACK_LOG="${CLAUDE_HOME:-.claude}/logs/pattern-feedback.log"
METRICS_DB="${CLAUDE_HOME:-.claude}/data/pattern-metrics.json"
THRESHOLD_EFFECTIVENESS=0.3
THRESHOLD_ARCHIVE=0.2

# Initialize directories
mkdir -p "$FEEDBACK_DIR" "$ARCHIVE_DIR" "$(dirname "$FEEDBACK_LOG")" "$(dirname "$METRICS_DB")"

# Function to log feedback events
log_feedback() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$FEEDBACK_LOG"
}

# Function to collect feedback from implementation
collect_implementation_feedback() {
    local pattern_id="$1"
    local implementation_id="$2"
    local feedback_data="$3"
    
    local feedback_id="feedback_${pattern_id}_${implementation_id}_$(date +%s)"
    
    # Structure feedback
    local structured_feedback=$(cat <<EOF
{
    "feedback_id": "$feedback_id",
    "pattern_id": "$pattern_id",
    "implementation_id": "$implementation_id",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "metrics": {
        "success": $(echo "$feedback_data" | jq -r '.success // false'),
        "execution_time": $(echo "$feedback_data" | jq -r '.execution_time // null'),
        "error_count": $(echo "$feedback_data" | jq -r '.error_count // 0'),
        "resource_usage": $(echo "$feedback_data" | jq '.resource_usage // {}'),
        "performance_impact": $(echo "$feedback_data" | jq -r '.performance_impact // null')
    },
    "qualitative": {
        "ease_of_use": $(echo "$feedback_data" | jq -r '.ease_of_use // null'),
        "fit_for_purpose": $(echo "$feedback_data" | jq -r '.fit_for_purpose // null'),
        "modifications_needed": $(echo "$feedback_data" | jq '.modifications_needed // []'),
        "issues_encountered": $(echo "$feedback_data" | jq '.issues_encountered // []')
    },
    "context": {
        "domain": "$(echo "$feedback_data" | jq -r '.domain // "unknown"')",
        "use_case": "$(echo "$feedback_data" | jq -r '.use_case // "general"')",
        "environment": $(echo "$feedback_data" | jq '.environment // {}')
    },
    "recommendations": {
        "continue_use": $(echo "$feedback_data" | jq -r '.continue_use // null'),
        "suggested_improvements": $(echo "$feedback_data" | jq '.suggested_improvements // []'),
        "alternative_patterns": $(echo "$feedback_data" | jq '.alternative_patterns // []')
    }
}
EOF
)
    
    # Save feedback
    echo "$structured_feedback" | jq '.' > "$FEEDBACK_DIR/$feedback_id.json"
    log_feedback "INFO" "Collected feedback for pattern $pattern_id from $implementation_id"
    
    # Update metrics immediately
    update_pattern_metrics "$pattern_id" "$structured_feedback"
    
    echo "$feedback_id"
}

# Function to update pattern metrics
update_pattern_metrics() {
    local pattern_id="$1"
    local feedback="$2"
    
    # Load or create metrics database
    local metrics="{}"
    if [ -f "$METRICS_DB" ]; then
        metrics=$(cat "$METRICS_DB")
    fi
    
    # Update pattern entry
    metrics=$(echo "$metrics" | jq --arg pid "$pattern_id" --argjson fb "$feedback" '
        .patterns[$pid] as $pattern |
        .patterns[$pid] = (
            $pattern // {
                pattern_id: $pid,
                total_feedback: 0,
                success_count: 0,
                failure_count: 0,
                average_execution_time: null,
                total_execution_time: 0,
                effectiveness_score: null,
                domains_used: [],
                last_updated: null
            }
        ) |
        .patterns[$pid].total_feedback += 1 |
        if $fb.metrics.success then
            .patterns[$pid].success_count += 1
        else
            .patterns[$pid].failure_count += 1
        end |
        if $fb.metrics.execution_time then
            .patterns[$pid].total_execution_time += $fb.metrics.execution_time |
            .patterns[$pid].average_execution_time = (.patterns[$pid].total_execution_time / .patterns[$pid].total_feedback)
        end |
        .patterns[$pid].domains_used = (.patterns[$pid].domains_used + [$fb.context.domain] | unique) |
        .patterns[$pid].last_updated = now | strftime("%Y-%m-%dT%H:%M:%SZ")
    ')
    
    # Calculate effectiveness score
    local pattern_metrics=$(echo "$metrics" | jq -r ".patterns[\"$pattern_id\"]")
    local effectiveness=$(calculate_effectiveness_score "$pattern_metrics")
    
    # Update effectiveness score
    metrics=$(echo "$metrics" | jq --arg pid "$pattern_id" --arg eff "$effectiveness" '
        .patterns[$pid].effectiveness_score = ($eff | tonumber)
    ')
    
    # Save updated metrics
    echo "$metrics" | jq '.' > "$METRICS_DB"
}

# Function to calculate effectiveness score
calculate_effectiveness_score() {
    local metrics="$1"
    
    local total=$(echo "$metrics" | jq -r '.total_feedback // 0')
    local success=$(echo "$metrics" | jq -r '.success_count // 0')
    local domains=$(echo "$metrics" | jq '.domains_used | length // 0')
    
    if [ "$total" -eq 0 ]; then
        echo "0"
        return
    fi
    
    # Calculate score based on success rate, usage, and domain diversity
    local score=$(awk -v t="$total" -v s="$success" -v d="$domains" '
        BEGIN {
            success_rate = s / t
            usage_factor = log(t + 1) / log(100)
            domain_factor = d > 1 ? (d > 5 ? 1.0 : d / 5.0) : 0.5
            
            score = success_rate * 0.6 + usage_factor * 0.2 + domain_factor * 0.2
            printf "%.3f", score
        }
    ')
    
    echo "$score"
}

# Function to aggregate feedback for pattern
aggregate_pattern_feedback() {
    local pattern_id="$1"
    
    # Find all feedback for this pattern
    local feedback_files=()
    while IFS= read -r file; do
        feedback_files+=("$file")
    done < <(find "$FEEDBACK_DIR" -name "feedback_${pattern_id}_*.json" -type f)
    
    if [ ${#feedback_files[@]} -eq 0 ]; then
        echo "{}"
        return
    fi
    
    # Aggregate feedback data
    local aggregated=$(cat <<EOF
{
    "pattern_id": "$pattern_id",
    "feedback_count": ${#feedback_files[@]},
    "aggregation_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "metrics": $(aggregate_metrics "${feedback_files[@]}"),
    "qualitative_summary": $(summarize_qualitative "${feedback_files[@]}"),
    "domain_distribution": $(analyze_domain_distribution "${feedback_files[@]}"),
    "improvement_suggestions": $(collect_improvements "${feedback_files[@]}"),
    "overall_rating": $(calculate_overall_rating "${feedback_files[@]}")
}
EOF
)
    
    echo "$aggregated"
}

# Function to aggregate metrics
aggregate_metrics() {
    local files=("$@")
    
    # Collect all metrics
    local metrics_json="["
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            metrics_json+="{\"file\":\"$file\",\"metrics\":$(jq '.metrics' "$file")},"
        fi
    done
    metrics_json="${metrics_json%,}]"
    
    # Calculate aggregates
    echo "$metrics_json" | jq '
        {
            success_rate: (map(select(.metrics.success == true)) | length) / length,
            average_execution_time: map(.metrics.execution_time // 0) | add / length,
            total_errors: map(.metrics.error_count // 0) | add,
            performance_distribution: {
                improved: (map(select(.metrics.performance_impact > 0)) | length),
                neutral: (map(select(.metrics.performance_impact == 0)) | length),
                degraded: (map(select(.metrics.performance_impact < 0)) | length)
            }
        }
    '
}

# Function to summarize qualitative feedback
summarize_qualitative() {
    local files=("$@")
    
    # Collect qualitative data
    local qual_data="[]"
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            qual_data=$(echo "$qual_data" | jq --slurpfile new <(jq '.qualitative' "$file") '. + $new')
        fi
    done
    
    # Summarize
    echo "$qual_data" | jq '
        {
            ease_of_use: {
                average: (map(.ease_of_use // 0) | add / length),
                distribution: group_by(.ease_of_use) | map({rating: .[0].ease_of_use, count: length})
            },
            fit_for_purpose: {
                average: (map(.fit_for_purpose // 0) | add / length),
                distribution: group_by(.fit_for_purpose) | map({rating: .[0].fit_for_purpose, count: length})
            },
            common_modifications: (map(.modifications_needed // []) | flatten | group_by(.) | map({modification: .[0], count: length}) | sort_by(-.count)),
            frequent_issues: (map(.issues_encountered // []) | flatten | group_by(.) | map({issue: .[0], count: length}) | sort_by(-.count))
        }
    '
}

# Function to analyze domain distribution
analyze_domain_distribution() {
    local files=("$@")
    
    # Collect domain data
    local domains="[]"
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local domain=$(jq -r '.context.domain // "unknown"' "$file")
            local success=$(jq -r '.metrics.success // false' "$file")
            domains=$(echo "$domains" | jq --arg d "$domain" --arg s "$success" '. + [{domain: $d, success: ($s == "true")}]')
        fi
    done
    
    # Analyze distribution
    echo "$domains" | jq '
        group_by(.domain) |
        map({
            domain: .[0].domain,
            count: length,
            success_rate: (map(select(.success == true)) | length) / length
        }) |
        sort_by(-.count)
    '
}

# Function to collect improvement suggestions
collect_improvements() {
    local files=("$@")
    
    # Collect all suggestions
    local suggestions="[]"
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            suggestions=$(echo "$suggestions" | jq --slurpfile new <(jq '.recommendations.suggested_improvements // []' "$file") '. + $new | flatten')
        fi
    done
    
    # Group and rank suggestions
    echo "$suggestions" | jq '
        group_by(.) |
        map({
            suggestion: .[0],
            frequency: length,
            priority: (
                if length > 5 then "high"
                elif length > 2 then "medium"
                else "low"
                end
            )
        }) |
        sort_by(-.frequency)
    '
}

# Function to calculate overall rating
calculate_overall_rating() {
    local files=("$@")
    
    local total_score=0
    local count=0
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local success=$(jq -r '.metrics.success // false' "$file")
            local ease=$(jq -r '.qualitative.ease_of_use // 3' "$file")
            local fit=$(jq -r '.qualitative.fit_for_purpose // 3' "$file")
            local continue=$(jq -r '.recommendations.continue_use // null' "$file")
            
            # Calculate file score
            local score=$(awk -v s="$success" -v e="$ease" -v f="$fit" -v c="$continue" '
                BEGIN {
                    success_score = s == "true" ? 1 : 0
                    ease_score = e / 5.0
                    fit_score = f / 5.0
                    continue_score = c == "true" ? 1 : c == "false" ? 0 : 0.5
                    
                    total = success_score * 0.4 + ease_score * 0.2 + fit_score * 0.2 + continue_score * 0.2
                    print total
                }
            ')
            
            total_score=$(awk -v t="$total_score" -v s="$score" 'BEGIN { print t + s }')
            count=$((count + 1))
        fi
    done
    
    if [ "$count" -gt 0 ]; then
        awk -v t="$total_score" -v c="$count" 'BEGIN { printf "%.3f", t / c }'
    else
        echo "0"
    fi
}

# Function to rate pattern effectiveness
rate_pattern_effectiveness() {
    local pattern_id="$1"
    
    # Get current metrics
    if [ ! -f "$METRICS_DB" ]; then
        echo "0"
        return
    fi
    
    local effectiveness=$(jq -r ".patterns[\"$pattern_id\"].effectiveness_score // 0" "$METRICS_DB")
    
    echo "$effectiveness"
}

# Function to check if pattern should be archived
should_archive_pattern() {
    local pattern_id="$1"
    local effectiveness="$2"
    
    # Check effectiveness threshold
    if (( $(echo "$effectiveness < $THRESHOLD_ARCHIVE" | bc -l) )); then
        return 0  # Should archive
    fi
    
    # Check if pattern has recent positive feedback
    local recent_success=$(find "$FEEDBACK_DIR" -name "feedback_${pattern_id}_*.json" -mtime -30 -exec jq -r '.metrics.success' {} \; | grep -c "true")
    
    if [ "$recent_success" -eq 0 ]; then
        return 0  # Should archive
    fi
    
    return 1  # Should not archive
}

# Function to archive ineffective pattern
archive_pattern() {
    local pattern_id="$1"
    local reason="$2"
    
    local library_file="$LIBRARY_DIR/${pattern_id}.json"
    if [ ! -f "$library_file" ]; then
        log_feedback "WARN" "Pattern file not found for archiving: $pattern_id"
        return 1
    fi
    
    # Create archive entry
    local archive_entry=$(cat <<EOF
{
    "pattern": $(cat "$library_file"),
    "archive_metadata": {
        "archived_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "reason": "$reason",
        "final_metrics": $(jq ".patterns[\"$pattern_id\"] // {}" "$METRICS_DB"),
        "feedback_summary": $(aggregate_pattern_feedback "$pattern_id")
    }
}
EOF
)
    
    # Save to archive
    echo "$archive_entry" | jq '.' > "$ARCHIVE_DIR/${pattern_id}_archived.json"
    
    # Remove from library
    rm -f "$library_file"
    
    # Update library index
    local index_file="$LIBRARY_DIR/index.json"
    if [ -f "$index_file" ]; then
        jq --arg pid "$pattern_id" 'del(.patterns[$pid])' "$index_file" > "${index_file}.tmp"
        mv "${index_file}.tmp" "$index_file"
    fi
    
    log_feedback "INFO" "Archived pattern $pattern_id: $reason"
    
    return 0
}

# Function to process feedback queue
process_feedback_queue() {
    local queue_dir="${CLAUDE_HOME:-.claude}/feedback/queue"
    
    if [ ! -d "$queue_dir" ]; then
        return
    fi
    
    # Process each feedback item
    while IFS= read -r feedback_file; do
        if [ ! -f "$feedback_file" ]; then
            continue
        fi
        
        local feedback_data=$(cat "$feedback_file")
        local pattern_id=$(echo "$feedback_data" | jq -r '.pattern_id // ""')
        local implementation_id=$(echo "$feedback_data" | jq -r '.implementation_id // "unknown"')
        
        if [ -n "$pattern_id" ]; then
            collect_implementation_feedback "$pattern_id" "$implementation_id" "$feedback_data"
            
            # Remove from queue
            rm -f "$feedback_file"
        fi
    done < <(find "$queue_dir" -name "*.json" -type f)
}

# Function to generate feedback report
generate_feedback_report() {
    local report_file="$PATTERNS_DIR/feedback-report.json"
    
    # Collect statistics
    local total_patterns=$(jq '.patterns | length' "$METRICS_DB" 2>/dev/null || echo "0")
    local high_performing=$(jq '[.patterns[] | select(.effectiveness_score >= 0.7)] | length' "$METRICS_DB" 2>/dev/null || echo "0")
    local low_performing=$(jq "[.patterns[] | select(.effectiveness_score < $THRESHOLD_EFFECTIVENESS)] | length" "$METRICS_DB" 2>/dev/null || echo "0")
    local archived_count=$(find "$ARCHIVE_DIR" -name "*_archived.json" | wc -l)
    
    cat <<EOF > "$report_file"
{
    "report_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "pattern_statistics": {
        "total_tracked": $total_patterns,
        "high_performing": $high_performing,
        "low_performing": $low_performing,
        "archived": $archived_count
    },
    "feedback_statistics": {
        "total_feedback": $(find "$FEEDBACK_DIR" -name "feedback_*.json" | wc -l),
        "recent_feedback": $(find "$FEEDBACK_DIR" -name "feedback_*.json" -mtime -7 | wc -l),
        "implementations_reporting": $(find "$FEEDBACK_DIR" -name "feedback_*.json" -exec jq -r '.implementation_id' {} \; | sort -u | wc -l)
    },
    "effectiveness_distribution": $(
        if [ -f "$METRICS_DB" ]; then
            jq '[.patterns[] | .effectiveness_score // 0] | {
                excellent: (map(select(. >= 0.8)) | length),
                good: (map(select(. >= 0.6 and . < 0.8)) | length),
                fair: (map(select(. >= 0.4 and . < 0.6)) | length),
                poor: (map(select(. < 0.4)) | length)
            }' "$METRICS_DB"
        else
            echo '{"excellent": 0, "good": 0, "fair": 0, "poor": 0}'
        fi
    ),
    "top_patterns": $(
        if [ -f "$METRICS_DB" ]; then
            jq '[.patterns | to_entries | sort_by(-.value.effectiveness_score // 0) | limit(5; .[]) | {
                pattern_id: .key,
                effectiveness: .value.effectiveness_score,
                success_rate: (.value.success_count / .value.total_feedback),
                domains: .value.domains_used
            }]' "$METRICS_DB"
        else
            echo '[]'
        fi
    )
}
EOF
}

# Main feedback processing logic
main() {
    log_feedback "INFO" "Starting pattern feedback processing"
    
    # Process feedback queue
    process_feedback_queue
    
    # Evaluate all patterns
    local patterns_evaluated=0
    local patterns_archived=0
    
    if [ -f "$METRICS_DB" ]; then
        while IFS= read -r pattern_id; do
            patterns_evaluated=$((patterns_evaluated + 1))
            
            # Rate effectiveness
            local effectiveness=$(rate_pattern_effectiveness "$pattern_id")
            
            # Check if should archive
            if should_archive_pattern "$pattern_id" "$effectiveness"; then
                local reason="Low effectiveness score: $effectiveness"
                if (( $(echo "$effectiveness < $THRESHOLD_ARCHIVE" | bc -l) )); then
                    reason="Below archive threshold: $effectiveness"
                fi
                
                if archive_pattern "$pattern_id" "$reason"; then
                    patterns_archived=$((patterns_archived + 1))
                fi
            fi
            
            # Update pattern library with current rating
            local library_file="$LIBRARY_DIR/${pattern_id}.json"
            if [ -f "$library_file" ]; then
                jq --arg eff "$effectiveness" '.effectiveness_score = ($eff | tonumber)' "$library_file" > "${library_file}.tmp"
                mv "${library_file}.tmp" "$library_file"
            fi
        done < <(jq -r '.patterns | keys[]' "$METRICS_DB")
    fi
    
    log_feedback "INFO" "Feedback processing complete: $patterns_evaluated patterns evaluated, $patterns_archived archived"
    
    # Generate feedback report
    generate_feedback_report
}

# Execute main function
main "$@"