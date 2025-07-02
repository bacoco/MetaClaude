#!/bin/bash

# Example workflow demonstrating the TES Script Development Kit
# This script shows how to use all the dev tools together

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     TES Script Development Kit - Example Workflow        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo

# Example 1: Validate an existing script's metadata
echo -e "${BLUE}Example 1: Validating existing script metadata${NC}"
echo "Command: ./validate-metadata.py ../../validation/json-schema-validator.sh"
echo -e "${YELLOW}(This would validate the metadata for the JSON validator script)${NC}"
echo

# Example 2: Test a script locally
echo -e "${BLUE}Example 2: Testing a script in sandbox${NC}"
echo "Command: ./test-script-locally.sh ../../data/json-to-csv.sh -- --input sample.json"
echo -e "${YELLOW}(This would run the JSON to CSV converter in a sandboxed environment)${NC}"
echo

# Example 3: Lint a script for security issues
echo -e "${BLUE}Example 3: Security linting${NC}"
echo "Command: ./script-linter.py ../../core/tool-execution-service.py"
echo -e "${YELLOW}(This would check the TES core script for security issues)${NC}"
echo

# Example 4: Create a new script (interactive demo)
echo -e "${BLUE}Example 4: Creating a new script${NC}"
echo "Command: ./create-script-template.sh"
echo -e "${YELLOW}This will launch an interactive wizard to create:${NC}"
echo "  - Main script file with boilerplate"
echo "  - Test file with basic test cases"
echo "  - Metadata JSON for registration"
echo

# Example 5: Complete workflow for a new feature
echo -e "${GREEN}Complete Workflow for New Script Development:${NC}"
echo "1. Create script:     ./create-script-template.sh"
echo "2. Implement logic:   \$EDITOR category/script-name.sh"
echo "3. Test locally:      ./test-script-locally.sh category/script-name.sh"
echo "4. Lint for issues:   ./script-linter.py category/script-name.sh"
echo "5. Validate metadata: ./validate-metadata.py category/script-name.metadata.json"
echo "6. Run tests:         category/test-script-name.sh"
echo "7. Register:          cd ../.. && ./register-script.sh category/script-name.sh"
echo

# Show available options
echo -e "${CYAN}Key Features:${NC}"
echo "✓ Language support: Bash, Python, Node.js"
echo "✓ Security scanning: Detects hardcoded secrets, injection risks"
echo "✓ Sandbox testing: Memory limits, timeouts, permission controls"
echo "✓ Auto-fix support: Metadata validation can fix common issues"
echo "✓ Git integration: Pre-commit hooks for automatic linting"
echo

echo -e "${GREEN}Ready to start developing? Try: ./create-script-template.sh${NC}"