#!/bin/bash
#
# Persist Knowledge Hook - Saves learned patterns and insights for future sessions
# Part of MetaClaude Phase 5: Cross-Domain Learning
#

set -euo pipefail

# Source MetaClaude utilities
source "$(dirname "$0")/../../utils/metaclaude-utils.sh"

# Configuration
LEARNING_DIR="${CLAUDE_HOME:-.claude}/learning"
PERSISTENCE_DIR="$LEARNING_DIR/persistence"
KNOWLEDGE_BASE="$PERSISTENCE_DIR/knowledge-base.json"
CHECKPOINT_DIR="$PERSISTENCE_DIR/checkpoints"
EXPORT_DIR="$PERSISTENCE_DIR/exports"
PERSISTENCE_LOG="${CLAUDE_HOME:-.claude}/logs/knowledge-persistence.log"
RETENTION_DAYS=365
CHECKPOINT_INTERVAL=86400  # 24 hours in seconds

# Initialize directories
mkdir -p "$PERSISTENCE_DIR" "$CHECKPOINT_DIR" "$EXPORT_DIR" "$(dirname "$PERSISTENCE_LOG")"

# Function to log persistence events
log_persistence() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$PERSISTENCE_LOG"
}

# Function to collect all learned knowledge
collect_learned_knowledge() {
    local knowledge=$(cat <<EOF
{
    "collection_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "knowledge_version": "1.0.0",
    "patterns": $(collect_pattern_knowledge),
    "insights": $(collect_insight_knowledge),
    "evolution": $(collect_evolution_knowledge),
    "meta_learning": $(collect_meta_learning_knowledge),
    "operational": $(collect_operational_knowledge)
}
EOF
)
    
    echo "$knowledge"
}

# Function to collect pattern knowledge
collect_pattern_knowledge() {
    local patterns_dir="${CLAUDE_HOME:-.claude}/patterns"
    
    # Collect from different pattern sources
    local extracted_patterns="[]"
    local universal_patterns="[]"
    local library_patterns="[]"
    
    if [ -d "$patterns_dir/extracted" ]; then
        extracted_patterns=$(find "$patterns_dir/extracted" -name "*.json" -type f -exec jq -s '.' {} + 2>/dev/null || echo "[]")
    fi
    
    if [ -d "$patterns_dir/universal" ]; then
        universal_patterns=$(find "$patterns_dir/universal" -name "*.json" -type f -exec jq -s '.' {} + 2>/dev/null || echo "[]")
    fi
    
    if [ -d "$patterns_dir/library" ]; then
        library_patterns=$(find "$patterns_dir/library" -name "*.json" -not -name "index.json" -type f -exec jq '.pattern' {} \; | jq -s '.' 2>/dev/null || echo "[]")
    fi
    
    # Combine and structure
    cat <<EOF
{
    "total_patterns": $(echo "$extracted_patterns $universal_patterns $library_patterns" | jq -s 'map(length) | add'),
    "extracted": {
        "count": $(echo "$extracted_patterns" | jq 'length'),
        "patterns": $extracted_patterns
    },
    "universal": {
        "count": $(echo "$universal_patterns" | jq 'length'),
        "patterns": $universal_patterns
    },
    "library": {
        "count": $(echo "$library_patterns" | jq 'length'),
        "patterns": $library_patterns
    },
    "metrics": $(collect_pattern_metrics)
}
EOF
}

# Function to collect pattern metrics
collect_pattern_metrics() {
    local metrics_db="${CLAUDE_HOME:-.claude}/data/pattern-metrics.json"
    
    if [ -f "$metrics_db" ]; then
        jq '.patterns' "$metrics_db"
    else
        echo "{}"
    fi
}

# Function to collect insight knowledge
collect_insight_knowledge() {
    local insights_dir="$LEARNING_DIR/meta/insights"
    
    if [ -d "$insights_dir" ]; then
        # Get recent insights
        local recent_insights=$(find "$insights_dir" -name "*.json" -type f -mtime -30 -exec jq -s '.' {} + 2>/dev/null || echo "[]")
        
        # Summarize key findings
        cat <<EOF
{
    "total_insights": $(find "$insights_dir" -name "*.json" -type f | wc -l),
    "recent_insights": $recent_insights,
    "key_findings": $(extract_key_findings "$recent_insights"),
    "trend_analysis": $(analyze_insight_trends "$recent_insights")
}
EOF
    else
        echo '{"total_insights": 0, "recent_insights": [], "key_findings": [], "trend_analysis": {}}'
    fi
}

# Function to extract key findings
extract_key_findings() {
    local insights="$1"
    
    echo "$insights" | jq '
        map(.recommendations // []) |
        flatten |
        group_by(.type) |
        map({
            recommendation_type: .[0].type,
            frequency: length,
            priority: (map(.priority) | group_by(.) | max_by(length) | .[0]),
            patterns: (map(.patterns // []) | flatten | unique)
        }) |
        sort_by(-.frequency)
    '
}

# Function to analyze insight trends
analyze_insight_trends() {
    local insights="$1"
    
    echo "$insights" | jq '
        {
            performance_improvement: (
                map(.pattern_insights.performance_distribution.high_performer_ratio // 0) |
                {
                    average: (add / length),
                    trend: (
                        if length > 1 then
                            if .[-1] > .[0] then "improving"
                            elif .[-1] < .[0] then "declining"
                            else "stable"
                            end
                        else "insufficient_data"
                        end
                    )
                }
            ),
            cross_domain_adoption: (
                map(.pattern_insights.performance_distribution.cross_domain_patterns // 0) |
                add
            ),
            combination_discovery_rate: (
                map(.combination_insights.viable_combinations // 0) |
                if length > 0 then add / length else 0 end
            )
        }
    '
}

# Function to collect evolution knowledge
collect_evolution_knowledge() {
    local evolution_dir="$LEARNING_DIR/evolution"
    
    if [ -d "$evolution_dir" ]; then
        # Collect lineage data
        local lineages=$(find "$evolution_dir/lineage" -name "*_lineage.json" -type f -exec jq -s '.' {} + 2>/dev/null || echo "[]")
        
        # Collect emergence data
        local emergence=$(find "$evolution_dir/emergence" -name "*.json" -type f -exec jq -s '.' {} + 2>/dev/null || echo "[]")
        
        cat <<EOF
{
    "pattern_lineages": {
        "count": $(echo "$lineages" | jq 'length'),
        "total_modifications": $(echo "$lineages" | jq 'map(.total_modifications // 0) | add'),
        "lineages": $lineages
    },
    "emerging_patterns": {
        "count": $(echo "$emergence" | jq 'length'),
        "active_trends": $(echo "$emergence" | jq 'map(.emerging_trends // []) | flatten | length'),
        "emergence_data": $emergence
    },
    "evolution_metrics": $(load_evolution_metrics)
}
EOF
    else
        echo '{"pattern_lineages": {"count": 0}, "emerging_patterns": {"count": 0}}'
    fi
}

# Function to load evolution metrics
load_evolution_metrics() {
    local evolution_db="$LEARNING_DIR/evolution/evolution-database.json"
    
    if [ -f "$evolution_db" ]; then
        jq '.metrics // {}' "$evolution_db"
    else
        echo "{}"
    fi
}

# Function to collect meta-learning knowledge
collect_meta_learning_knowledge() {
    local meta_dir="$LEARNING_DIR/meta"
    
    if [ -d "$meta_dir" ]; then
        # Load learning model
        local learning_model="{}"
        if [ -f "$meta_dir/learning-model.json" ]; then
            learning_model=$(cat "$meta_dir/learning-model.json")
        fi
        
        # Collect compositions
        local compositions=$(find "$meta_dir/compositions" -name "*.json" -type f -exec jq -s '.' {} + 2>/dev/null || echo "[]")
        
        cat <<EOF
{
    "learning_model": $learning_model,
    "discovered_compositions": {
        "count": $(echo "$compositions" | jq 'map(length) | add // 0'),
        "compositions": $compositions
    },
    "learning_iterations": $(echo "$learning_model" | jq '.learning_iterations // 0')
}
EOF
    else
        echo '{"learning_model": {}, "discovered_compositions": {"count": 0}}'
    fi
}

# Function to collect operational knowledge
collect_operational_knowledge() {
    # Collect operational statistics and configuration
    cat <<EOF
{
    "session_count": $(find "${CLAUDE_HOME:-.claude}/logs" -name "session_*.log" -type f | wc -l),
    "total_operations": $(find "${CLAUDE_HOME:-.claude}/logs" -name "operations.log" -type f -exec wc -l {} \; | awk '{sum+=$1} END {print sum}' || echo "0"),
    "active_implementations": $(find "${CLAUDE_HOME:-.claude}/implementations" -mindepth 1 -maxdepth 1 -type d | wc -l),
    "configuration": {
        "retention_days": $RETENTION_DAYS,
        "checkpoint_interval": $CHECKPOINT_INTERVAL,
        "learning_enabled": true
    }
}
EOF
}

# Function to create knowledge checkpoint
create_knowledge_checkpoint() {
    local knowledge="$1"
    local checkpoint_id="checkpoint_$(date +%s)"
    local checkpoint_file="$CHECKPOINT_DIR/${checkpoint_id}.json"
    
    log_persistence "INFO" "Creating knowledge checkpoint: $checkpoint_id"
    
    # Create checkpoint with metadata
    local checkpoint=$(cat <<EOF
{
    "checkpoint_id": "$checkpoint_id",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "knowledge_version": "$(echo "$knowledge" | jq -r '.knowledge_version')",
    "statistics": {
        "total_patterns": $(echo "$knowledge" | jq '.patterns.total_patterns'),
        "total_insights": $(echo "$knowledge" | jq '.insights.total_insights'),
        "pattern_lineages": $(echo "$knowledge" | jq '.evolution.pattern_lineages.count'),
        "learning_iterations": $(echo "$knowledge" | jq '.meta_learning.learning_iterations')
    },
    "knowledge": $knowledge,
    "integrity": {
        "checksum": "$(echo "$knowledge" | sha256sum | cut -d' ' -f1)",
        "size_bytes": $(echo "$knowledge" | wc -c)
    }
}
EOF
)
    
    # Save checkpoint
    echo "$checkpoint" | jq '.' > "$checkpoint_file"
    
    # Compress older checkpoints
    compress_old_checkpoints
    
    echo "$checkpoint_id"
}

# Function to compress old checkpoints
compress_old_checkpoints() {
    # Find checkpoints older than 7 days
    find "$CHECKPOINT_DIR" -name "checkpoint_*.json" -type f -mtime +7 | while read -r checkpoint; do
        if [ -f "$checkpoint" ] && [ ! -f "${checkpoint}.gz" ]; then
            gzip -9 "$checkpoint"
            log_persistence "INFO" "Compressed checkpoint: $(basename "$checkpoint")"
        fi
    done
}

# Function to update knowledge base
update_knowledge_base() {
    local new_knowledge="$1"
    
    # Load existing knowledge base
    local existing_knowledge="{}"
    if [ -f "$KNOWLEDGE_BASE" ]; then
        existing_knowledge=$(cat "$KNOWLEDGE_BASE")
    fi
    
    # Merge knowledge
    local merged_knowledge=$(merge_knowledge "$existing_knowledge" "$new_knowledge")
    
    # Save updated knowledge base
    echo "$merged_knowledge" | jq '.' > "$KNOWLEDGE_BASE"
    
    log_persistence "INFO" "Updated knowledge base"
}

# Function to merge knowledge
merge_knowledge() {
    local existing="$1"
    local new="$2"
    
    # Smart merge that preserves important data
    jq -n --argjson existing "$existing" --argjson new "$new" '
        {
            last_updated: $new.collection_timestamp,
            knowledge_version: $new.knowledge_version,
            patterns: {
                extracted: ($existing.patterns.extracted.patterns // [] + $new.patterns.extracted.patterns) | unique_by(.pattern_id // .),
                universal: ($existing.patterns.universal.patterns // [] + $new.patterns.universal.patterns) | unique_by(.pattern_id // .),
                library: ($existing.patterns.library.patterns // [] + $new.patterns.library.patterns) | unique_by(.pattern_id // .),
                metrics: $new.patterns.metrics  # Always use latest metrics
            },
            insights: {
                history: (($existing.insights.history // []) + [$new.insights]) | if length > 100 then .[-100:] else . end,
                current: $new.insights
            },
            evolution: $new.evolution,  # Evolution data is cumulative
            meta_learning: $new.meta_learning,  # Latest learning state
            operational: $new.operational,
            knowledge_stats: {
                total_updates: (($existing.knowledge_stats.total_updates // 0) + 1),
                patterns_tracked: ($new.patterns.extracted.patterns // [] + $new.patterns.universal.patterns // [] + $new.patterns.library.patterns // []) | length,
                last_checkpoint: $new.collection_timestamp
            }
        }
    '
}

# Function to export knowledge for transfer
export_knowledge() {
    local export_format="${1:-json}"
    local export_id="export_$(date +%s)"
    local export_file="$EXPORT_DIR/knowledge_${export_id}.${export_format}"
    
    log_persistence "INFO" "Exporting knowledge in $export_format format"
    
    # Collect current knowledge
    local knowledge=$(collect_learned_knowledge)
    
    case "$export_format" in
        "json")
            echo "$knowledge" | jq '.' > "$export_file"
            ;;
        "compressed")
            echo "$knowledge" | jq '.' | gzip -9 > "${export_file}.gz"
            export_file="${export_file}.gz"
            ;;
        "minimal")
            # Export only high-value patterns and key insights
            echo "$knowledge" | jq '{
                export_version: "1.0.0",
                exported_at: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
                high_value_patterns: [
                    .patterns.library.patterns[] |
                    select(.effectiveness_score >= 0.7 or .quality_score >= 0.7)
                ],
                key_insights: .insights.key_findings,
                learning_model: .meta_learning.learning_model,
                statistics: {
                    total_patterns: .patterns.total_patterns,
                    learning_iterations: .meta_learning.learning_iterations
                }
            }' > "$export_file"
            ;;
        *)
            log_persistence "ERROR" "Unknown export format: $export_format"
            return 1
            ;;
    esac
    
    log_persistence "INFO" "Knowledge exported to: $export_file"
    echo "$export_file"
}

# Function to import knowledge
import_knowledge() {
    local import_file="$1"
    
    if [ ! -f "$import_file" ]; then
        log_persistence "ERROR" "Import file not found: $import_file"
        return 1
    fi
    
    log_persistence "INFO" "Importing knowledge from: $import_file"
    
    # Decompress if needed
    local temp_file="$import_file"
    if [[ "$import_file" == *.gz ]]; then
        temp_file="/tmp/import_knowledge_$$.json"
        gunzip -c "$import_file" > "$temp_file"
    fi
    
    # Validate import data
    if ! jq -e '.' "$temp_file" > /dev/null 2>&1; then
        log_persistence "ERROR" "Invalid JSON in import file"
        [ "$temp_file" != "$import_file" ] && rm -f "$temp_file"
        return 1
    fi
    
    # Import patterns
    local imported_data=$(cat "$temp_file")
    import_patterns "$imported_data"
    import_insights "$imported_data"
    import_learning_model "$imported_data"
    
    # Clean up
    [ "$temp_file" != "$import_file" ] && rm -f "$temp_file"
    
    log_persistence "INFO" "Knowledge import completed"
}

# Function to import patterns
import_patterns() {
    local data="$1"
    local patterns_dir="${CLAUDE_HOME:-.claude}/patterns"
    
    # Import high-value patterns to library
    local patterns=$(echo "$data" | jq '.high_value_patterns // .patterns.library.patterns // []')
    local imported_count=0
    
    while IFS= read -r pattern; do
        local pattern_id=$(echo "$pattern" | jq -r '.pattern_id // ""')
        if [ -n "$pattern_id" ]; then
            echo "$pattern" | jq '.' > "$patterns_dir/library/imported_${pattern_id}.json"
            imported_count=$((imported_count + 1))
        fi
    done < <(echo "$patterns" | jq -c '.[]')
    
    log_persistence "INFO" "Imported $imported_count patterns"
}

# Function to import insights
import_insights() {
    local data="$1"
    local insights_dir="$LEARNING_DIR/meta/insights"
    
    mkdir -p "$insights_dir"
    
    # Import key insights
    local insights=$(echo "$data" | jq '.key_insights // .insights.current // {}')
    if [ "$(echo "$insights" | jq '. | length')" -gt 0 ]; then
        echo "$insights" | jq '.' > "$insights_dir/imported_$(date +%s).json"
        log_persistence "INFO" "Imported insights"
    fi
}

# Function to import learning model
import_learning_model() {
    local data="$1"
    local model=$(echo "$data" | jq '.learning_model // .meta_learning.learning_model // {}')
    
    if [ "$(echo "$model" | jq '. | length')" -gt 0 ]; then
        local model_file="$LEARNING_DIR/meta/learning-model.json"
        
        # Merge with existing model
        if [ -f "$model_file" ]; then
            local existing=$(cat "$model_file")
            model=$(jq -n --argjson existing "$existing" --argjson new "$model" '
                $existing * $new |
                .imported_at = now | strftime("%Y-%m-%dT%H:%M:%SZ")
            ')
        fi
        
        echo "$model" | jq '.' > "$model_file"
        log_persistence "INFO" "Imported learning model"
    fi
}

# Function to clean old data
clean_old_data() {
    log_persistence "INFO" "Cleaning old data (retention: $RETENTION_DAYS days)"
    
    # Clean old checkpoints
    find "$CHECKPOINT_DIR" -name "*.json*" -type f -mtime +$RETENTION_DAYS -delete
    
    # Clean old exports
    find "$EXPORT_DIR" -name "*" -type f -mtime +$RETENTION_DAYS -delete
    
    # Archive old insights
    local archive_dir="$LEARNING_DIR/archive"
    mkdir -p "$archive_dir"
    
    find "$LEARNING_DIR/meta/insights" -name "*.json" -type f -mtime +$RETENTION_DAYS -exec mv {} "$archive_dir/" \;
    
    log_persistence "INFO" "Cleanup completed"
}

# Function to verify knowledge integrity
verify_knowledge_integrity() {
    local knowledge_file="${1:-$KNOWLEDGE_BASE}"
    
    if [ ! -f "$knowledge_file" ]; then
        log_persistence "WARN" "Knowledge file not found: $knowledge_file"
        return 1
    fi
    
    # Check JSON validity
    if ! jq -e '.' "$knowledge_file" > /dev/null 2>&1; then
        log_persistence "ERROR" "Knowledge file has invalid JSON"
        return 1
    fi
    
    # Check required fields
    local required_fields=("patterns" "insights" "evolution" "meta_learning")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$knowledge_file" > /dev/null 2>&1; then
            log_persistence "ERROR" "Knowledge file missing required field: $field"
            return 1
        fi
    done
    
    log_persistence "INFO" "Knowledge integrity verified"
    return 0
}

# Function to generate persistence report
generate_persistence_report() {
    local report_file="$PERSISTENCE_DIR/persistence-report.json"
    
    cat <<EOF > "$report_file"
{
    "report_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "knowledge_base": {
        "exists": $([ -f "$KNOWLEDGE_BASE" ] && echo "true" || echo "false"),
        "last_updated": $([ -f "$KNOWLEDGE_BASE" ] && jq -r '.last_updated // "unknown"' "$KNOWLEDGE_BASE" || echo '"never"'),
        "size_mb": $([ -f "$KNOWLEDGE_BASE" ] && du -m "$KNOWLEDGE_BASE" | cut -f1 || echo "0")
    },
    "checkpoints": {
        "total": $(find "$CHECKPOINT_DIR" -name "checkpoint_*" -type f | wc -l),
        "compressed": $(find "$CHECKPOINT_DIR" -name "*.gz" -type f | wc -l),
        "latest": $(find "$CHECKPOINT_DIR" -name "checkpoint_*.json" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2- | xargs basename 2>/dev/null || echo "none")
    },
    "exports": {
        "total": $(find "$EXPORT_DIR" -name "*" -type f | wc -l),
        "formats": $(find "$EXPORT_DIR" -name "*" -type f | sed 's/.*\.//' | sort -u | jq -R . | jq -s .)
    },
    "storage_usage_mb": $(du -sm "$PERSISTENCE_DIR" | cut -f1),
    "data_age": {
        "oldest_checkpoint_days": $(find "$CHECKPOINT_DIR" -name "checkpoint_*" -type f -printf '%T@\n' | sort -n | head -1 | xargs -I {} awk -v old={} -v now=$(date +%s) 'BEGIN { print int((now - old) / 86400) }' || echo "0"),
        "newest_checkpoint_days": $(find "$CHECKPOINT_DIR" -name "checkpoint_*" -type f -printf '%T@\n' | sort -n | tail -1 | xargs -I {} awk -v new={} -v now=$(date +%s) 'BEGIN { print int((now - new) / 86400) }' || echo "0")
    }
}
EOF
}

# Main persistence logic
main() {
    local action="${1:-persist}"
    
    case "$action" in
        "persist")
            log_persistence "INFO" "Starting knowledge persistence"
            
            # Collect all learned knowledge
            local knowledge=$(collect_learned_knowledge)
            
            # Create checkpoint
            create_knowledge_checkpoint "$knowledge"
            
            # Update knowledge base
            update_knowledge_base "$knowledge"
            
            # Clean old data
            clean_old_data
            
            # Verify integrity
            verify_knowledge_integrity
            
            # Generate report
            generate_persistence_report
            
            log_persistence "INFO" "Knowledge persistence completed"
            ;;
            
        "export")
            local format="${2:-json}"
            export_knowledge "$format"
            ;;
            
        "import")
            local file="${2:-}"
            if [ -z "$file" ]; then
                log_persistence "ERROR" "Import file required"
                exit 1
            fi
            import_knowledge "$file"
            ;;
            
        "verify")
            verify_knowledge_integrity
            ;;
            
        "report")
            generate_persistence_report
            cat "$PERSISTENCE_DIR/persistence-report.json"
            ;;
            
        *)
            echo "Usage: $0 [persist|export|import|verify|report]"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"