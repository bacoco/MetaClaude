#!/bin/bash

# Quick test script for MetaClaude Tool Usage Excellence
# Tests basic functionality without full edge case handling

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}MetaClaude Tool Usage Excellence - Quick Test${NC}"
echo "=============================================="
echo

# Test 1: Basic hook functionality
echo -e "${YELLOW}Test 1: Enforce Matrix${NC}"
./enforce-matrix.sh '{"tool_name": "write_file", "context": "saving", "user_request": "save"}' > /tmp/test1.json 2>&1
if jq -e '.status' /tmp/test1.json >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Matrix enforcement returns valid JSON${NC}"
    jq -r '.status' /tmp/test1.json
else
    echo -e "${RED}✗ Matrix enforcement failed${NC}"
fi
echo

# Test 2: Usage tracking
echo -e "${YELLOW}Test 2: Track Usage${NC}"
./track-usage.sh '{"tool_name": "read_file", "context": "test", "result_status": "success"}' > /tmp/test2.json 2>&1
if jq -e '.status' /tmp/test2.json >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Usage tracking returns valid JSON${NC}"
    echo "Session: $(jq -r '.session_id' /tmp/test2.json)"
else
    echo -e "${RED}✗ Usage tracking failed${NC}"
fi
echo

# Test 3: Check log files
echo -e "${YELLOW}Test 3: Log Files${NC}"
LOG_DIR="$HOME/develop/DesignerClaude/UIDesignerClaude/.claude/logs/metaclaude"
if [ -f "$LOG_DIR/tool-usage.jsonl" ]; then
    echo -e "${GREEN}✓ Usage log exists${NC}"
    echo "Entries: $(wc -l < "$LOG_DIR/tool-usage.jsonl" | tr -d ' ')"
else
    echo -e "${YELLOW}⚠ No usage log yet${NC}"
fi
echo

# Test 4: Documentation update
echo -e "${YELLOW}Test 4: Documentation${NC}"
./update-docs.sh tool read_file > /tmp/test4.json 2>&1
if jq -e '.status' /tmp/test4.json >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Documentation update works${NC}"
else
    echo -e "${YELLOW}⚠ Documentation update needs usage data${NC}"
fi
echo

echo -e "${GREEN}Basic tests complete!${NC}"
echo "The hooks are now active and will track all tool usage."
echo "Run more operations to generate data for analytics."

# Cleanup
rm -f /tmp/test*.json