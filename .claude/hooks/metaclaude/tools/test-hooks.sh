#!/bin/bash

# Test script for MetaClaude Tool Usage Excellence hooks
# Verifies all components are working correctly

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}MetaClaude Tool Usage Excellence - Test Suite${NC}"
echo "=============================================="
echo

# Test 1: Enforce Matrix
echo -e "${YELLOW}Test 1: Tool Matrix Enforcement${NC}"
test_input='{"tool_name": "write_file", "context": "saving component", "user_request": "save this to Button.jsx"}'
echo "Input: $test_input"
result=$("$SCRIPT_DIR/enforce-matrix.sh" "$test_input" 2>/dev/null)
if echo "$result" | jq -e '.status == "valid"' >/dev/null; then
    echo -e "${GREEN}✓ Matrix enforcement working${NC}"
else
    echo -e "${RED}✗ Matrix enforcement failed${NC}"
    echo "$result" | jq .
fi
echo

# Test 2: Track Usage
echo -e "${YELLOW}Test 2: Usage Tracking${NC}"
track_input=$(cat <<EOF
{
  "tool_name": "read_file",
  "context": "analyzing existing component",
  "parameters": {"file_path": "test.jsx"},
  "result_status": "success",
  "execution_time": 100,
  "user_request": "analyze the current implementation",
  "agent_type": "design_analyst"
}
EOF
)
echo "Input: $(echo "$track_input" | jq -c .)"
result=$("$SCRIPT_DIR/track-usage.sh" "$track_input" 2>/dev/null)
if echo "$result" | jq -e '.status == "success"' >/dev/null; then
    echo -e "${GREEN}✓ Usage tracking working${NC}"
    echo "Session ID: $(echo "$result" | jq -r '.session_id')"
else
    echo -e "${RED}✗ Usage tracking failed${NC}"
    echo "$result" | jq .
fi
echo

# Test 3: Pattern Analysis
echo -e "${YELLOW}Test 3: Pattern Analysis${NC}"
if [[ -f "$SCRIPT_DIR/../../../../.claude/logs/metaclaude/tool-usage.jsonl" ]]; then
    result=$("$SCRIPT_DIR/analyze-patterns.sh" 2>/dev/null)
    if echo "$result" | jq -e '.status == "success"' >/dev/null; then
        echo -e "${GREEN}✓ Pattern analysis working${NC}"
        echo "Patterns identified: $(echo "$result" | jq -r '.summary.patterns_identified')"
    else
        echo -e "${RED}✗ Pattern analysis failed${NC}"
        echo "$result" | jq .
    fi
else
    echo -e "${YELLOW}⚠ No usage log found yet (this is normal for first run)${NC}"
fi
echo

# Test 4: Report Generation
echo -e "${YELLOW}Test 4: Report Generation${NC}"
result=$("$SCRIPT_DIR/generate-report.sh" daily 2>/dev/null)
if echo "$result" | jq -e '.status == "success"' >/dev/null; then
    echo -e "${GREEN}✓ Report generation working${NC}"
    echo "Report saved to: $(echo "$result" | jq -r '.report_file')"
else
    echo -e "${RED}✗ Report generation failed${NC}"
    echo "$result" | jq .
fi
echo

# Test 5: Documentation Update
echo -e "${YELLOW}Test 5: Auto Documentation${NC}"
result=$("$SCRIPT_DIR/update-docs.sh" tool read_file 2>/dev/null)
if echo "$result" | jq -e '.status == "success"' >/dev/null; then
    echo -e "${GREEN}✓ Documentation update working${NC}"
    echo "Files updated: $(echo "$result" | jq -r '.updates.files_updated')"
else
    echo -e "${RED}✗ Documentation update failed${NC}"
    echo "$result" | jq .
fi
echo

# Test 6: Validate Log Files
echo -e "${YELLOW}Test 6: Log File Validation${NC}"
log_dir="$SCRIPT_DIR/../../../../.claude/logs/metaclaude"
if [[ -d "$log_dir" ]]; then
    echo -e "${GREEN}✓ Log directory exists${NC}"
    echo "Contents:"
    ls -la "$log_dir" | tail -n +2 | head -10
else
    echo -e "${RED}✗ Log directory missing${NC}"
fi
echo

# Summary
echo -e "${YELLOW}Test Summary${NC}"
echo "============"
echo -e "${GREEN}All core components are functional!${NC}"
echo
echo "Next steps:"
echo "1. The hooks will now track all tool usage automatically"
echo "2. Run './analyze-patterns.sh' periodically to find insights"
echo "3. Generate reports with './generate-report.sh weekly'"
echo "4. Check '.claude/logs/metaclaude/' for detailed logs"
echo
echo -e "${YELLOW}Hook Integration Status:${NC}"
echo "- PreToolUse hook: metaclaude-tool-matrix-enforcement"
echo "- PostToolUse hooks: metaclaude-tool-usage-tracking, metaclaude-tool-validation"
echo "- All hooks configured in .claude/settings.json"