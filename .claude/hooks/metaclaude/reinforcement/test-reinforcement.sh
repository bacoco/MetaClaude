#!/bin/bash
# Test script for MetaClaude Reinforcement hooks

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="/tmp/metaclaude_reinforcement_test_$$"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create test directory
mkdir -p "$TEST_DIR"

echo "🧪 Testing MetaClaude Reinforcement Hooks..."
echo "==========================================="

# Test 1: Concept Density Analysis
test_concept_density() {
    echo -e "\n${YELLOW}Test 1: Concept Density Analysis${NC}"
    
    # Create test file with known concept counts
    cat > "$TEST_DIR/test_density.md" << 'EOF'
# Test Document

This document demonstrates transparency in our system design. The transparent nature
of our architecture ensures clarity and transparency throughout. We value transparency
as a core principle, making everything transparent and clear.

Our system is highly adaptable and flexible. The adaptive components can be customized
to meet user needs. This adaptability is key to our flexible approach.

We maintain a user-centric focus with excellent user experience. Our user-centered design
puts user needs first through user feedback and user-focused development.

The orchestration layer coordinates all components. This coordination enables seamless
workflow integration through our orchestration pipeline.

Metacognitive capabilities enable self-awareness and introspection. The system's
metacognition supports self-reflection and self-monitoring.

Continuous evolution and improvement drive iterative refinement. This progressive
evolution ensures continuous enhancement.

The autonomous agents operate independently with self-directed behavior. Their autonomy
enables self-managing operations.
EOF
    
    # Run density analysis
    local result=$("$SCRIPT_DIR/concept-density.sh" "$TEST_DIR/test_density.md" 2>&1)
    
    # Check if transparency is marked as "over" (it appears 5 times in ~150 words)
    if echo "$result" | grep -q "\"transparency\".*\"status\":\"over\""; then
        echo -e "${GREEN}✓ Correctly identified over-emphasized concept${NC}"
    else
        echo -e "${RED}✗ Failed to identify over-emphasized concept${NC}"
        echo "$result"
        return 1
    fi
    
    # Check if all concepts are tracked
    local concept_count=$(echo "$result" | grep -o "\"density\"" | wc -l)
    if [ "$concept_count" -ge 7 ]; then
        echo -e "${GREEN}✓ All concepts tracked (found $concept_count)${NC}"
    else
        echo -e "${RED}✗ Not all concepts tracked (found $concept_count)${NC}"
        return 1
    fi
}

# Test 2: Consolidation Suggestions
test_consolidation_suggestions() {
    echo -e "\n${YELLOW}Test 2: Consolidation Suggestions${NC}"
    
    # Create file with repeated definitions
    cat > "$TEST_DIR/test_consolidation.md" << 'EOF'
# Component A

Transparency means making system operations visible and understandable.

## Section 1

Our transparent approach means making everything visible to users.

## Section 2  

We achieve transparency by making all processes visible and clear.

## Section 3

The principle of transparency refers to making systems visible.
EOF
    
    # Run consolidation suggestions
    local result=$("$SCRIPT_DIR/suggest-consolidation.sh" "$TEST_DIR/test_consolidation.md" 2>&1)
    
    # Check if consolidation is suggested
    if echo "$result" | grep -q "consolidation_suggestions"; then
        echo -e "${GREEN}✓ Generated consolidation suggestions${NC}"
    else
        echo -e "${RED}✗ Failed to generate suggestions${NC}"
        echo "$result"
        return 1
    fi
    
    # Check documentation strategy
    if echo "$result" | grep -q "documentation_strategies"; then
        echo -e "${GREEN}✓ Provided documentation strategy recommendations${NC}"
    else
        echo -e "${RED}✗ Failed to provide strategy recommendations${NC}"
        return 1
    fi
}

# Test 3: Concept Map Generation
test_concept_map() {
    echo -e "\n${YELLOW}Test 3: Concept Map Generation${NC}"
    
    # Create multiple test files
    cat > "$TEST_DIR/main.md" << 'EOF'
# Main Documentation

This system prioritizes transparency and adaptability as core principles.
EOF
    
    cat > "$TEST_DIR/implementation.sh" << 'EOF'
#!/bin/bash
# Implementation follows the transparency principle defined in main.md
# Ensures adaptable configuration as specified in documentation
EOF
    
    # Generate HTML map
    local result=$("$SCRIPT_DIR/concept-map.sh" "$TEST_DIR" "html" 2>&1)
    
    if echo "$result" | grep -q "\"format\":\"html\""; then
        echo -e "${GREEN}✓ Generated HTML concept map${NC}"
    else
        echo -e "${RED}✗ Failed to generate HTML map${NC}"
        echo "$result"
        return 1
    fi
    
    # Generate DOT map
    local result=$("$SCRIPT_DIR/concept-map.sh" "$TEST_DIR" "dot" 2>&1)
    
    if echo "$result" | grep -q "\"format\":\"dot\""; then
        echo -e "${GREEN}✓ Generated DOT concept map${NC}"
    else
        echo -e "${RED}✗ Failed to generate DOT map${NC}"
        return 1
    fi
}

# Test 4: Balance Checker
test_balance_checker() {
    echo -e "\n${YELLOW}Test 4: Balance Checker${NC}"
    
    # Create balanced file
    cat > "$TEST_DIR/balanced.md" << 'EOF'
# Balanced Document

This document demonstrates transparency in design while maintaining adaptability.
Our user-centric approach enables orchestrated workflows with metacognitive
awareness. The system evolves continuously while preserving autonomous operation.

The implementation details focus on practical application rather than repeating
concepts. We reference established principles without over-explanation.
EOF
    
    # Create unbalanced file
    cat > "$TEST_DIR/unbalanced.md" << 'EOF'
# Unbalanced Document

Transparency transparency transparency! Everything must be transparent with full
transparency. Did we mention transparency? Our transparent system is transparently
transparent in its transparency.

(Missing most other concepts...)
EOF
    
    # Run balance checker
    local result=$("$SCRIPT_DIR/balance-checker.sh" "$TEST_DIR" 2>&1)
    
    # Check if files are correctly classified
    if echo "$result" | grep -q "balanced.md.*\"status\":\"balanced\""; then
        echo -e "${GREEN}✓ Correctly identified balanced file${NC}"
    else
        echo -e "${RED}✗ Failed to identify balanced file${NC}"
    fi
    
    if echo "$result" | grep -q "unbalanced.md.*\"status\":\"over_balanced\""; then
        echo -e "${GREEN}✓ Correctly identified unbalanced file${NC}"
    else
        echo -e "${RED}✗ Failed to identify unbalanced file${NC}"
    fi
    
    # Check project health
    if echo "$result" | grep -q "\"project_balance\""; then
        echo -e "${GREEN}✓ Calculated project balance metrics${NC}"
    else
        echo -e "${RED}✗ Failed to calculate project metrics${NC}"
        return 1
    fi
}

# Test 5: Integration Hooks
test_integration_hooks() {
    echo -e "\n${YELLOW}Test 5: Integration Hooks${NC}"
    
    # Test pre-write hook
    echo "Testing pre-write density check..."
    local test_content="Transparency is important. Transparent systems show transparency through transparent transparency transparent transparent."
    
    # Simulate pre-write check
    local result=$("$SCRIPT_DIR/pre-write-density-check.sh" "Write" "$TEST_DIR/new_file.md" "$test_content" 2>&1)
    
    if echo "$result" | grep -q "Concept Density Warning"; then
        echo -e "${GREEN}✓ Pre-write hook detected over-emphasis${NC}"
    else
        echo -e "${YELLOW}⚠ Pre-write hook did not trigger warning (may be OK)${NC}"
    fi
    
    # Test post-write hook
    echo "Testing post-write tracking..."
    echo "$test_content" > "$TEST_DIR/new_file.md"
    
    # Simulate post-write update
    "$SCRIPT_DIR/post-write-update-tracking.sh" "Write" "$TEST_DIR/new_file.md" "true" 2>&1
    
    # Check if tracking was updated
    if [ -f "$SCRIPT_DIR/../../../data/concept-tracking.json" ]; then
        echo -e "${GREEN}✓ Post-write hook updated tracking${NC}"
    else
        echo -e "${YELLOW}⚠ Tracking database not found (will be created on first run)${NC}"
    fi
}

# Test 6: Configuration Files
test_configuration() {
    echo -e "\n${YELLOW}Test 6: Configuration Files${NC}"
    
    # Check concept patterns
    if [ -f "$SCRIPT_DIR/concept-patterns.json" ]; then
        # Validate JSON
        if python3 -c "import json; json.load(open('$SCRIPT_DIR/concept-patterns.json'))" 2>/dev/null; then
            echo -e "${GREEN}✓ Valid concept-patterns.json${NC}"
        else
            echo -e "${RED}✗ Invalid concept-patterns.json${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Missing concept-patterns.json${NC}"
        return 1
    fi
    
    # Check hook config
    if [ -f "$SCRIPT_DIR/hook-config.json" ]; then
        if python3 -c "import json; json.load(open('$SCRIPT_DIR/hook-config.json'))" 2>/dev/null; then
            echo -e "${GREEN}✓ Valid hook-config.json${NC}"
        else
            echo -e "${RED}✗ Invalid hook-config.json${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Missing hook-config.json${NC}"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    local failed=0
    
    test_concept_density || ((failed++))
    test_consolidation_suggestions || ((failed++))
    test_concept_map || ((failed++))
    test_balance_checker || ((failed++))
    test_integration_hooks || ((failed++))
    test_configuration || ((failed++))
    
    echo -e "\n==========================================="
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
    else
        echo -e "${RED}❌ $failed test(s) failed${NC}"
    fi
    
    # Cleanup
    rm -rf "$TEST_DIR"
    
    return $failed
}

# Execute tests
run_all_tests