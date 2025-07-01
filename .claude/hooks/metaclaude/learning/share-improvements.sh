#!/bin/bash
#
# Share Improvements Hook - Broadcasts successful patterns to all implementations
# Part of MetaClaude Phase 5: Cross-Domain Learning
#

set -euo pipefail

# Source MetaClaude utilities
source "$(dirname "$0")/../../utils/metaclaude-utils.sh"

# Configuration
PATTERNS_DIR="${CLAUDE_HOME:-.claude}/patterns"
UNIVERSAL_DIR="$PATTERNS_DIR/universal"
LIBRARY_DIR="$PATTERNS_DIR/library"
BROADCAST_DIR="$PATTERNS_DIR/broadcast"
ADOPTION_LOG="${CLAUDE_HOME:-.claude}/logs/pattern-adoption.log"
SHARE_LOG="${CLAUDE_HOME:-.claude}/logs/pattern-sharing.log"
IMPLEMENTATIONS_DIR="${CLAUDE_HOME:-.claude}/implementations"

# Initialize directories
mkdir -p "$LIBRARY_DIR" "$BROADCAST_DIR" "$(dirname "$SHARE_LOG")"

# Function to log sharing events
log_share() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$SHARE_LOG"
}

# Function to evaluate pattern quality
evaluate_pattern_quality() {
    local pattern_file="$1"
    
    if [ ! -f "$pattern_file" ]; then
        echo "0"
        return
    fi
    
    local pattern=$(cat "$pattern_file")
    
    # Quality factors
    local confidence=$(echo "$pattern" | jq -r '.metadata.confidence // 0')
    local usage_count=$(echo "$pattern" | jq -r '.metadata.usage_count // 0')
    local success_rate=$(echo "$pattern" | jq -r '.metadata.success_rate // 0')
    local principle_count=$(echo "$pattern" | jq '.principles | length // 0')
    local domain_count=$(echo "$pattern" | jq '.domains | length // 0')
    
    # Calculate quality score
    local quality=$(awk -v c="$confidence" -v u="$usage_count" -v s="$success_rate" -v p="$principle_count" -v d="$domain_count" '
        BEGIN {
            usage_factor = u > 0 ? log(u + 1) / log(100) : 0
            success_factor = s > 0 ? s : 0.5
            principle_factor = p > 0 ? (p > 5 ? 1.0 : p / 5.0) : 0.3
            domain_factor = d > 1 ? (d > 3 ? 1.0 : d / 3.0) : 0.5
            
            quality = c * 0.3 + usage_factor * 0.2 + success_factor * 0.3 + principle_factor * 0.1 + domain_factor * 0.1
            printf "%.3f", quality
        }
    ')
    
    echo "$quality"
}

# Function to prepare pattern for broadcast
prepare_broadcast_package() {
    local pattern_file="$1"
    local quality_score="$2"
    
    local pattern=$(cat "$pattern_file")
    local pattern_id=$(echo "$pattern" | jq -r '.pattern_id')
    local broadcast_id="broadcast_${pattern_id}_$(date +%s)"
    
    # Create broadcast package
    cat <<EOF
{
    "broadcast_id": "$broadcast_id",
    "pattern": $pattern,
    "quality_score": $quality_score,
    "broadcast_metadata": {
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "source": "$(hostname)",
        "version": "1.0.0",
        "priority": $(calculate_broadcast_priority "$quality_score")
    },
    "adoption_tracking": {
        "implementations": [],
        "feedback": [],
        "metrics": {
            "adoption_rate": 0,
            "success_rate": null,
            "improvement_impact": null
        }
    },
    "distribution": {
        "targets": $(identify_target_implementations "$pattern"),
        "method": "push",
        "retry_policy": {
            "max_attempts": 3,
            "backoff": "exponential"
        }
    }
}
EOF
}

# Function to calculate broadcast priority
calculate_broadcast_priority() {
    local quality_score="$1"
    
    if (( $(echo "$quality_score > 0.8" | bc -l) )); then
        echo '"high"'
    elif (( $(echo "$quality_score > 0.5" | bc -l) )); then
        echo '"medium"'
    else
        echo '"low"'
    fi
}

# Function to identify target implementations
identify_target_implementations() {
    local pattern="$1"
    
    # Get applicable domains
    local domains=$(echo "$pattern" | jq -r '.domains[]' 2>/dev/null)
    local contexts=$(echo "$pattern" | jq -r '.applicability.contexts[]' 2>/dev/null)
    
    # Find matching implementations
    local targets=()
    
    if [ -d "$IMPLEMENTATIONS_DIR" ]; then
        while IFS= read -r impl_dir; do
            local impl_config="$impl_dir/config.json"
            if [ -f "$impl_config" ]; then
                local impl_domains=$(jq -r '.domains[]' "$impl_config" 2>/dev/null)
                local impl_capabilities=$(jq -r '.capabilities[]' "$impl_config" 2>/dev/null)
                
                # Check for domain match
                for domain in $domains; do
                    if echo "$impl_domains" | grep -q "$domain"; then
                        targets+=("$(basename "$impl_dir")")
                        break
                    fi
                done
                
                # Check for context match
                for context in $contexts; do
                    if echo "$impl_capabilities" | grep -q "$context"; then
                        targets+=("$(basename "$impl_dir")")
                        break
                    fi
                done
            fi
        done < <(find "$IMPLEMENTATIONS_DIR" -mindepth 1 -maxdepth 1 -type d)
    fi
    
    # Default to all if no specific targets found
    if [ ${#targets[@]} -eq 0 ]; then
        targets=("all")
    fi
    
    printf '%s\n' "${targets[@]}" | sort -u | jq -R . | jq -s .
}

# Function to broadcast pattern
broadcast_pattern() {
    local broadcast_package="$1"
    local broadcast_id=$(echo "$broadcast_package" | jq -r '.broadcast_id')
    
    # Save broadcast package
    echo "$broadcast_package" | jq '.' > "$BROADCAST_DIR/${broadcast_id}.json"
    
    # Get targets
    local targets=$(echo "$broadcast_package" | jq -r '.distribution.targets[]')
    
    # Broadcast to each target
    local success_count=0
    local total_count=0
    
    while IFS= read -r target; do
        total_count=$((total_count + 1))
        
        if [ "$target" = "all" ]; then
            # Broadcast to pattern library (central repository)
            if update_pattern_library "$broadcast_package"; then
                success_count=$((success_count + 1))
                log_share "INFO" "Pattern $broadcast_id added to central library"
            fi
        else
            # Broadcast to specific implementation
            if notify_implementation "$target" "$broadcast_package"; then
                success_count=$((success_count + 1))
                log_share "INFO" "Pattern $broadcast_id sent to implementation: $target"
            fi
        fi
    done <<< "$targets"
    
    # Update broadcast status
    local status="completed"
    if [ "$success_count" -eq 0 ]; then
        status="failed"
    elif [ "$success_count" -lt "$total_count" ]; then
        status="partial"
    fi
    
    update_broadcast_status "$broadcast_id" "$status" "$success_count" "$total_count"
    
    return 0
}

# Function to update pattern library
update_pattern_library() {
    local broadcast_package="$1"
    local pattern=$(echo "$broadcast_package" | jq '.pattern')
    local pattern_id=$(echo "$pattern" | jq -r '.pattern_id')
    local quality_score=$(echo "$broadcast_package" | jq -r '.quality_score')
    
    # Check if pattern already exists
    local existing_file="$LIBRARY_DIR/${pattern_id}.json"
    if [ -f "$existing_file" ]; then
        local existing_quality=$(jq -r '.quality_score // 0' "$existing_file")
        
        # Only update if new version is better
        if (( $(echo "$quality_score <= $existing_quality" | bc -l) )); then
            log_share "INFO" "Pattern $pattern_id already exists with equal or better quality"
            return 0
        fi
    fi
    
    # Create library entry
    local library_entry=$(cat <<EOF
{
    "pattern": $pattern,
    "quality_score": $quality_score,
    "library_metadata": {
        "added_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "version": "1.0.0",
        "status": "active"
    },
    "usage_stats": {
        "download_count": 0,
        "implementation_count": 0,
        "success_reports": 0,
        "failure_reports": 0
    },
    "tags": $(generate_pattern_tags "$pattern"),
    "related_patterns": []
}
EOF
)
    
    # Save to library
    echo "$library_entry" | jq '.' > "$existing_file"
    
    # Update library index
    update_library_index "$pattern_id" "$pattern"
    
    return 0
}

# Function to generate pattern tags
generate_pattern_tags() {
    local pattern="$1"
    
    local tags=()
    
    # Add principle-based tags
    while IFS= read -r principle; do
        tags+=("principle:$principle")
    done < <(echo "$pattern" | jq -r '.principles[]' 2>/dev/null)
    
    # Add domain tags
    while IFS= read -r domain; do
        tags+=("domain:$domain")
    done < <(echo "$pattern" | jq -r '.domains[]' 2>/dev/null)
    
    # Add type tag
    local pattern_type=$(echo "$pattern" | jq -r '.pattern_type // "unknown"')
    tags+=("type:$pattern_type")
    
    # Add abstraction level tag
    local abstraction_level=$(echo "$pattern" | jq -r '.abstraction_level // "unknown"')
    tags+=("level:$abstraction_level")
    
    printf '%s\n' "${tags[@]}" | jq -R . | jq -s .
}

# Function to update library index
update_library_index() {
    local pattern_id="$1"
    local pattern="$2"
    
    local index_file="$LIBRARY_DIR/index.json"
    
    # Create or load index
    local index="{}"
    if [ -f "$index_file" ]; then
        index=$(cat "$index_file")
    fi
    
    # Update index entry
    index=$(echo "$index" | jq --arg id "$pattern_id" --argjson pattern "$pattern" '
        .patterns[$id] = {
            name: $pattern.name,
            type: $pattern.pattern_type,
            domains: $pattern.domains,
            principles: $pattern.principles,
            tags: $pattern.tags,
            quality_score: $pattern.quality_score,
            last_updated: now | strftime("%Y-%m-%dT%H:%M:%SZ")
        }
    ')
    
    # Save updated index
    echo "$index" | jq '.' > "$index_file"
}

# Function to notify implementation
notify_implementation() {
    local target="$1"
    local broadcast_package="$2"
    
    local impl_dir="$IMPLEMENTATIONS_DIR/$target"
    if [ ! -d "$impl_dir" ]; then
        log_share "WARN" "Implementation directory not found: $target"
        return 1
    fi
    
    # Create notification
    local notification_dir="$impl_dir/notifications/patterns"
    mkdir -p "$notification_dir"
    
    local broadcast_id=$(echo "$broadcast_package" | jq -r '.broadcast_id')
    local notification_file="$notification_dir/${broadcast_id}.json"
    
    # Save notification
    echo "$broadcast_package" | jq '.' > "$notification_file"
    
    # Trigger implementation hook if exists
    local impl_hook="$impl_dir/hooks/on-pattern-received.sh"
    if [ -x "$impl_hook" ]; then
        "$impl_hook" "$notification_file" &
    fi
    
    return 0
}

# Function to update broadcast status
update_broadcast_status() {
    local broadcast_id="$1"
    local status="$2"
    local success_count="$3"
    local total_count="$4"
    
    local broadcast_file="$BROADCAST_DIR/${broadcast_id}.json"
    if [ -f "$broadcast_file" ]; then
        # Update status
        local updated=$(jq --arg status "$status" --arg success "$success_count" --arg total "$total_count" '
            .broadcast_metadata.status = $status |
            .broadcast_metadata.completed_at = now | strftime("%Y-%m-%dT%H:%M:%SZ") |
            .broadcast_metadata.results = {
                success_count: ($success | tonumber),
                total_count: ($total | tonumber),
                success_rate: (($success | tonumber) / ($total | tonumber))
            }
        ' "$broadcast_file")
        
        echo "$updated" | jq '.' > "$broadcast_file"
    fi
}

# Function to track adoption rates
track_adoption_rates() {
    # Analyze adoption logs
    if [ ! -f "$ADOPTION_LOG" ]; then
        return
    fi
    
    # Calculate adoption metrics for each pattern
    local adoption_stats=$(awk -F'\t' '
        $2 == "ADOPTED" {
            adopted[$3]++
            total[$3]++
        }
        $2 == "REJECTED" {
            total[$3]++
        }
        END {
            for (pattern in total) {
                rate = adopted[pattern] / total[pattern]
                print pattern "\t" adopted[pattern] "\t" total[pattern] "\t" rate
            }
        }
    ' "$ADOPTION_LOG")
    
    # Update pattern metadata with adoption rates
    while IFS=$'\t' read -r pattern_id adopted total rate; do
        local library_file="$LIBRARY_DIR/${pattern_id}.json"
        if [ -f "$library_file" ]; then
            local updated=$(jq --arg adopted "$adopted" --arg total "$total" --arg rate "$rate" '
                .usage_stats.implementation_count = ($adopted | tonumber) |
                .adoption_rate = ($rate | tonumber)
            ' "$library_file")
            
            echo "$updated" | jq '.' > "$library_file"
        fi
    done <<< "$adoption_stats"
}

# Function to select patterns for broadcast
select_patterns_for_broadcast() {
    local min_quality="${1:-0.5}"
    local max_patterns="${2:-10}"
    
    # Find eligible patterns
    local eligible_patterns=()
    
    # Check universal patterns
    if [ -d "$UNIVERSAL_DIR" ]; then
        while IFS= read -r pattern_file; do
            local quality=$(evaluate_pattern_quality "$pattern_file")
            
            if (( $(echo "$quality >= $min_quality" | bc -l) )); then
                eligible_patterns+=("$pattern_file:$quality")
            fi
        done < <(find "$UNIVERSAL_DIR" -name "*.json" -type f -mtime -7)  # Patterns from last week
    fi
    
    # Sort by quality and select top patterns
    printf '%s\n' "${eligible_patterns[@]}" | sort -t: -k2 -nr | head -n "$max_patterns" | cut -d: -f1
}

# Main broadcast logic
main() {
    log_share "INFO" "Starting pattern sharing process"
    
    # Track adoption rates from previous broadcasts
    track_adoption_rates
    
    # Select patterns for broadcast
    local patterns_to_broadcast=$(select_patterns_for_broadcast)
    
    if [ -z "$patterns_to_broadcast" ]; then
        log_share "INFO" "No patterns eligible for broadcast"
        exit 0
    fi
    
    local broadcast_count=0
    local total_patterns=0
    
    # Process each selected pattern
    while IFS= read -r pattern_file; do
        if [ -z "$pattern_file" ]; then
            continue
        fi
        
        total_patterns=$((total_patterns + 1))
        
        local quality=$(evaluate_pattern_quality "$pattern_file")
        log_share "INFO" "Broadcasting pattern: $(basename "$pattern_file") (quality: $quality)"
        
        # Prepare and broadcast
        local broadcast_package=$(prepare_broadcast_package "$pattern_file" "$quality")
        
        if broadcast_pattern "$broadcast_package"; then
            broadcast_count=$((broadcast_count + 1))
        fi
    done <<< "$patterns_to_broadcast"
    
    log_share "INFO" "Pattern sharing complete: $broadcast_count/$total_patterns patterns broadcast"
    
    # Generate sharing report
    generate_sharing_report "$broadcast_count" "$total_patterns"
}

# Function to generate sharing report
generate_sharing_report() {
    local broadcast_count="$1"
    local total_patterns="$2"
    
    local report_file="$PATTERNS_DIR/sharing-report.json"
    
    cat <<EOF > "$report_file"
{
    "report_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "broadcast_summary": {
        "patterns_selected": $total_patterns,
        "patterns_broadcast": $broadcast_count,
        "success_rate": $(awk -v b="$broadcast_count" -v t="$total_patterns" 'BEGIN { print t > 0 ? b/t : 0 }')
    },
    "library_stats": {
        "total_patterns": $(find "$LIBRARY_DIR" -name "*.json" -not -name "index.json" | wc -l),
        "active_patterns": $(find "$LIBRARY_DIR" -name "*.json" -not -name "index.json" -exec jq -r 'select(.library_metadata.status == "active") | .pattern_id' {} \; | wc -l)
    },
    "adoption_metrics": {
        "implementations_reached": $(find "$IMPLEMENTATIONS_DIR" -name "*.json" -path "*/notifications/patterns/*" -mtime -1 | wc -l),
        "average_adoption_rate": $(jq -s 'map(select(.adoption_rate) | .adoption_rate) | add / length' "$LIBRARY_DIR"/*.json 2>/dev/null || echo "0")
    }
}
EOF
}

# Execute main function
main "$@"