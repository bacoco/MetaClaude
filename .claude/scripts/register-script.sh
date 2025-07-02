#!/bin/bash

# MetaClaude Script Registry - Registration Tool
# Registers new scripts in the global registry

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Registry file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_FILE="${SCRIPT_DIR}/registry.json"

# Default values
CATEGORY=""
TIMEOUT="30000"
SANDBOX="standard"
MAX_MEMORY="512MB"
NETWORK_ACCESS="false"
VERSION=""
DEPENDS_ON=""
CHANGELOG_ENTRY=""

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Register a new script in the MetaClaude Global Script Registry.

Required Options:
    --name NAME                 Human-readable name for the script
    --category CATEGORY         Category (core|data|analysis|validation|generation|integration)
    --path PATH                 Path to the script file (relative to scripts/)
    --description DESC          Brief description of what the script does

Optional Options:
    --id ID                     Unique identifier (default: generated from category/name)
    --specialists SPEC1,SPEC2   Comma-separated list of compatible specialists
    --dependencies DEP1:VER1,DEP2:VER2    Dependencies with version constraints (e.g., jq:>=1.6,pandas:^1.3.0)
    --depends-on SCRIPT1:VER1,SCRIPT2:VER2    Script dependencies with versions (e.g., core/utils:^1.0.0)
    --tags TAG1,TAG2           Comma-separated list of tags
    --timeout MS               Execution timeout in milliseconds (default: 30000)
    --sandbox LEVEL            Sandbox level: minimal|standard|strict|network (default: standard)
    --max-memory SIZE          Maximum memory allocation (default: 512MB)
    --network-access           Enable network access (default: false)
    --version VERSION          Script version (required for versioned scripts)
    --changelog DESC           Changelog entry for this version
    --example PATH             Path to example file

Script Argument Definition:
    --arg NAME:TYPE:REQUIRED:DESC    Define script arguments (can be used multiple times)
    
    Example: --arg "input_file:string:true:Input file path"
             --arg "format:string:false:Output format"

Script Output Definition:
    --output NAME:TYPE:DESC          Define script outputs (can be used multiple times)
    
    Example: --output "result:object:Processing result"
             --output "errors:array:List of errors"

Examples:
    # Register a simple validation script
    $0 --name "JSON Validator" \\
       --category validation \\
       --path "validation/json-validator.sh" \\
       --description "Validates JSON files" \\
       --specialists "api-ui-designer,data-scientist" \\
       --dependencies "jq:>=1.6" \\
       --arg "file:string:true:JSON file to validate"

    # Register a versioned script with dependencies
    $0 --name "Data Transformer" \\
       --category data \\
       --path "data/transformer-v2.py" \\
       --description "Transform data between formats" \\
       --version "2.0.0" \\
       --changelog "Added support for Parquet format, improved performance" \\
       --specialists "data-scientist" \\
       --dependencies "pandas:^1.3.0,numpy:~1.21.0,pyarrow:>=6.0.0" \\
       --depends-on "core/json-validator:^1.0.0,core/utils:~2.1.0" \\
       --timeout 60000 \\
       --max-memory "2GB" \\
       --arg "input:string:true:Input file" \\
       --arg "output:string:true:Output file" \\
       --arg "format:string:false:Output format" \\
       --output "records_processed:number:Number of records" \\
       --output "errors:array:Processing errors"

    # Register a patch version update
    $0 --name "API Mock Generator" \\
       --category generation \\
       --path "generation/api-mock-v2.0.2.js" \\
       --description "Generate realistic mock data for API endpoints" \\
       --version "2.0.2" \\
       --changelog "Fixed bug with nested array generation" \\
       --dependencies "faker:^8.0.0,json-schema-faker:^2.16.0" \\
       --arg "schema:object:true:OpenAPI/JSON Schema definition"

EOF
    exit 1
}

# Arrays to store arguments and outputs
declare -a ARGS
declare -a OUTPUTS

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            NAME="$2"
            shift 2
            ;;
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --path)
            SCRIPT_PATH="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --id)
            ID="$2"
            shift 2
            ;;
        --specialists)
            SPECIALISTS="$2"
            shift 2
            ;;
        --dependencies)
            DEPENDENCIES="$2"
            shift 2
            ;;
        --tags)
            TAGS="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --sandbox)
            SANDBOX="$2"
            shift 2
            ;;
        --max-memory)
            MAX_MEMORY="$2"
            shift 2
            ;;
        --network-access)
            NETWORK_ACCESS="true"
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --depends-on)
            DEPENDS_ON="$2"
            shift 2
            ;;
        --changelog)
            CHANGELOG_ENTRY="$2"
            shift 2
            ;;
        --example)
            EXAMPLE="$2"
            shift 2
            ;;
        --arg)
            ARGS+=("$2")
            shift 2
            ;;
        --output)
            OUTPUTS+=("$2")
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

# Validate required arguments
if [[ -z "$NAME" ]] || [[ -z "$CATEGORY" ]] || [[ -z "$SCRIPT_PATH" ]] || [[ -z "$DESCRIPTION" ]]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    usage
fi

# Validate category
VALID_CATEGORIES="core data analysis validation generation integration templates"
if [[ ! " $VALID_CATEGORIES " =~ " $CATEGORY " ]]; then
    echo -e "${RED}Error: Invalid category '$CATEGORY'${NC}"
    echo "Valid categories: $VALID_CATEGORIES"
    exit 1
fi

# Determine version - use 1.0.0 if not specified
if [[ -z "$VERSION" ]]; then
    VERSION="1.0.0"
    echo -e "${YELLOW}No version specified, using default: $VERSION${NC}"
fi

# Generate ID if not provided
if [[ -z "$ID" ]]; then
    # Convert name to lowercase and replace spaces with hyphens
    ID_SUFFIX=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    BASE_ID="${CATEGORY}/${ID_SUFFIX}"
    
    # Check if we should create a versioned ID
    if [[ "$VERSION" != "1.0.0" ]]; then
        ID="${BASE_ID}@${VERSION}"
    else
        ID="$BASE_ID"
    fi
else
    # If ID is provided with version, extract base ID
    if [[ "$ID" =~ @ ]]; then
        BASE_ID="${ID%@*}"
    else
        BASE_ID="$ID"
        # Add version to ID if version is not 1.0.0
        if [[ "$VERSION" != "1.0.0" ]]; then
            ID="${ID}@${VERSION}"
        fi
    fi
fi

# Check if script file exists
FULL_SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_PATH}"
if [[ ! -f "$FULL_SCRIPT_PATH" ]]; then
    echo -e "${YELLOW}Warning: Script file not found at $FULL_SCRIPT_PATH${NC}"
    echo "Make sure to create the script file before using it."
fi

# Determine script type from extension
case "${SCRIPT_PATH##*.}" in
    sh|bash)
        SCRIPT_TYPE="shell_script"
        INTERPRETER="/bin/bash"
        ;;
    py)
        SCRIPT_TYPE="python_script"
        INTERPRETER="/usr/bin/python3"
        ;;
    js)
        SCRIPT_TYPE="node_script"
        INTERPRETER="/usr/bin/node"
        ;;
    *)
        echo -e "${RED}Error: Unknown script type for extension .${SCRIPT_PATH##*.}${NC}"
        exit 1
        ;;
esac

# Build arguments JSON array
ARGS_JSON="["
for arg in "${ARGS[@]}"; do
    IFS=':' read -r arg_name arg_type arg_required arg_desc <<< "$arg"
    
    # Convert string boolean to actual boolean
    if [[ "$arg_required" == "true" ]]; then
        arg_required="true"
    else
        arg_required="false"
    fi
    
    if [[ ${#ARGS_JSON} -gt 1 ]]; then
        ARGS_JSON+=","
    fi
    
    ARGS_JSON+="{\"name\":\"$arg_name\",\"type\":\"$arg_type\",\"required\":$arg_required,\"description\":\"$arg_desc\"}"
done
ARGS_JSON+="]"

# Build outputs JSON array
OUTPUTS_JSON="["
for output in "${OUTPUTS[@]}"; do
    IFS=':' read -r out_name out_type out_desc <<< "$output"
    
    if [[ ${#OUTPUTS_JSON} -gt 1 ]]; then
        OUTPUTS_JSON+=","
    fi
    
    OUTPUTS_JSON+="{\"name\":\"$out_name\",\"type\":\"$out_type\",\"description\":\"$out_desc\"}"
done
OUTPUTS_JSON+="]"

# Build specialists array
SPECIALISTS_JSON="[]"
if [[ -n "$SPECIALISTS" ]]; then
    SPECIALISTS_JSON="[\"$(echo $SPECIALISTS | sed 's/,/","/g')\"]"
fi

# Build dependencies object (new format with version constraints)
DEPENDENCIES_JSON="{}"
if [[ -n "$DEPENDENCIES" ]]; then
    DEPENDENCIES_JSON="{"
    IFS=',' read -ra DEPS <<< "$DEPENDENCIES"
    first=true
    for dep in "${DEPS[@]}"; do
        if [[ ! $first ]]; then
            DEPENDENCIES_JSON+=","
        fi
        first=false
        
        # Parse dependency:version format
        if [[ "$dep" =~ : ]]; then
            dep_name="${dep%:*}"
            dep_version="${dep#*:}"
        else
            dep_name="$dep"
            dep_version="*"
        fi
        
        DEPENDENCIES_JSON+=" \"$dep_name\": \"$dep_version\""
    done
    DEPENDENCIES_JSON+=" }"
fi

# Build script dependencies object
SCRIPT_DEPENDENCIES_JSON="{}"
if [[ -n "$DEPENDS_ON" ]]; then
    SCRIPT_DEPENDENCIES_JSON="{"
    IFS=',' read -ra SCRIPT_DEPS <<< "$DEPENDS_ON"
    first=true
    for dep in "${SCRIPT_DEPS[@]}"; do
        if [[ ! $first ]]; then
            SCRIPT_DEPENDENCIES_JSON+=","
        fi
        first=false
        
        # Parse script:version format
        if [[ "$dep" =~ : ]]; then
            script_name="${dep%:*}"
            script_version="${dep#*:}"
        else
            script_name="$dep"
            script_version="^1.0.0"
        fi
        
        SCRIPT_DEPENDENCIES_JSON+=" \"$script_name\": \"$script_version\""
    done
    SCRIPT_DEPENDENCIES_JSON+=" }"
fi

# Build tags array
TAGS_JSON="[]"
if [[ -n "$TAGS" ]]; then
    TAGS_JSON="[\"$(echo $TAGS | sed 's/,/","/g')\"]"
fi

# Build examples array
EXAMPLES_JSON="[]"
if [[ -n "$EXAMPLE" ]]; then
    EXAMPLES_JSON="[\"$EXAMPLE\"]"
fi

# Determine required permissions based on script
PERMISSIONS="[]"
case "$SANDBOX" in
    minimal)
        PERMISSIONS='["read_file"]'
        ;;
    standard)
        PERMISSIONS='["read_file","write_file"]'
        ;;
    network)
        PERMISSIONS='["read_file","write_file","network"]'
        ;;
    strict)
        PERMISSIONS='[]'
        ;;
esac

# Build changelog JSON if provided
CHANGELOG_JSON="{}"
if [[ -n "$CHANGELOG_ENTRY" ]]; then
    CHANGELOG_JSON="{ \"$VERSION\": \"$CHANGELOG_ENTRY\" }"
fi

# Build the new script entry
NEW_SCRIPT=$(cat <<EOF
{
  "id": "$ID",
  "name": "$NAME",
  "category": "$CATEGORY",
  "path": "$SCRIPT_PATH",
  "description": "$DESCRIPTION",
  "execution": {
    "type": "$SCRIPT_TYPE",
    "interpreter": "$INTERPRETER",
    "args": $ARGS_JSON,
    "timeout": $TIMEOUT,
    "permissions": $PERMISSIONS
  },
  "outputs": $OUTPUTS_JSON,
  "specialists": $SPECIALISTS_JSON,
  "dependencies": $DEPENDENCIES_JSON,
EOF
)

# Add scriptDependencies if provided
if [[ -n "$DEPENDS_ON" ]]; then
    NEW_SCRIPT+="  \"scriptDependencies\": $SCRIPT_DEPENDENCIES_JSON,\n"
fi

NEW_SCRIPT+=$(cat <<EOF
  "version": "$VERSION",
EOF
)

# Add changelog if provided
if [[ -n "$CHANGELOG_ENTRY" ]]; then
    NEW_SCRIPT+="  \"changelog\": $CHANGELOG_JSON,\n"
fi

NEW_SCRIPT+=$(cat <<EOF
  "security": {
    "sandbox": "$SANDBOX",
    "max_memory": "$MAX_MEMORY",
    "network_access": $NETWORK_ACCESS
  },
  "examples": $EXAMPLES_JSON,
  "tags": $TAGS_JSON
}
EOF
)

# Check if script ID already exists
if jq -e ".scripts[] | select(.id == \"$ID\")" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo -e "${RED}Error: Script with ID '$ID' already exists in registry${NC}"
    echo "Use a different --id or --version to register a new version"
    exit 1
fi

# For versioned scripts, check if we're adding a new version
if [[ "$ID" =~ @ ]]; then
    # Check if base script exists
    BASE_EXISTS=$(jq -r ".scripts[] | select(.id | startswith(\"$BASE_ID\")) | .id" "$REGISTRY_FILE" | head -1)
    
    if [[ -n "$BASE_EXISTS" ]]; then
        echo -e "${GREEN}Adding new version to existing script: $BASE_ID${NC}"
        
        # Extract existing versions
        EXISTING_VERSIONS=$(jq -r ".scripts[] | select(.id | startswith(\"$BASE_ID\")) | .version // \"1.0.0\"" "$REGISTRY_FILE" | sort -V)
        echo "Existing versions:"
        echo "$EXISTING_VERSIONS" | sed 's/^/  - /'
        echo "Adding version: $VERSION"
        
        # Create CHANGELOG.md if it doesn't exist
        CHANGELOG_FILE="${SCRIPT_DIR}/CHANGELOG.md"
        if [[ ! -f "$CHANGELOG_FILE" ]]; then
            echo "# Script Version Changelog" > "$CHANGELOG_FILE"
            echo "" >> "$CHANGELOG_FILE"
        fi
        
        # Add changelog entry
        if [[ -n "$CHANGELOG_ENTRY" ]]; then
            echo "## [$BASE_ID@$VERSION] - $(date +%Y-%m-%d)" >> "$CHANGELOG_FILE"
            echo "$CHANGELOG_ENTRY" >> "$CHANGELOG_FILE"
            echo "" >> "$CHANGELOG_FILE"
        fi
    fi
fi

# Add the new script to the registry
echo -e "${GREEN}Adding script to registry...${NC}"

# Create a temporary file
TMP_FILE=$(mktemp)

# Add the new script to the registry
jq ".scripts += [$NEW_SCRIPT]" "$REGISTRY_FILE" > "$TMP_FILE"

# Validate the JSON
if jq empty "$TMP_FILE" 2>/dev/null; then
    # Update the registry file
    mv "$TMP_FILE" "$REGISTRY_FILE"
    
    echo -e "${GREEN}✓ Script registered successfully!${NC}"
    echo
    echo "Script ID: $ID"
    echo "Name: $NAME"
    echo "Category: $CATEGORY"
    echo "Path: $SCRIPT_PATH"
    
    if [[ ! -f "$FULL_SCRIPT_PATH" ]]; then
        echo
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Create the script file at: $FULL_SCRIPT_PATH"
        echo "2. Implement the script logic according to the registered interface"
        echo "3. Add examples if needed"
    fi
else
    echo -e "${RED}Error: Failed to update registry - invalid JSON${NC}"
    rm "$TMP_FILE"
    exit 1
fi