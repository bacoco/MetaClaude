#!/bin/bash
# test-hooks.sh - Test utility for MetaClaude hook system

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Base directory
HOOK_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}=== MetaClaude Hook System Test Suite ===${NC}\n"

# Test 1: Directory structure
echo -e "${YELLOW}Test 1: Verifying directory structure${NC}"
required_dirs=("content" "monitoring" "utils")
for dir in "${required_dirs[@]}"; do
    if [[ -d "$HOOK_BASE/$dir" ]]; then
        echo -e "  ${GREEN}✓${NC} $dir directory exists"
    else
        echo -e "  ${RED}✗${NC} $dir directory missing"
    fi
done

# Test 2: Script executability
echo -e "\n${YELLOW}Test 2: Checking script permissions${NC}"
scripts=(
    "content/dedup-check.sh"
    "content/similarity-detector.sh"
    "monitoring/hook-metrics.sh"
    "monitoring/log-aggregator.sh"
)
for script in "${scripts[@]}"; do
    if [[ -x "$HOOK_BASE/$script" ]]; then
        echo -e "  ${GREEN}✓${NC} $script is executable"
    else
        echo -e "  ${RED}✗${NC} $script is not executable"
    fi
done

# Test 3: Deduplication hook
echo -e "\n${YELLOW}Test 3: Testing deduplication hook${NC}"
test_content='{"content": "Core Configuration test content with Token Economy patterns"}'
echo "$test_content" | "$HOOK_BASE/content/dedup-check.sh" 2>&1 | head -5 || true

# Test 4: Similarity detection
echo -e "\n${YELLOW}Test 4: Testing similarity detector${NC}"
echo "Testing pattern detection for Configuration and Standards" | \
    "$HOOK_BASE/content/similarity-detector.sh" | jq '.summary' 2>/dev/null || \
    echo -e "  ${RED}JSON parsing failed${NC}"

# Test 5: Metrics recording
echo -e "\n${YELLOW}Test 5: Testing metrics recording${NC}"
"$HOOK_BASE/monitoring/hook-metrics.sh" record test-hook success 100
"$HOOK_BASE/monitoring/hook-metrics.sh" stats test-hook | jq '.' 2>/dev/null || \
    echo -e "  ${RED}Metrics retrieval failed${NC}"

# Test 6: Settings.json configuration
echo -e "\n${YELLOW}Test 6: Verifying settings.json configuration${NC}"
settings_file="$HOOK_BASE/../../settings.json"
if [[ -f "$settings_file" ]]; then
    if jq '.hooks.PreToolUse[] | select(.name == "metaclaude-content-deduplication")' \
        "$settings_file" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Hook configured in settings.json"
    else
        echo -e "  ${RED}✗${NC} Hook not found in settings.json"
    fi
else
    echo -e "  ${RED}✗${NC} settings.json not found"
fi

echo -e "\n${BLUE}=== Test suite completed ===${NC}"