#!/bin/bash

# JSON Schema Validator
# Validates JSON files against a schema using jq

set -euo pipefail

# Check arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <schema_path> <data_path>"
    exit 1
fi

SCHEMA_PATH="$1"
DATA_PATH="$2"

# Check if files exist
if [[ ! -f "$SCHEMA_PATH" ]]; then
    echo "Error: Schema file not found: $SCHEMA_PATH" >&2
    exit 1
fi

if [[ ! -f "$DATA_PATH" ]]; then
    echo "Error: Data file not found: $DATA_PATH" >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Validate JSON syntax first
if ! jq empty "$SCHEMA_PATH" 2>/dev/null; then
    echo "Error: Invalid JSON in schema file" >&2
    exit 1
fi

if ! jq empty "$DATA_PATH" 2>/dev/null; then
    echo "Error: Invalid JSON in data file" >&2
    exit 1
fi

# Simple validation function
validate_json() {
    local schema="$1"
    local data="$2"
    
    # Extract schema type
    local schema_type=$(echo "$schema" | jq -r '.type // "object"')
    local data_type=$(echo "$data" | jq -r 'type')
    
    # Check type match
    if [[ "$schema_type" != "$data_type" ]]; then
        echo "Type mismatch: expected $schema_type, got $data_type"
        return 1
    fi
    
    # For objects, check required properties
    if [[ "$schema_type" == "object" ]]; then
        local required=$(echo "$schema" | jq -r '.required[]?' 2>/dev/null)
        if [[ -n "$required" ]]; then
            while IFS= read -r prop; do
                if ! echo "$data" | jq -e "has(\"$prop\")" >/dev/null 2>&1; then
                    echo "Missing required property: $prop"
                    return 1
                fi
            done <<< "$required"
        fi
    fi
    
    return 0
}

# Load schema and data
SCHEMA=$(cat "$SCHEMA_PATH")
DATA=$(cat "$DATA_PATH")

# Perform validation
ERRORS=""
if validate_json "$SCHEMA" "$DATA"; then
    IS_VALID="true"
else
    IS_VALID="false"
    ERRORS=$(validate_json "$SCHEMA" "$DATA" 2>&1 || true)
fi

# Output results in parseable format
echo "is_valid=$IS_VALID"
if [[ "$IS_VALID" == "false" ]]; then
    echo "errors=[\"$ERRORS\"]"
else
    echo "errors=[]"
fi

# Exit with appropriate code
if [[ "$IS_VALID" == "true" ]]; then
    exit 0
else
    exit 1
fi