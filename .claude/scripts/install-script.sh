#!/bin/bash

# MetaClaude Script Registry - Installation Tool
# Link scripts from the registry to specialist directories

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Registry file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_FILE="${SCRIPT_DIR}/registry.json"
IMPLEMENTATIONS_DIR="$(dirname "$SCRIPT_DIR")/implementations"

# Parameters
SCRIPT_ID=""
SPECIALIST=""
LINK_NAME=""
FORCE=false
LIST_ONLY=false

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Link scripts from the global registry to specialist directories.

Options:
    --script-id ID         Script ID from the registry
    --specialist NAME      Target specialist to install for
    --link-name NAME       Custom name for the symlink (optional)
    --force               Overwrite existing links
    --list                List all installed scripts for a specialist
    -h, --help           Show this help message

Examples:
    # Install a script for a specialist
    $0 --script-id "validation/json-schema-validator" --specialist "api-ui-designer"

    # Install with custom link name
    $0 --script-id "data/csv-to-json" --specialist "data-scientist" --link-name "csv-converter"

    # Force overwrite existing link
    $0 --script-id "analysis/code-complexity" --specialist "qa-engineer" --force

    # List installed scripts for a specialist
    $0 --specialist "data-scientist" --list

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --script-id)
            SCRIPT_ID="$2"
            shift 2
            ;;
        --specialist)
            SPECIALIST="$2"
            shift 2
            ;;
        --link-name)
            LINK_NAME="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --list)
            LIST_ONLY=true
            shift
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

# Function to get all available specialists
get_available_specialists() {
    if [[ -d "$IMPLEMENTATIONS_DIR" ]]; then
        find "$IMPLEMENTATIONS_DIR" -maxdepth 1 -type d -not -path "$IMPLEMENTATIONS_DIR" -exec basename {} \; | sort
    fi
}

# Function to list installed scripts for a specialist
list_installed_scripts() {
    local specialist="$1"
    local specialist_scripts_dir="$IMPLEMENTATIONS_DIR/$specialist/scripts"
    
    if [[ ! -d "$specialist_scripts_dir" ]]; then
        echo -e "${YELLOW}No scripts directory found for $specialist${NC}"
        return
    fi
    
    echo -e "${BLUE}Installed scripts for $specialist:${NC}"
    echo
    
    local found=false
    
    # Find all symlinks in the scripts directory
    while IFS= read -r -d '' link; do
        if [[ -L "$link" ]]; then
            found=true
            local link_name=$(basename "$link")
            local target=$(readlink "$link")
            local script_id=""
            
            # Try to find the script ID from the target path
            if [[ "$target" =~ scripts/(.+)$ ]]; then
                # Extract the relative path after "scripts/"
                local rel_path="${BASH_REMATCH[1]}"
                # Look up the script ID in the registry
                script_id=$(jq -r ".scripts[] | select(.path == \"scripts/$rel_path\") | .id" "$REGISTRY_FILE" 2>/dev/null || echo "")
            fi
            
            if [[ -n "$script_id" ]]; then
                # Get script details from registry
                local script_info=$(jq -r ".scripts[] | select(.id == \"$script_id\")" "$REGISTRY_FILE")
                local name=$(echo "$script_info" | jq -r '.name')
                local description=$(echo "$script_info" | jq -r '.description' | cut -c1-50)
                
                if [[ ${#description} -eq 50 ]]; then
                    description="${description}..."
                fi
                
                printf "  ${GREEN}%-20s${NC} → %-30s %s\n" "$link_name" "$name" "$description"
            else
                printf "  ${GREEN}%-20s${NC} → %s\n" "$link_name" "$target"
            fi
        fi
    done < <(find "$specialist_scripts_dir" -maxdepth 1 -type l -print0 2>/dev/null)
    
    if [[ "$found" == false ]]; then
        echo "  No scripts installed"
    fi
}

# List mode
if [[ "$LIST_ONLY" == true ]]; then
    if [[ -z "$SPECIALIST" ]]; then
        # List all specialists with installed scripts
        echo -e "${BLUE}Specialists with installed scripts:${NC}"
        echo
        
        for spec in $(get_available_specialists); do
            local scripts_dir="$IMPLEMENTATIONS_DIR/$spec/scripts"
            if [[ -d "$scripts_dir" ]] && [[ -n "$(find "$scripts_dir" -maxdepth 1 -type l 2>/dev/null)" ]]; then
                list_installed_scripts "$spec"
                echo
            fi
        done
    else
        # List scripts for specific specialist
        if [[ ! -d "$IMPLEMENTATIONS_DIR/$SPECIALIST" ]]; then
            echo -e "${RED}Error: Specialist '$SPECIALIST' not found${NC}"
            echo "Available specialists:"
            get_available_specialists | sed 's/^/  - /'
            exit 1
        fi
        
        list_installed_scripts "$SPECIALIST"
    fi
    exit 0
fi

# Validate required arguments for installation
if [[ -z "$SCRIPT_ID" ]] || [[ -z "$SPECIALIST" ]]; then
    echo -e "${RED}Error: Both --script-id and --specialist are required for installation${NC}"
    usage
fi

# Check if specialist exists
if [[ ! -d "$IMPLEMENTATIONS_DIR/$SPECIALIST" ]]; then
    echo -e "${RED}Error: Specialist '$SPECIALIST' not found${NC}"
    echo "Available specialists:"
    get_available_specialists | sed 's/^/  - /'
    exit 1
fi

# Get script details from registry
SCRIPT_INFO=$(jq ".scripts[] | select(.id == \"$SCRIPT_ID\")" "$REGISTRY_FILE" 2>/dev/null)

if [[ -z "$SCRIPT_INFO" ]]; then
    echo -e "${RED}Error: Script with ID '$SCRIPT_ID' not found in registry${NC}"
    echo "Use ./search-scripts.sh to find available scripts"
    exit 1
fi

# Extract script details
SCRIPT_NAME=$(echo "$SCRIPT_INFO" | jq -r '.name')
SCRIPT_PATH=$(echo "$SCRIPT_INFO" | jq -r '.path')
SCRIPT_CATEGORY=$(echo "$SCRIPT_INFO" | jq -r '.category')
SCRIPT_SPECIALISTS=$(echo "$SCRIPT_INFO" | jq -r '.specialists[]?' 2>/dev/null)

# Check if script is compatible with the specialist
if [[ -n "$SCRIPT_SPECIALISTS" ]] && ! echo "$SCRIPT_SPECIALISTS" | grep -q "^$SPECIALIST$"; then
    echo -e "${YELLOW}Warning: Script '$SCRIPT_NAME' is not explicitly compatible with '$SPECIALIST'${NC}"
    echo "Compatible specialists: $(echo "$SCRIPT_SPECIALISTS" | tr '\n' ', ' | sed 's/, $//')"
    echo
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Determine link name
if [[ -z "$LINK_NAME" ]]; then
    # Use script filename without extension as default link name
    LINK_NAME=$(basename "$SCRIPT_PATH" | sed 's/\.[^.]*$//')
fi

# Create scripts directory if it doesn't exist
SPECIALIST_SCRIPTS_DIR="$IMPLEMENTATIONS_DIR/$SPECIALIST/scripts"
if [[ ! -d "$SPECIALIST_SCRIPTS_DIR" ]]; then
    echo -e "${YELLOW}Creating scripts directory for $SPECIALIST...${NC}"
    mkdir -p "$SPECIALIST_SCRIPTS_DIR"
fi

# Determine source and target paths
SOURCE_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
TARGET_PATH="$SPECIALIST_SCRIPTS_DIR/$LINK_NAME"

# Check if source script exists
if [[ ! -f "$SOURCE_PATH" ]]; then
    echo -e "${RED}Error: Script file not found at $SOURCE_PATH${NC}"
    echo "The script may not have been created yet."
    exit 1
fi

# Check if target already exists
if [[ -e "$TARGET_PATH" ]] && [[ "$FORCE" != true ]]; then
    echo -e "${RED}Error: Link already exists at $TARGET_PATH${NC}"
    echo "Use --force to overwrite"
    exit 1
fi

# Create the symlink
echo -e "${GREEN}Installing script...${NC}"
ln -sf "$SOURCE_PATH" "$TARGET_PATH"

# Make the script executable
chmod +x "$SOURCE_PATH"

# Verify the link was created
if [[ -L "$TARGET_PATH" ]]; then
    echo -e "${GREEN}✓ Script installed successfully!${NC}"
    echo
    echo "Script: $SCRIPT_NAME"
    echo "Specialist: $SPECIALIST"
    echo "Link: $TARGET_PATH → $SOURCE_PATH"
    echo
    echo -e "${BLUE}Usage in specialist workflows:${NC}"
    echo "  action: use_tool"
    echo "  tool_id: \"$SCRIPT_ID\""
    echo
    echo -e "${BLUE}Direct execution:${NC}"
    echo "  $TARGET_PATH [arguments]"
else
    echo -e "${RED}Error: Failed to create symlink${NC}"
    exit 1
fi