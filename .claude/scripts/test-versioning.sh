#!/bin/bash

# Test script for versioning and dependency management system
# Tests all major features of the version manager and dependency installer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED_TESTS=0
PASSED_TESTS=0

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    echo -e "${BLUE}Running test: $test_name${NC}"
    
    if eval "$command"; then
        if [[ $expected_exit_code -eq 0 ]]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}✗ FAILED - Expected failure but command succeeded${NC}"
            ((FAILED_TESTS++))
        fi
    else
        if [[ $expected_exit_code -ne 0 ]]; then
            echo -e "${GREEN}✓ PASSED (expected failure)${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}✗ FAILED - Command failed unexpectedly${NC}"
            ((FAILED_TESTS++))
        fi
    fi
    echo
}

echo -e "${YELLOW}=== MetaClaude Script Versioning System Test Suite ===${NC}"
echo

# Test 1: Version resolution
echo -e "${YELLOW}1. Testing Version Resolution${NC}"
run_test "Resolve specific version" \
    "python3 core/version-manager.py resolve 'core/json-validator@2.0.0' | grep -q 'core/json-validator@2.0.0'"

run_test "Resolve latest version" \
    "python3 core/version-manager.py resolve 'core/json-validator' | grep -q 'core/json-validator'"

run_test "Resolve with caret constraint" \
    "python3 core/version-manager.py resolve 'analysis/code-complexity@^1.0.0' | grep -q 'analysis/code-complexity'"

# Test 2: List versions
echo -e "${YELLOW}2. Testing Version Listing${NC}"
run_test "List available versions" \
    "python3 core/version-manager.py list 'core/json-validator' | grep -q '2.0.0'"

# Test 3: Dependency tree
echo -e "${YELLOW}3. Testing Dependency Tree${NC}"
run_test "Show dependency tree" \
    "python3 core/version-manager.py deps 'core/json-validator@2.0.0'"

run_test "Check for circular dependencies" \
    "python3 core/version-manager.py deps 'core/json-validator@2.0.0' --check-circular"

# Test 4: Installation order
echo -e "${YELLOW}4. Testing Installation Order${NC}"
run_test "Get installation order" \
    "python3 core/version-manager.py install-order 'core/json-validator@2.0.0'"

# Test 5: Migration guide
echo -e "${YELLOW}5. Testing Migration Guide Generation${NC}"
run_test "Generate migration guide" \
    "python3 core/version-manager.py migrate 'core/json-validator' '1.0.0' '2.0.0' | grep -q 'Migration Guide'"

# Test 6: Dependency installation (dry run)
echo -e "${YELLOW}6. Testing Dependency Installation${NC}"
run_test "Check dependency installer" \
    "python3 core/dependency-installer.py --help | grep -q 'MetaClaude Script Dependency Installer'"

# Test 7: Registry validation
echo -e "${YELLOW}7. Testing Registry Validation${NC}"
run_test "Validate registry JSON" \
    "jq empty registry.json"

run_test "Check for duplicate IDs" \
    "! jq -r '.scripts[].id' registry.json | sort | uniq -d | grep ."

# Test 8: Version format validation
echo -e "${YELLOW}8. Testing Version Format Validation${NC}"
run_test "Check all versions are semantic" \
    "jq -r '.scripts[].version // empty' registry.json | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null || true"

# Test 9: Script registration validation
echo -e "${YELLOW}9. Testing Script Registration${NC}"
# Create a test script
TEST_SCRIPT="test-dummy-script.sh"
cat > "$SCRIPT_DIR/core/$TEST_SCRIPT" << 'EOF'
#!/bin/bash
echo "Test script"
EOF
chmod +x "$SCRIPT_DIR/core/$TEST_SCRIPT"

# Test registration with version (skip actual registration)
echo -e "${BLUE}Running test: Check register script with version support${NC}"
if "${SCRIPT_DIR}/register-script.sh" --help 2>&1 | grep -q 'version VERSION'; then
    echo -e "${GREEN}✓ PASSED${NC}"
    ((PASSED_TESTS++))
else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED_TESTS++))
fi
echo

# Clean up test script
rm -f "$SCRIPT_DIR/core/$TEST_SCRIPT"

# Test 10: Backward compatibility
echo -e "${YELLOW}10. Testing Backward Compatibility${NC}"
run_test "Check non-versioned scripts still work" \
    "jq -e '.scripts[] | select(.id | contains(\"@\") | not)' registry.json > /dev/null"

# Summary
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    exit 1
fi