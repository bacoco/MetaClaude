#!/bin/bash

# MetaClaude Script Registry - Tool Execution Wrapper
# Execute registered scripts through the Tool Execution Service (TES)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TES_PATH="${SCRIPT_DIR}/core/tool-execution-service.py"
REGISTRY_FILE="${SCRIPT_DIR}/registry.json"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not found${NC}"
    exit 1
fi

# Check if TES exists
if [[ ! -f "$TES_PATH" ]]; then
    echo -e "${RED}Error: Tool Execution Service not found at $TES_PATH${NC}"
    exit 1
fi

# Make TES executable
chmod +x "$TES_PATH"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 SCRIPT_ID [OPTIONS]

Execute a registered script through the Tool Execution Service (TES).

Arguments:
    SCRIPT_ID              The ID of the script to execute

Options:
    --arg KEY=VALUE        Provide script arguments (can be used multiple times)
    --json                 Output result in JSON format
    --dry-run             Show what would be executed without running
    --show-info           Display script information before execution
    -h, --help           Show this help message

Examples:
    # Execute a validation script
    $0 validation/json-schema-validator --arg schema_path=./schema.json --arg data_path=./data.json

    # Execute with JSON output
    $0 data/csv-to-json --arg input_file=data.csv --json

    # Show script info before running
    $0 analysis/code-complexity --show-info --arg source_path=./src --arg language=javascript

    # Complex arguments (JSON)
    $0 generation/api-mock --arg 'schema={"type":"object","properties":{"id":{"type":"string"}}}' --arg count=5

EOF
    exit 0
}

# Parameters
SCRIPT_ID=""
ARGS=()
JSON_OUTPUT=false
DRY_RUN=false
SHOW_INFO=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --arg)
            ARGS+=("--arg" "$2")
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            ARGS+=("--json")
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --show-info)
            SHOW_INFO=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
        *)
            if [[ -z "$SCRIPT_ID" ]]; then
                SCRIPT_ID="$1"
            else
                echo -e "${RED}Error: Multiple script IDs provided${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# Validate script ID
if [[ -z "$SCRIPT_ID" ]]; then
    echo -e "${RED}Error: Script ID is required${NC}"
    usage
fi

# Function to show script information
show_script_info() {
    local script_info=$(jq ".scripts[] | select(.id == \"$SCRIPT_ID\")" "$REGISTRY_FILE" 2>/dev/null)
    
    if [[ -z "$script_info" ]]; then
        echo -e "${RED}Error: Script '$SCRIPT_ID' not found in registry${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Script Information:${NC}"
    echo -e "  ID: $(echo "$script_info" | jq -r '.id')"
    echo -e "  Name: $(echo "$script_info" | jq -r '.name')"
    echo -e "  Description: $(echo "$script_info" | jq -r '.description')"
    echo -e "  Category: $(echo "$script_info" | jq -r '.category')"
    echo -e "  Version: $(echo "$script_info" | jq -r '.version')"
    
    # Show arguments
    local args=$(echo "$script_info" | jq -r '.execution.args[]?' 2>/dev/null)
    if [[ -n "$args" ]]; then
        echo -e "\n${YELLOW}Arguments:${NC}"
        echo "$script_info" | jq -r '.execution.args[] | "  \(.name) (\(.type)): \(.description) [\(if .required then "required" else "optional" end)]"'
    fi
    
    # Show outputs
    local outputs=$(echo "$script_info" | jq -r '.outputs[]?' 2>/dev/null)
    if [[ -n "$outputs" ]]; then
        echo -e "\n${YELLOW}Outputs:${NC}"
        echo "$script_info" | jq -r '.outputs[] | "  \(.name) (\(.type)): \(.description)"'
    fi
    
    # Show security settings
    echo -e "\n${YELLOW}Security:${NC}"
    echo -e "  Sandbox: $(echo "$script_info" | jq -r '.security.sandbox')"
    echo -e "  Max Memory: $(echo "$script_info" | jq -r '.security.max_memory')"
    echo -e "  Network Access: $(echo "$script_info" | jq -r '.security.network_access')"
    echo -e "  Timeout: $(echo "$script_info" | jq -r '.execution.timeout')ms"
}

# Show script info if requested
if [[ "$SHOW_INFO" == true ]]; then
    show_script_info
    echo
fi

# Build command
CMD=("python3" "$TES_PATH" "$SCRIPT_ID" "--registry" "$REGISTRY_FILE")
CMD+=("${ARGS[@]}")

# Dry run mode
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run mode - would execute:${NC}"
    echo "${CMD[@]}"
    exit 0
fi

# Execute through TES
if [[ "$JSON_OUTPUT" == false ]]; then
    echo -e "${GREEN}Executing script: $SCRIPT_ID${NC}"
    echo
fi

# Run the command
"${CMD[@]}"