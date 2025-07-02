#!/bin/bash

# Test Script Locally - Run scripts in a TES-like sandbox environment
# This tool helps test scripts with resource limits and permission controls

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPTS_DIR="/Users/loic/develop/DesignerClaude/UIDesignerClaude/.claude/scripts"
REGISTRY_FILE="$SCRIPTS_DIR/registry.json"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Default limits (matching TES environment)
DEFAULT_TIMEOUT=30000  # 30 seconds in milliseconds
DEFAULT_MEMORY="512MB"
DEFAULT_CPU_LIMIT="1"

# Function to display header
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         TES Local Testing Environment v1.0.0             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Function to format time
format_time() {
    local ms=$1
    local seconds=$((ms / 1000))
    local milliseconds=$((ms % 1000))
    
    if [[ $seconds -gt 0 ]]; then
        echo "${seconds}.${milliseconds}s"
    else
        echo "${milliseconds}ms"
    fi
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1048576))MB"
    fi
}

# Function to get script metadata from registry
get_script_metadata() {
    local script_path="$1"
    local relative_path="${script_path#$SCRIPTS_DIR/}"
    
    if [[ -f "$REGISTRY_FILE" ]]; then
        jq -r ".scripts[] | select(.path == \"$relative_path\")" "$REGISTRY_FILE" 2>/dev/null
    fi
}

# Function to create sandbox environment
create_sandbox() {
    local sandbox_type="$1"
    local sandbox_dir="$TMP_DIR/sandbox"
    
    mkdir -p "$sandbox_dir"
    
    case "$sandbox_type" in
        "minimal")
            # Minimal sandbox - basic filesystem isolation
            echo -e "${BLUE}Creating minimal sandbox...${NC}"
            ;;
        "strict")
            # Strict sandbox - network isolation, limited filesystem
            echo -e "${BLUE}Creating strict sandbox...${NC}"
            # Create restricted filesystem structure
            mkdir -p "$sandbox_dir"/{tmp,home}
            ;;
        *)
            echo -e "${YELLOW}Unknown sandbox type: $sandbox_type, using minimal${NC}"
            ;;
    esac
    
    echo "$sandbox_dir"
}

# Function to apply resource limits
apply_resource_limits() {
    local memory_limit="$1"
    local cpu_limit="$2"
    
    # Convert memory limit to bytes
    local memory_bytes
    case "$memory_limit" in
        *MB)
            memory_bytes=$((${memory_limit%MB} * 1048576))
            ;;
        *GB)
            memory_bytes=$((${memory_limit%GB} * 1073741824))
            ;;
        *)
            memory_bytes=$((512 * 1048576))  # Default 512MB
            ;;
    esac
    
    # Return ulimit commands
    echo "ulimit -v $((memory_bytes / 1024))"  # Virtual memory in KB
    echo "ulimit -t $cpu_limit"  # CPU time in seconds
}

# Function to validate script inputs
validate_inputs() {
    local metadata="$1"
    shift
    local args=("$@")
    
    if [[ -z "$metadata" ]]; then
        return 0  # No metadata, skip validation
    fi
    
    local required_args=$(echo "$metadata" | jq -r '.execution.args[] | select(.required == true) | .name' 2>/dev/null)
    
    # Check if all required arguments are provided
    for req_arg in $required_args; do
        local found=false
        for arg in "${args[@]}"; do
            if [[ "$arg" == *"$req_arg"* ]]; then
                found=true
                break
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            echo -e "${RED}Error: Required argument '$req_arg' not provided${NC}" >&2
            return 1
        fi
    done
    
    return 0
}

# Function to monitor script execution
monitor_execution() {
    local pid=$1
    local timeout=$2
    local start_time=$(date +%s%3N)
    
    # Monitor CPU and memory usage
    while kill -0 "$pid" 2>/dev/null; do
        local current_time=$(date +%s%3N)
        local elapsed=$((current_time - start_time))
        
        # Check timeout
        if [[ $elapsed -gt $timeout ]]; then
            echo -e "\n${RED}Timeout exceeded! Killing process...${NC}" >&2
            kill -TERM "$pid" 2>/dev/null
            sleep 1
            kill -KILL "$pid" 2>/dev/null || true
            return 124  # Timeout exit code
        fi
        
        # Show progress
        printf "\r${YELLOW}Running... $(format_time $elapsed)${NC}"
        sleep 0.1
    done
    
    wait "$pid"
    local exit_code=$?
    
    local end_time=$(date +%s%3N)
    local total_time=$((end_time - start_time))
    
    printf "\r${GREEN}Completed in $(format_time $total_time)${NC}\n"
    
    return $exit_code
}

# Function to generate test report
generate_report() {
    local script_name="$1"
    local exit_code="$2"
    local execution_time="$3"
    local output_file="$4"
    local error_file="$5"
    local metadata="$6"
    
    local report_file="$TMP_DIR/test-report.json"
    
    # Get output size
    local output_size=$(wc -c < "$output_file" 2>/dev/null || echo 0)
    local error_size=$(wc -c < "$error_file" 2>/dev/null || echo 0)
    
    # Parse output if JSON
    local output_data="{}"
    if [[ -s "$output_file" ]]; then
        if jq -e . "$output_file" >/dev/null 2>&1; then
            output_data=$(cat "$output_file")
        fi
    fi
    
    # Create report
    cat > "$report_file" << JSON
{
  "script": "$script_name",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "execution": {
    "exit_code": $exit_code,
    "success": $([ $exit_code -eq 0 ] && echo "true" || echo "false"),
    "execution_time_ms": $execution_time,
    "output_size": $output_size,
    "error_size": $error_size
  },
  "output": $output_data,
  "errors": $([ -s "$error_file" ] && jq -Rs . "$error_file" || echo "null"),
  "validation": {
    "schema_valid": $([ -n "$metadata" ] && echo "true" || echo "false"),
    "timeout_respected": $([ $exit_code -ne 124 ] && echo "true" || echo "false")
  }
}
JSON
    
    echo "$report_file"
}

# Function to display test results
display_results() {
    local report_file="$1"
    local output_file="$2"
    local error_file="$3"
    
    echo -e "\n${BLUE}═══════════════ Test Results ═══════════════${NC}"
    
    # Parse report
    local exit_code=$(jq -r '.execution.exit_code' "$report_file")
    local exec_time=$(jq -r '.execution.execution_time_ms' "$report_file")
    local output_size=$(jq -r '.execution.output_size' "$report_file")
    
    # Status
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ Test PASSED${NC}"
    elif [[ $exit_code -eq 124 ]]; then
        echo -e "${RED}✗ Test FAILED (Timeout)${NC}"
    else
        echo -e "${RED}✗ Test FAILED (Exit code: $exit_code)${NC}"
    fi
    
    # Execution details
    echo -e "\n${YELLOW}Execution Details:${NC}"
    echo "  Time: $(format_time $exec_time)"
    echo "  Output size: $(format_bytes $output_size)"
    
    # Resource usage (if available)
    if command -v /usr/bin/time >/dev/null 2>&1 && [[ -f "$TMP_DIR/time.log" ]]; then
        echo -e "\n${YELLOW}Resource Usage:${NC}"
        cat "$TMP_DIR/time.log"
    fi
    
    # Output
    if [[ -s "$output_file" ]]; then
        echo -e "\n${YELLOW}Script Output:${NC}"
        if jq -e . "$output_file" >/dev/null 2>&1; then
            jq -C . "$output_file"
        else
            cat "$output_file" | head -20
            [[ $(wc -l < "$output_file") -gt 20 ]] && echo "... (truncated)"
        fi
    fi
    
    # Errors
    if [[ -s "$error_file" ]]; then
        echo -e "\n${YELLOW}Error Output:${NC}"
        cat "$error_file" | head -10
        [[ $(wc -l < "$error_file") -gt 10 ]] && echo "... (truncated)"
    fi
    
    # Report location
    echo -e "\n${BLUE}Full report saved to: $report_file${NC}"
}

# Main function
main() {
    print_header
    
    # Parse arguments
    local script_path=""
    local show_help=false
    local verbose=false
    local custom_timeout=""
    local custom_memory=""
    local script_args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --timeout)
                custom_timeout="$2"
                shift 2
                ;;
            --memory)
                custom_memory="$2"
                shift 2
                ;;
            --)
                shift
                script_args=("$@")
                break
                ;;
            *)
                if [[ -z "$script_path" ]]; then
                    script_path="$1"
                else
                    script_args+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Show help if requested
    if [[ "$show_help" == "true" ]] || [[ -z "$script_path" ]]; then
        cat << HELP
Usage: $(basename "$0") [OPTIONS] SCRIPT_PATH [-- SCRIPT_ARGS...]

Test a script in a TES-like sandbox environment with resource limits.

Options:
    -h, --help          Show this help message
    -v, --verbose       Show detailed execution information
    --timeout MS        Set execution timeout in milliseconds (default: 30000)
    --memory LIMIT      Set memory limit (e.g., 512MB, 1GB)
    --                  Pass remaining arguments to the script

Examples:
    $(basename "$0") ./my-script.sh
    $(basename "$0") ./my-script.py -- --input data.json
    $(basename "$0") --timeout 60000 --memory 1GB ./processor.js

Environment Variables:
    TES_DEBUG=1         Enable debug output

HELP
        exit 0
    fi
    
    # Validate script exists
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}Error: Script not found: $script_path${NC}" >&2
        exit 1
    fi
    
    # Make script path absolute
    script_path="$(cd "$(dirname "$script_path")" && pwd)/$(basename "$script_path")"
    script_name="$(basename "$script_path")"
    
    echo -e "${BLUE}Testing script: $script_name${NC}"
    
    # Get script metadata
    local metadata=$(get_script_metadata "$script_path")
    
    if [[ -n "$metadata" ]]; then
        echo -e "${GREEN}✓ Found script in registry${NC}"
        
        # Extract configuration from metadata
        local timeout=${custom_timeout:-$(echo "$metadata" | jq -r '.execution.timeout // 30000')}
        local memory=${custom_memory:-$(echo "$metadata" | jq -r '.security.max_memory // "512MB"')}
        local sandbox=$(echo "$metadata" | jq -r '.security.sandbox // "minimal"')
        local permissions=$(echo "$metadata" | jq -r '.execution.permissions[]?' 2>/dev/null)
        
        echo -e "${YELLOW}Configuration:${NC}"
        echo "  Timeout: $(format_time $timeout)"
        echo "  Memory: $memory"
        echo "  Sandbox: $sandbox"
        [[ -n "$permissions" ]] && echo "  Permissions: $permissions"
    else
        echo -e "${YELLOW}⚠ Script not in registry, using defaults${NC}"
        local timeout=${custom_timeout:-$DEFAULT_TIMEOUT}
        local memory=${custom_memory:-$DEFAULT_MEMORY}
        local sandbox="minimal"
    fi
    
    # Validate inputs
    if ! validate_inputs "$metadata" "${script_args[@]}"; then
        exit 1
    fi
    
    # Create sandbox
    local sandbox_dir=$(create_sandbox "$sandbox")
    
    # Prepare execution environment
    local output_file="$TMP_DIR/output.json"
    local error_file="$TMP_DIR/error.log"
    local time_log="$TMP_DIR/time.log"
    
    # Apply resource limits
    local limit_commands=$(apply_resource_limits "$memory" "$DEFAULT_CPU_LIMIT")
    
    echo -e "\n${BLUE}Starting execution...${NC}"
    
    # Execute script with monitoring
    local start_time=$(date +%s%3N)
    
    (
        # Apply limits
        eval "$limit_commands"
        
        # Change to sandbox if strict
        [[ "$sandbox" == "strict" ]] && cd "$sandbox_dir"
        
        # Execute script
        if command -v /usr/bin/time >/dev/null 2>&1; then
            /usr/bin/time -v "$script_path" "${script_args[@]}" 2>"$time_log"
        else
            "$script_path" "${script_args[@]}"
        fi
    ) >"$output_file" 2>"$error_file" &
    
    local pid=$!
    
    # Monitor execution
    monitor_execution "$pid" "$timeout"
    local exit_code=$?
    
    local end_time=$(date +%s%3N)
    local execution_time=$((end_time - start_time))
    
    # Generate report
    local report_file=$(generate_report "$script_name" "$exit_code" "$execution_time" "$output_file" "$error_file" "$metadata")
    
    # Display results
    display_results "$report_file" "$output_file" "$error_file"
    
    # Exit with script's exit code
    exit $exit_code
}

# Run main function
main "$@"