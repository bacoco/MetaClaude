#!/bin/bash

# Auto-register tools created by Tool Builder
# This script is called automatically after tool generation

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTER_SCRIPT="${SCRIPT_DIR}/../register-script.sh"

# Check arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <tool_path> <metadata_file>"
    echo "  tool_path: Path to the generated tool"
    echo "  metadata_file: JSON file with tool metadata"
    exit 1
fi

TOOL_PATH="$1"
METADATA_FILE="$2"

# Validate inputs
if [[ ! -f "$TOOL_PATH" ]]; then
    echo -e "${RED}Error: Tool file not found: $TOOL_PATH${NC}"
    exit 1
fi

if [[ ! -f "$METADATA_FILE" ]]; then
    echo -e "${RED}Error: Metadata file not found: $METADATA_FILE${NC}"
    exit 1
fi

# Make tool executable
chmod +x "$TOOL_PATH"

# Extract metadata
METADATA=$(cat "$METADATA_FILE")

# Extract required fields
NAME=$(echo "$METADATA" | jq -r '.name // empty')
DESCRIPTION=$(echo "$METADATA" | jq -r '.description // empty')
PURPOSE=$(echo "$METADATA" | jq -r '.purpose // ""')
SPECIALISTS=$(echo "$METADATA" | jq -r '.specialists[]? // empty' | tr '\n' ',' | sed 's/,$//')
DEPENDENCIES=$(echo "$METADATA" | jq -r '.dependencies[]? // empty' | tr '\n' ',' | sed 's/,$//')
TIMEOUT=$(echo "$METADATA" | jq -r '.timeout // 30000')
MAX_MEMORY=$(echo "$METADATA" | jq -r '.maxMemory // "512MB"')

# Validate required fields
if [[ -z "$NAME" ]] || [[ -z "$DESCRIPTION" ]]; then
    echo -e "${RED}Error: Metadata must include 'name' and 'description'${NC}"
    exit 1
fi

# Determine category from purpose
determine_category() {
    local purpose="$1"
    local purpose_lower=$(echo "$purpose" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$purpose_lower" =~ validate|check|verify|ensure ]]; then
        echo "validation"
    elif [[ "$purpose_lower" =~ convert|transform|process|parse ]]; then
        echo "data"
    elif [[ "$purpose_lower" =~ analyze|examine|inspect|measure ]]; then
        echo "analysis"
    elif [[ "$purpose_lower" =~ generate|create|build|scaffold ]]; then
        echo "generation"
    elif [[ "$purpose_lower" =~ connect|integrate|sync|api ]]; then
        echo "integration"
    else
        echo "core"
    fi
}

CATEGORY=$(determine_category "$PURPOSE")

# Generate tags
generate_tags() {
    local name="$1"
    local purpose="$2"
    local tags=""
    
    # Add language tag
    local extension="${TOOL_PATH##*.}"
    case "$extension" in
        py) tags="python" ;;
        sh) tags="bash,shell" ;;
        js) tags="javascript,node" ;;
    esac
    
    # Add purpose-based tags
    if [[ "$purpose" =~ json ]]; then tags="$tags,json"; fi
    if [[ "$purpose" =~ xml ]]; then tags="$tags,xml"; fi
    if [[ "$purpose" =~ csv ]]; then tags="$tags,csv"; fi
    if [[ "$purpose" =~ api ]]; then tags="$tags,api"; fi
    if [[ "$purpose" =~ test ]]; then tags="$tags,testing"; fi
    
    # Add tool-builder tag
    tags="$tags,tool-builder-generated"
    
    # Clean up tags
    echo "$tags" | sed 's/^,//' | sed 's/,$//'
}

TAGS=$(generate_tags "$NAME" "$PURPOSE")

# Calculate relative path for registry
TOOL_RELATIVE_PATH=$(realpath --relative-to="$(dirname "$REGISTER_SCRIPT")" "$TOOL_PATH")

# Extract arguments from metadata
ARGS=$(echo "$METADATA" | jq -r '.arguments[]? | "--arg \(.name):\(.type):\(.required // false):\(.description)"' | tr '\n' ' ')

# Extract outputs from metadata
OUTPUTS=$(echo "$METADATA" | jq -r '.outputs[]? | "--output \(.name):\(.type):\(.description)"' | tr '\n' ' ')

# Build registration command
echo -e "${GREEN}Registering tool in global registry...${NC}"
echo "Name: $NAME"
echo "Category: $CATEGORY"
echo "Path: $TOOL_RELATIVE_PATH"

# Build the command
CMD=("$REGISTER_SCRIPT"
    "--name" "$NAME"
    "--category" "$CATEGORY"
    "--path" "$TOOL_RELATIVE_PATH"
    "--description" "$DESCRIPTION"
    "--timeout" "$TIMEOUT"
    "--max-memory" "$MAX_MEMORY"
)

# Add optional fields
if [[ -n "$SPECIALISTS" ]]; then
    CMD+=("--specialists" "$SPECIALISTS")
fi

if [[ -n "$DEPENDENCIES" ]]; then
    CMD+=("--dependencies" "$DEPENDENCIES")
fi

if [[ -n "$TAGS" ]]; then
    CMD+=("--tags" "$TAGS")
fi

# Add arguments if present
if [[ -n "$ARGS" ]]; then
    eval "CMD+=($ARGS)"
fi

# Add outputs if present
if [[ -n "$OUTPUTS" ]]; then
    eval "CMD+=($OUTPUTS)"
fi

# Execute registration
if "${CMD[@]}"; then
    echo -e "${GREEN}✓ Tool successfully registered!${NC}"
    
    # Notify specialists if specified
    if [[ -n "$SPECIALISTS" ]]; then
        echo -e "${YELLOW}Tool is now available to: $SPECIALISTS${NC}"
    fi
    
    # Create success indicator
    echo "success=true"
    echo "category=$CATEGORY"
    echo "specialists=$SPECIALISTS"
else
    echo -e "${RED}Failed to register tool${NC}"
    echo "success=false"
    exit 1
fi