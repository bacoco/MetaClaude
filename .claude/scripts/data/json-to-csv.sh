#!/bin/bash

# JSON to CSV Converter
# Convert JSON arrays to CSV format with automatic header detection

set -euo pipefail

# Check arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <input_file> [output_file] [headers]"
    echo "  input_file: JSON file to convert"
    echo "  output_file: Output CSV file (stdout if not specified)"
    echo "  headers: true/false - use first row for headers (default: true)"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-}"
USE_HEADERS="${3:-true}"

# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Validate JSON
if ! jq empty "$INPUT_FILE" 2>/dev/null; then
    echo "Error: Invalid JSON in input file" >&2
    exit 1
fi

# Function to convert JSON to CSV
json_to_csv() {
    local json_file="$1"
    local use_headers="$2"
    
    # Check if input is an array
    if ! jq -e 'type == "array"' "$json_file" >/dev/null 2>&1; then
        echo "Error: Input must be a JSON array" >&2
        return 1
    fi
    
    # Get row count
    local row_count=$(jq 'length' "$json_file")
    
    if [[ "$row_count" -eq 0 ]]; then
        echo "Error: Empty array" >&2
        return 1
    fi
    
    # Extract headers from first object
    if [[ "$use_headers" == "true" ]]; then
        jq -r '.[0] | keys_unsorted | @csv' "$json_file"
    fi
    
    # Extract values
    jq -r '.[] | [.[]] | @csv' "$json_file"
    
    # Return row count for output
    echo "row_count=$row_count" >&2
}

# Convert JSON to CSV
if [[ -n "$OUTPUT_FILE" ]]; then
    # Output to file
    CSV_OUTPUT=$(json_to_csv "$INPUT_FILE" "$USE_HEADERS" 2>&1)
    RESULT=$?
    
    if [[ $RESULT -eq 0 ]]; then
        # Extract row count from stderr
        ROW_COUNT=$(echo "$CSV_OUTPUT" | grep "row_count=" | cut -d= -f2)
        # Write CSV to file (excluding the row_count line)
        echo "$CSV_OUTPUT" | grep -v "row_count=" > "$OUTPUT_FILE"
        
        # Output results for parsing
        echo "json_data={\"file\":\"$OUTPUT_FILE\"}"
        echo "row_count=$ROW_COUNT"
    else
        echo "$CSV_OUTPUT" >&2
        exit 1
    fi
else
    # Output to stdout
    json_to_csv "$INPUT_FILE" "$USE_HEADERS"
fi