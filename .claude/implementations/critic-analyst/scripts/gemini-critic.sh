#!/bin/bash
# gemini-critic.sh - Gemini CLI wrapper for analysis-only mode

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECIALIST_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$SPECIALIST_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure Gemini never creates code
ANALYSIS_ONLY_PROMPT="You are a code analyst and critic. You must ONLY analyze, review, and provide feedback. Never generate, create, or write implementation code. Your role is to:
1. Identify issues and vulnerabilities
2. Assess quality and structure
3. Provide conceptual suggestions
4. Explain problems and their impact

Always describe what should be improved without showing how to implement it."

# Function to display usage
usage() {
    cat << EOF
Usage: $(basename "$0") <command> [options]

Commands:
    analyze <file>      Comprehensive code analysis
    audit <project>     Security-focused audit
    review <file>       Architecture and design review
    compare <v1> <v2>   Compare two versions
    help               Show this help message

Options:
    --agent <name>     Specific agent to use
    --focus <area>     Focus area (security, performance, etc.)
    --output <file>    Output file (default: stdout)
    --comprehensive    Run all agents
    --json            Output in JSON format

Examples:
    $(basename "$0") analyze src/auth.js
    $(basename "$0") audit . --focus security
    $(basename "$0") compare v1.js v2.js --output comparison.md

EOF
    exit 1
}

# Function to ensure analysis-only output
enforce_analysis_only() {
    local prompt="$1"
    echo "$ANALYSIS_ONLY_PROMPT

$prompt"
}

# Function to run analysis
run_analysis() {
    local file="$1"
    local agent="${2:-code-critic}"
    local output="${3:-}"
    
    echo -e "${BLUE}🔍 Running analysis with $agent...${NC}"
    
    # Build the analysis prompt
    local prompt=$(cat << EOF
Analyze the following code file: $file

Focus on:
- Code quality and structure
- Potential bugs and issues
- Security vulnerabilities
- Performance concerns
- Best practices compliance

Provide a detailed report with findings categorized by severity.
EOF
)
    
    # Run Gemini with enforced constraints
    local full_prompt=$(enforce_analysis_only "$prompt")
    
    if [[ -z "$output" ]]; then
        npx @google/gemini-cli "$full_prompt" --file "$file"
    else
        npx @google/gemini-cli "$full_prompt" --file "$file" > "$output"
        echo -e "${GREEN}✓ Analysis saved to: $output${NC}"
    fi
}

# Function to run security audit
run_audit() {
    local project="$1"
    local output="${2:-}"
    
    echo -e "${BLUE}🔒 Running security audit...${NC}"
    
    local prompt=$(cat << EOF
Perform a comprehensive security audit of this project.

Check for:
- OWASP Top 10 vulnerabilities
- Authentication and authorization issues
- Data protection problems
- Configuration security
- Dependency vulnerabilities

Categorize findings by severity and provide remediation guidance.
EOF
)
    
    local full_prompt=$(enforce_analysis_only "$prompt")
    
    # Create output directory
    local audit_dir="$REPORTS_DIR/audits/${TIMESTAMP}_audit"
    mkdir -p "$audit_dir"
    
    # Run audit on key files
    find "$project" -type f \( -name "*.js" -o -name "*.py" -o -name "*.java" \) | while read -r file; do
        local relative_path="${file#$project/}"
        local report_file="$audit_dir/${relative_path//\//_}.md"
        
        echo -e "${YELLOW}  Auditing: $relative_path${NC}"
        npx @google/gemini-cli "$full_prompt" --file "$file" > "$report_file"
    done
    
    echo -e "${GREEN}✓ Audit complete: $audit_dir${NC}"
}

# Function to compare versions
run_compare() {
    local file1="$1"
    local file2="$2"
    local output="${3:-}"
    
    echo -e "${BLUE}📊 Comparing versions...${NC}"
    
    local prompt=$(cat << EOF
Compare these two code versions and identify:
- What has improved
- What has gotten worse
- New issues introduced
- Issues that were fixed
- Overall quality change

Provide a detailed comparison report.
EOF
)
    
    local full_prompt=$(enforce_analysis_only "$prompt")
    
    if [[ -z "$output" ]]; then
        npx @google/gemini-cli "$full_prompt" --file "$file1" --file "$file2"
    else
        npx @google/gemini-cli "$full_prompt" --file "$file1" --file "$file2" > "$output"
        echo -e "${GREEN}✓ Comparison saved to: $output${NC}"
    fi
}

# Function to run comprehensive analysis
run_comprehensive() {
    local file="$1"
    local output_dir="$REPORTS_DIR/analyses/${TIMESTAMP}_comprehensive"
    
    mkdir -p "$output_dir"
    
    echo -e "${BLUE}🔍 Running comprehensive analysis...${NC}"
    
    # Run all agents
    local agents=("code-critic" "security-auditor" "performance-analyst" "architecture-reviewer" "documentation-reviewer")
    
    for agent in "${agents[@]}"; do
        echo -e "${YELLOW}  Running $agent...${NC}"
        run_analysis "$file" "$agent" "$output_dir/$agent.md"
    done
    
    # Generate summary report
    echo -e "${BLUE}📋 Generating summary report...${NC}"
    cat > "$output_dir/summary.md" << EOF
# Comprehensive Analysis Summary
Date: $(date)
File: $file

## Analysis Results

EOF
    
    for report in "$output_dir"/*.md; do
        [[ "$report" == "$output_dir/summary.md" ]] && continue
        echo "### $(basename "$report" .md)" >> "$output_dir/summary.md"
        grep -E "(Score:|Critical:|High:)" "$report" >> "$output_dir/summary.md" || true
        echo "" >> "$output_dir/summary.md"
    done
    
    echo -e "${GREEN}✓ Comprehensive analysis complete: $output_dir${NC}"
}

# Main command processing
case "${1:-}" in
    analyze)
        shift
        [[ $# -lt 1 ]] && usage
        
        file="$1"
        agent="code-critic"
        output=""
        
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --agent) agent="$2"; shift 2 ;;
                --output) output="$2"; shift 2 ;;
                --comprehensive) 
                    run_comprehensive "$file"
                    exit 0
                    ;;
                *) echo "Unknown option: $1"; usage ;;
            esac
        done
        
        run_analysis "$file" "$agent" "$output"
        ;;
        
    audit)
        shift
        [[ $# -lt 1 ]] && usage
        
        project="$1"
        shift
        
        run_audit "$project"
        ;;
        
    review)
        shift
        [[ $# -lt 1 ]] && usage
        
        file="$1"
        output=""
        
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --output) output="$2"; shift 2 ;;
                *) echo "Unknown option: $1"; usage ;;
            esac
        done
        
        run_analysis "$file" "architecture-reviewer" "$output"
        ;;
        
    compare)
        shift
        [[ $# -lt 2 ]] && usage
        
        file1="$1"
        file2="$2"
        output=""
        
        shift 2
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --output) output="$2"; shift 2 ;;
                *) echo "Unknown option: $1"; usage ;;
            esac
        done
        
        run_compare "$file1" "$file2" "$output"
        ;;
        
    help|--help|-h)
        usage
        ;;
        
    *)
        echo -e "${RED}Error: Unknown command '${1:-}'${NC}"
        usage
        ;;
esac