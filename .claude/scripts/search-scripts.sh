#!/bin/bash

# MetaClaude Script Registry - Search Tool
# Search and discover scripts in the global registry

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Registry file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_FILE="${SCRIPT_DIR}/registry.json"

# Search parameters
CATEGORY=""
SPECIALIST=""
TAGS=""
NAME=""
SHOW_DETAILS=false
OUTPUT_FORMAT="human"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Search for scripts in the MetaClaude Global Script Registry.

Options:
    --category CATEGORY      Filter by category (core|data|analysis|validation|generation|integration)
    --specialist SPECIALIST  Filter by compatible specialist
    --tags TAG1,TAG2        Filter by tags (comma-separated)
    --name NAME             Search by name (partial match)
    --details               Show detailed information for each script
    --format FORMAT         Output format: human|json|csv (default: human)
    -h, --help             Show this help message

Examples:
    # Find all validation scripts
    $0 --category validation

    # Find scripts for the QA Engineer specialist
    $0 --specialist qa-engineer

    # Find scripts tagged with 'json' and 'validation'
    $0 --tags json,validation

    # Search by name with details
    $0 --name "validator" --details

    # Get JSON output for integration
    $0 --specialist data-scientist --format json

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --specialist)
            SPECIALIST="$2"
            shift 2
            ;;
        --tags)
            TAGS="$2"
            shift 2
            ;;
        --name)
            NAME="$2"
            shift 2
            ;;
        --details)
            SHOW_DETAILS=true
            shift
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Check if registry file exists
if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo -e "${RED}Error: Registry file not found at $REGISTRY_FILE${NC}"
    exit 1
fi

# Build jq filter
JQ_FILTER=".scripts[]"

# Add category filter
if [[ -n "$CATEGORY" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.category == \"$CATEGORY\")"
fi

# Add specialist filter
if [[ -n "$SPECIALIST" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.specialists[]? == \"$SPECIALIST\")"
fi

# Add name filter (case-insensitive partial match)
if [[ -n "$NAME" ]]; then
    JQ_FILTER="$JQ_FILTER | select(.name | ascii_downcase | contains(\"$(echo $NAME | tr '[:upper:]' '[:lower:]')\"))"
fi

# Add tags filter
if [[ -n "$TAGS" ]]; then
    IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
    for tag in "${TAG_ARRAY[@]}"; do
        JQ_FILTER="$JQ_FILTER | select(.tags[]? == \"$tag\")"
    done
fi

# Function to format script details
format_script_details() {
    local script="$1"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$(echo "$script" | jq -r '.name')${NC}"
    echo -e "${CYAN}ID:${NC} $(echo "$script" | jq -r '.id')"
    echo -e "${CYAN}Category:${NC} $(echo "$script" | jq -r '.category')"
    echo -e "${CYAN}Description:${NC} $(echo "$script" | jq -r '.description')"
    echo -e "${CYAN}Version:${NC} $(echo "$script" | jq -r '.version')"
    
    # Specialists
    local specialists=$(echo "$script" | jq -r '.specialists[]?' 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
    if [[ -n "$specialists" ]]; then
        echo -e "${CYAN}Specialists:${NC} $specialists"
    fi
    
    # Tags
    local tags=$(echo "$script" | jq -r '.tags[]?' 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
    if [[ -n "$tags" ]]; then
        echo -e "${CYAN}Tags:${NC} $tags"
    fi
    
    # Dependencies
    local deps=$(echo "$script" | jq -r '.dependencies[]?' 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
    if [[ -n "$deps" ]]; then
        echo -e "${CYAN}Dependencies:${NC} $deps"
    fi
    
    if [[ "$SHOW_DETAILS" == true ]]; then
        echo
        echo -e "${YELLOW}Execution Details:${NC}"
        echo -e "  Type: $(echo "$script" | jq -r '.execution.type')"
        echo -e "  Timeout: $(echo "$script" | jq -r '.execution.timeout')ms"
        echo -e "  Sandbox: $(echo "$script" | jq -r '.security.sandbox')"
        echo -e "  Max Memory: $(echo "$script" | jq -r '.security.max_memory')"
        echo -e "  Network Access: $(echo "$script" | jq -r '.security.network_access')"
        
        # Arguments
        local args=$(echo "$script" | jq -r '.execution.args[]?' 2>/dev/null)
        if [[ -n "$args" ]]; then
            echo
            echo -e "${YELLOW}Arguments:${NC}"
            echo "$script" | jq -r '.execution.args[] | "  - \(.name) (\(.type)): \(.description) [\(if .required then "required" else "optional" end)]"'
        fi
        
        # Outputs
        local outputs=$(echo "$script" | jq -r '.outputs[]?' 2>/dev/null)
        if [[ -n "$outputs" ]]; then
            echo
            echo -e "${YELLOW}Outputs:${NC}"
            echo "$script" | jq -r '.outputs[] | "  - \(.name) (\(.type)): \(.description)"'
        fi
    fi
}

# Function to format script summary
format_script_summary() {
    local script="$1"
    local id=$(echo "$script" | jq -r '.id')
    local name=$(echo "$script" | jq -r '.name')
    local category=$(echo "$script" | jq -r '.category')
    local description=$(echo "$script" | jq -r '.description' | cut -c1-50)
    
    if [[ ${#description} -eq 50 ]]; then
        description="${description}..."
    fi
    
    printf "%-30s %-25s %-15s %s\n" "$id" "$name" "$category" "$description"
}

# Execute search and format output
case "$OUTPUT_FORMAT" in
    json)
        # Raw JSON output
        jq "[$JQ_FILTER]" "$REGISTRY_FILE"
        ;;
    
    csv)
        # CSV output
        echo "ID,Name,Category,Description,Version,Specialists,Tags"
        jq -r "$JQ_FILTER | [.id, .name, .category, .description, .version, (.specialists | join(\";\")), (.tags | join(\";\"))] | @csv" "$REGISTRY_FILE"
        ;;
    
    human)
        # Human-readable output
        RESULTS=$(jq -c "[$JQ_FILTER]" "$REGISTRY_FILE")
        COUNT=$(echo "$RESULTS" | jq 'length')
        
        if [[ $COUNT -eq 0 ]]; then
            echo -e "${YELLOW}No scripts found matching your criteria.${NC}"
            exit 0
        fi
        
        echo -e "${GREEN}Found $COUNT script(s):${NC}"
        echo
        
        if [[ "$SHOW_DETAILS" == true ]]; then
            # Detailed view
            echo "$RESULTS" | jq -c '.[]' | while read -r script; do
                format_script_details "$script"
                echo
            done
        else
            # Summary view
            printf "${CYAN}%-30s %-25s %-15s %s${NC}\n" "ID" "Name" "Category" "Description"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            echo "$RESULTS" | jq -c '.[]' | while read -r script; do
                format_script_summary "$script"
            done
            
            echo
            echo -e "${YELLOW}Tip: Use --details to see more information about each script${NC}"
        fi
        ;;
    
    *)
        echo -e "${RED}Error: Unknown output format '$OUTPUT_FORMAT'${NC}"
        exit 1
        ;;
esac