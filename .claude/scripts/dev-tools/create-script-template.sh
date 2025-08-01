#!/bin/bash

# Create Script Template - Interactive wizard for creating new TES scripts
# This tool helps developers create properly structured scripts with all necessary boilerplate

set -euo pipefail

# Color codes for better UX
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base directory for scripts
SCRIPTS_DIR="/Users/loic/develop/DesignerClaude/UIDesignerClaude/.claude/scripts"

# Function to display header
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        TES Script Creation Wizard - Version 1.0.0        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Function to validate script name
validate_script_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        echo -e "${RED}Error: Script name must contain only lowercase letters, numbers, and hyphens${NC}"
        return 1
    fi
    return 0
}

# Function to select from list
select_from_list() {
    local prompt="$1"
    shift
    local options=("$@")
    
    echo -e "${YELLOW}$prompt${NC}"
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "$opt"
            return
        fi
    done
}

# Main wizard function
create_script() {
    print_header
    
    # Get script name
    while true; do
        echo -e "${GREEN}Enter script name (lowercase, hyphens allowed):${NC}"
        read -r script_name
        if validate_script_name "$script_name"; then
            break
        fi
    done
    
    # Get description
    echo -e "\n${GREEN}Enter a brief description of what the script does:${NC}"
    read -r description
    
    # Select language
    echo -e "\n${GREEN}Select script language:${NC}"
    languages=("bash" "python" "node.js")
    language=$(select_from_list "Choose language:" "${languages[@]}")
    
    # Select category
    echo -e "\n${GREEN}Select script category:${NC}"
    categories=(
        "analysis - Data analysis and reporting tools"
        "data - Data transformation and conversion utilities"
        "validation - Input validation and schema checking"
        "generation - Code and content generation tools"
        "integration - External service integrations"
        "monitoring - System monitoring and metrics"
        "core - Core TES functionality"
    )
    category_full=$(select_from_list "Choose category:" "${categories[@]}")
    category=$(echo "$category_full" | cut -d' ' -f1)
    
    # Get arguments
    echo -e "\n${GREEN}Define script arguments (press Enter when done):${NC}"
    args=()
    arg_count=0
    while true; do
        echo -e "${YELLOW}Argument $((arg_count + 1)) (leave name empty to finish):${NC}"
        echo -n "  Name: "
        read -r arg_name
        [[ -z "$arg_name" ]] && break
        
        echo -n "  Type (string/number/boolean/array): "
        read -r arg_type
        
        echo -n "  Required (y/n): "
        read -r arg_required
        [[ "$arg_required" == "y" ]] && arg_required="true" || arg_required="false"
        
        echo -n "  Description: "
        read -r arg_desc
        
        echo -n "  Default value (optional): "
        read -r arg_default
        
        args+=("{\"name\": \"$arg_name\", \"type\": \"$arg_type\", \"required\": $arg_required, \"description\": \"$arg_desc\"$([ -n "$arg_default" ] && echo ", \"default\": \"$arg_default\"" || echo "")}")
        ((arg_count++))
    done
    
    # Create directory if needed
    script_dir="$SCRIPTS_DIR/$category"
    mkdir -p "$script_dir"
    
    # Generate script filename
    case "$language" in
        "bash")
            ext="sh"
            interpreter="/bin/bash"
            ;;
        "python")
            ext="py"
            interpreter="/usr/bin/env python3"
            ;;
        "node.js")
            ext="js"
            interpreter="/usr/bin/env node"
            ;;
    esac
    
    script_path="$script_dir/$script_name.$ext"
    test_path="$script_dir/test-$script_name.$ext"
    
    # Create script file
    echo -e "\n${BLUE}Creating script: $script_path${NC}"
    
    case "$language" in
        "bash")
            cat > "$script_path" << 'EOF'
#!/bin/bash

# SCRIPT_NAME - DESCRIPTION
# Generated by TES Script Creation Wizard

set -euo pipefail

# Enable debug mode if requested
[[ "${DEBUG:-0}" == "1" ]] && set -x

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Error handling
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

success() {
    echo -e "${GREEN}Success: $1${NC}"
}

# Argument parsing
usage() {
    cat << USAGE
Usage: $SCRIPT_NAME [OPTIONS]

DESCRIPTION

Options:
ARGS_HELP
    -h, --help     Show this help message
    -v, --version  Show version information

Environment:
    DEBUG=1        Enable debug output

Examples:
    $SCRIPT_NAME ARG_EXAMPLES

USAGE
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0
                ;;
            *)
                # Add custom argument parsing here
                shift
                ;;
        esac
    done
}

# Validate inputs
validate_inputs() {
    # Add input validation logic here
    return 0
}

# Main function
main() {
    parse_args "$@"
    
    if ! validate_inputs; then
        error "Invalid inputs provided"
    fi
    
    # Add main script logic here
    echo "Executing $SCRIPT_NAME..."
    
    # Output results in JSON format for TES integration
    cat << JSON
{
    "status": "success",
    "message": "Script executed successfully",
    "data": {}
}
JSON
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
            ;;
            
        "python")
            cat > "$script_path" << 'EOF'
#!/usr/bin/env python3

"""
SCRIPT_NAME - DESCRIPTION
Generated by TES Script Creation Wizard
"""

import sys
import json
import argparse
import logging
from typing import Dict, Any, Optional
from pathlib import Path

# Script metadata
__version__ = "1.0.0"
__author__ = "TES Script Wizard"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ScriptError(Exception):
    """Custom exception for script errors"""
    pass


def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='DESCRIPTION',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    # Add custom arguments here
    parser.add_argument(
        '-v', '--version',
        action='version',
        version=f'%(prog)s {__version__}'
    )
    
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug logging'
    )
    
    return parser.parse_args()


def validate_inputs(args: argparse.Namespace) -> bool:
    """Validate input arguments"""
    try:
        # Add validation logic here
        return True
    except Exception as e:
        logger.error(f"Validation error: {e}")
        return False


def process_data(args: argparse.Namespace) -> Dict[str, Any]:
    """Main processing logic"""
    try:
        # Add main script logic here
        result = {
            "status": "success",
            "message": "Script executed successfully",
            "data": {}
        }
        return result
    except Exception as e:
        logger.error(f"Processing error: {e}")
        raise ScriptError(f"Failed to process: {e}")


def main():
    """Main entry point"""
    try:
        args = parse_arguments()
        
        if args.debug:
            logger.setLevel(logging.DEBUG)
        
        if not validate_inputs(args):
            raise ScriptError("Invalid inputs provided")
        
        result = process_data(args)
        
        # Output results as JSON for TES integration
        print(json.dumps(result, indent=2))
        
    except ScriptError as e:
        logger.error(f"Script error: {e}")
        error_result = {
            "status": "error",
            "message": str(e),
            "data": None
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)
    except Exception as e:
        logger.exception("Unexpected error")
        error_result = {
            "status": "error",
            "message": "An unexpected error occurred",
            "data": None
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(2)


if __name__ == "__main__":
    main()
EOF
            ;;
            
        "node.js")
            cat > "$script_path" << 'EOF'
#!/usr/bin/env node

/**
 * SCRIPT_NAME - DESCRIPTION
 * Generated by TES Script Creation Wizard
 */

const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

// Script metadata
const VERSION = '1.0.0';
const SCRIPT_NAME = path.basename(__filename);

// Error class
class ScriptError extends Error {
    constructor(message) {
        super(message);
        this.name = 'ScriptError';
    }
}

// Logging utilities
const log = {
    info: (msg) => console.error(`[INFO] ${msg}`),
    error: (msg) => console.error(`[ERROR] ${msg}`),
    debug: (msg) => process.env.DEBUG && console.error(`[DEBUG] ${msg}`),
    warn: (msg) => console.error(`[WARN] ${msg}`)
};

// Parse command line arguments
function parseArgs(argv) {
    const args = {
        _: [],
        help: false,
        version: false,
        debug: false
    };
    
    for (let i = 2; i < argv.length; i++) {
        const arg = argv[i];
        
        switch (arg) {
            case '-h':
            case '--help':
                args.help = true;
                break;
            case '-v':
            case '--version':
                args.version = true;
                break;
            case '--debug':
                args.debug = true;
                break;
            default:
                if (arg.startsWith('-')) {
                    // Add custom argument parsing here
                } else {
                    args._.push(arg);
                }
        }
    }
    
    return args;
}

// Show usage information
function showUsage() {
    console.log(`
Usage: ${SCRIPT_NAME} [OPTIONS]

DESCRIPTION

Options:
    -h, --help     Show this help message
    -v, --version  Show version information
    --debug        Enable debug output

Examples:
    ${SCRIPT_NAME} [examples]
`);
}

// Validate inputs
async function validateInputs(args) {
    try {
        // Add validation logic here
        return true;
    } catch (error) {
        log.error(`Validation error: ${error.message}`);
        return false;
    }
}

// Main processing logic
async function processData(args) {
    try {
        // Add main script logic here
        
        return {
            status: 'success',
            message: 'Script executed successfully',
            data: {}
        };
    } catch (error) {
        throw new ScriptError(`Processing failed: ${error.message}`);
    }
}

// Main entry point
async function main() {
    try {
        const args = parseArgs(process.argv);
        
        if (args.help) {
            showUsage();
            process.exit(0);
        }
        
        if (args.version) {
            console.log(`${SCRIPT_NAME} version ${VERSION}`);
            process.exit(0);
        }
        
        if (args.debug) {
            process.env.DEBUG = '1';
        }
        
        if (!await validateInputs(args)) {
            throw new ScriptError('Invalid inputs provided');
        }
        
        const result = await processData(args);
        
        // Output results as JSON for TES integration
        console.log(JSON.stringify(result, null, 2));
        
    } catch (error) {
        const errorResult = {
            status: 'error',
            message: error.message,
            data: null
        };
        
        console.log(JSON.stringify(errorResult, null, 2));
        process.exit(error instanceof ScriptError ? 1 : 2);
    }
}

// Run if called directly
if (require.main === module) {
    main();
}
EOF
            ;;
    esac
    
    # Replace placeholders
    sed -i '' "s/SCRIPT_NAME/$script_name/g" "$script_path"
    sed -i '' "s/DESCRIPTION/$description/g" "$script_path"
    
    # Make script executable
    chmod +x "$script_path"
    
    # Create test file
    echo -e "${BLUE}Creating test file: $test_path${NC}"
    
    case "$language" in
        "bash")
            cat > "$test_path" << EOF
#!/bin/bash

# Test suite for $script_name
# Generated by TES Script Creation Wizard

set -euo pipefail

# Test framework
readonly SCRIPT_PATH="$script_path"
readonly TEST_DIR="\$(mktemp -d)"
trap 'rm -rf "\$TEST_DIR"' EXIT

# Color codes
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Test counters
tests_run=0
tests_passed=0
tests_failed=0

# Test functions
assert_equals() {
    local expected="\$1"
    local actual="\$2"
    local message="\${3:-}"
    
    ((tests_run++))
    
    if [[ "\$expected" == "\$actual" ]]; then
        echo -e "\${GREEN}✓\${NC} \$message"
        ((tests_passed++))
    else
        echo -e "\${RED}✗\${NC} \$message"
        echo "  Expected: \$expected"
        echo "  Actual: \$actual"
        ((tests_failed++))
    fi
}

assert_contains() {
    local haystack="\$1"
    local needle="\$2"
    local message="\${3:-}"
    
    ((tests_run++))
    
    if [[ "\$haystack" == *"\$needle"* ]]; then
        echo -e "\${GREEN}✓\${NC} \$message"
        ((tests_passed++))
    else
        echo -e "\${RED}✗\${NC} \$message"
        echo "  String does not contain: \$needle"
        ((tests_failed++))
    fi
}

# Test cases
test_help_flag() {
    echo "Testing --help flag..."
    local output=\$("\$SCRIPT_PATH" --help 2>&1 || true)
    assert_contains "\$output" "Usage:" "Help flag shows usage"
}

test_version_flag() {
    echo "Testing --version flag..."
    local output=\$("\$SCRIPT_PATH" --version 2>&1 || true)
    assert_contains "\$output" "version" "Version flag shows version"
}

test_basic_execution() {
    echo "Testing basic execution..."
    local output=\$("\$SCRIPT_PATH" 2>&1 || true)
    local exit_code=\$?
    assert_equals "0" "\$exit_code" "Script exits successfully"
}

# Add more test cases here

# Run tests
main() {
    echo "Running tests for $script_name..."
    echo
    
    test_help_flag
    test_version_flag
    test_basic_execution
    
    echo
    echo "Test Summary:"
    echo "  Total: \$tests_run"
    echo -e "  \${GREEN}Passed: \$tests_passed\${NC}"
    echo -e "  \${RED}Failed: \$tests_failed\${NC}"
    
    [[ \$tests_failed -eq 0 ]] && exit 0 || exit 1
}

main "\$@"
EOF
            ;;
            
        "python")
            cat > "$test_path" << EOF
#!/usr/bin/env python3

"""
Test suite for $script_name
Generated by TES Script Creation Wizard
"""

import unittest
import subprocess
import json
import sys
import os
from pathlib import Path

# Add script directory to path
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

SCRIPT_PATH = str(script_dir / "$script_name.py")


class Test${script_name//-/_}(unittest.TestCase):
    """Test cases for $script_name"""
    
    def run_script(self, args=None):
        """Helper to run the script and capture output"""
        cmd = [sys.executable, SCRIPT_PATH]
        if args:
            cmd.extend(args)
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True
        )
        
        return result
    
    def test_help_flag(self):
        """Test --help flag"""
        result = self.run_script(['--help'])
        self.assertEqual(result.returncode, 0)
        self.assertIn('usage:', result.stdout.lower())
    
    def test_version_flag(self):
        """Test --version flag"""
        result = self.run_script(['--version'])
        self.assertEqual(result.returncode, 0)
        self.assertIn('1.0.0', result.stdout)
    
    def test_basic_execution(self):
        """Test basic script execution"""
        result = self.run_script()
        self.assertEqual(result.returncode, 0)
        
        # Verify JSON output
        try:
            output = json.loads(result.stdout)
            self.assertEqual(output['status'], 'success')
        except json.JSONDecodeError:
            self.fail("Script did not produce valid JSON output")
    
    def test_invalid_input(self):
        """Test script behavior with invalid input"""
        # Add test cases for invalid inputs
        pass
    
    # Add more test cases here


if __name__ == '__main__':
    unittest.main()
EOF
            ;;
            
        "node.js")
            cat > "$test_path" << EOF
#!/usr/bin/env node

/**
 * Test suite for $script_name
 * Generated by TES Script Creation Wizard
 */

const { execSync } = require('child_process');
const path = require('path');
const assert = require('assert');

const SCRIPT_PATH = path.join(__dirname, '$script_name.js');

// Test utilities
let testsPassed = 0;
let testsFailed = 0;

function test(name, fn) {
    try {
        fn();
        console.log(\`✓ \${name}\`);
        testsPassed++;
    } catch (error) {
        console.error(\`✗ \${name}\`);
        console.error(\`  \${error.message}\`);
        testsFailed++;
    }
}

function runScript(args = []) {
    try {
        const output = execSync(\`node "\${SCRIPT_PATH}" \${args.join(' ')}\`, {
            encoding: 'utf8'
        });
        return { output, exitCode: 0 };
    } catch (error) {
        return {
            output: error.stdout || error.stderr || '',
            exitCode: error.status || 1
        };
    }
}

// Test cases
test('Help flag shows usage', () => {
    const { output } = runScript(['--help']);
    assert(output.includes('Usage:'), 'Output should contain usage information');
});

test('Version flag shows version', () => {
    const { output } = runScript(['--version']);
    assert(output.includes('version'), 'Output should contain version information');
});

test('Basic execution succeeds', () => {
    const { output, exitCode } = runScript();
    assert.strictEqual(exitCode, 0, 'Script should exit with code 0');
    
    // Verify JSON output
    const result = JSON.parse(output);
    assert.strictEqual(result.status, 'success', 'Status should be success');
});

// Add more test cases here

// Summary
console.log(\`\\nTest Summary:\`);
console.log(\`  Total: \${testsPassed + testsFailed}\`);
console.log(\`  Passed: \${testsPassed}\`);
console.log(\`  Failed: \${testsFailed}\`);

process.exit(testsFailed > 0 ? 1 : 0);
EOF
            ;;
    esac
    
    chmod +x "$test_path"
    
    # Generate registration command
    echo -e "\n${BLUE}Generating registration metadata...${NC}"
    
    # Create metadata JSON
    args_json=$(printf '%s\n' "${args[@]}" | paste -sd ',' -)
    metadata=$(cat << JSON
{
  "id": "$category/$script_name",
  "name": "$script_name",
  "category": "$category",
  "path": "scripts/$category/$script_name.$ext",
  "description": "$description",
  "execution": {
    "type": "shell_script",
    "interpreter": "$interpreter",
    "args": [$args_json],
    "timeout": 30000,
    "permissions": ["read_file", "write_file"]
  },
  "outputs": [
    {"name": "status", "type": "string", "description": "Execution status"},
    {"name": "message", "type": "string", "description": "Status message"},
    {"name": "data", "type": "object", "description": "Result data"}
  ],
  "dependencies": [],
  "version": "1.0.0",
  "security": {
    "sandbox": "minimal",
    "max_memory": "512MB",
    "network_access": false
  },
  "tags": ["$category"]
}
JSON
)
    
    # Save metadata for registration
    metadata_file="$script_dir/$script_name.metadata.json"
    echo "$metadata" > "$metadata_file"
    
    echo -e "\n${GREEN}✓ Script created successfully!${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Edit the script: $script_path"
    echo "2. Run tests: $test_path"
    echo "3. Register with TES:"
    echo -e "   ${BLUE}cd $SCRIPTS_DIR && ./register-script.sh $category/$script_name.$ext${NC}"
    echo -e "\n${YELLOW}Files created:${NC}"
    echo "  - Script: $script_path"
    echo "  - Tests: $test_path"
    echo "  - Metadata: $metadata_file"
}

# Run the wizard
create_script