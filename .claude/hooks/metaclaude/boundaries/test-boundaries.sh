#!/bin/bash
# Test script for MetaClaude Boundary System

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "MetaClaude Boundary System Test Suite"
echo "===================================="
echo ""

# Test 1: Permission validation for allowed operation
echo "Test 1: UI Generator writing JSX file (should be allowed)"
if METACLAUDE_AGENT_TYPE="ui_generator" \
   METACLAUDE_OPERATION="tool:Write" \
   METACLAUDE_RESOURCE="Button.jsx" \
   "${SCRIPT_DIR}/validate-permissions.sh" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}: UI Generator can write JSX files"
else
    echo -e "${RED}✗ FAIL${NC}: UI Generator should be able to write JSX files"
fi

# Test 2: Permission validation for blocked operation
echo ""
echo "Test 2: Design Analyst writing system config (should be blocked)"
if METACLAUDE_AGENT_TYPE="design_analyst" \
   METACLAUDE_OPERATION="file:write" \
   METACLAUDE_RESOURCE=".claude/settings.json" \
   "${SCRIPT_DIR}/validate-permissions.sh" >/dev/null 2>&1; then
    echo -e "${RED}✗ FAIL${NC}: Design Analyst should not write system files"
else
    echo -e "${GREEN}✓ PASS${NC}: Design Analyst blocked from writing system files"
fi

# Test 3: Handoff tracking
echo ""
echo "Test 3: Tracking agent handoff"
HANDOFF_ID=$("${SCRIPT_DIR}/track-handoff.sh" track style_guide_expert ui_generator "share_tokens" "design_tokens")
if [ -n "${HANDOFF_ID}" ]; then
    echo -e "${GREEN}✓ PASS${NC}: Handoff tracked with ID: ${HANDOFF_ID}"
else
    echo -e "${RED}✗ FAIL${NC}: Failed to track handoff"
fi

# Test 4: Wildcard tool permission
echo ""
echo "Test 4: Orchestrator using any tool (wildcard permission)"
if METACLAUDE_AGENT_TYPE="orchestrator" \
   METACLAUDE_OPERATION="tool:AnyRandomTool" \
   METACLAUDE_RESOURCE="anything" \
   "${SCRIPT_DIR}/validate-permissions.sh" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}: Orchestrator has wildcard tool access"
else
    echo -e "${RED}✗ FAIL${NC}: Orchestrator should have wildcard tool access"
fi

# Test 5: Memory namespace validation
echo ""
echo "Test 5: Style Guide Expert writing to design_tokens namespace"
if METACLAUDE_AGENT_TYPE="style_guide_expert" \
   METACLAUDE_OPERATION="memory:write" \
   METACLAUDE_RESOURCE="design_tokens" \
   "${SCRIPT_DIR}/validate-permissions.sh" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}: Style Guide Expert can write design tokens"
else
    echo -e "${RED}✗ FAIL${NC}: Style Guide Expert should write design tokens"
fi

# Test 6: Cross-agent communication
echo ""
echo "Test 6: Agent communication permission"
if METACLAUDE_AGENT_TYPE="ux_researcher" \
   METACLAUDE_OPERATION="agent:communicate" \
   METACLAUDE_RESOURCE="ui_generator" \
   "${SCRIPT_DIR}/validate-permissions.sh" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}: UX Researcher can communicate with other agents"
else
    echo -e "${RED}✗ FAIL${NC}: UX Researcher should be able to communicate"
fi

# Test 7: Visualization generation
echo ""
echo "Test 7: Generating boundary visualization"
if "${SCRIPT_DIR}/visualize-boundaries.sh" boundaries >/dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}: Boundary visualization generated"
else
    echo -e "${RED}✗ FAIL${NC}: Failed to generate visualization"
fi

# Test 8: Permission matrix integrity
echo ""
echo "Test 8: Checking permission matrix integrity"
if jq empty "${SCRIPT_DIR}/permission-matrix.json" 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}: Permission matrix is valid JSON"
else
    echo -e "${RED}✗ FAIL${NC}: Permission matrix has invalid JSON"
fi

echo ""
echo "Test Summary Complete"
echo ""
echo "To view detailed logs:"
echo "  - Permission validations: cat .claude/logs/metaclaude/permission-validations.jsonl | jq"
echo "  - Handoffs: cat .claude/logs/metaclaude/handoffs.jsonl | jq"
echo ""
echo "To visualize boundaries:"
echo "  - ${SCRIPT_DIR}/visualize-boundaries.sh all"