#!/bin/bash
# Test script for MetaClaude coordination layer

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test helpers
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Test broadcast system
test_broadcast_system() {
    log_test "Testing broadcast system..."
    
    # Create test subscription
    export AGENT_ID="test_agent_001"
    export AGENT_TYPE="researcher"
    
    ./subscribe.sh create "$AGENT_ID" "$AGENT_TYPE" "task,state,conflict"
    
    # Broadcast test message
    export TOOL_NAME="TestTool"
    export TOOL_OUTPUT="Test broadcast message"
    ./broadcast.sh
    
    # Read message
    local messages=$(./subscribe.sh read "$AGENT_ID" 1)
    if [[ "$messages" =~ "Test broadcast message" ]]; then
        log_success "Broadcast system working"
    else
        log_fail "Broadcast system failed"
    fi
    
    # Cleanup
    ./subscribe.sh remove "$AGENT_ID"
}

# Test state management
test_state_management() {
    log_test "Testing state management..."
    
    # Set state
    ./state-manager.sh set test_key '{"value": "test_data"}' test_namespace
    
    # Get state
    local value=$(./state-manager.sh get test_key test_namespace)
    if [[ "$value" =~ "test_data" ]]; then
        log_success "State set/get working"
    else
        log_fail "State set/get failed"
    fi
    
    # Update state
    ./state-manager.sh update test_key '.value = "updated_data"' test_namespace
    value=$(./state-manager.sh get test_key test_namespace)
    if [[ "$value" =~ "updated_data" ]]; then
        log_success "State update working"
    else
        log_fail "State update failed"
    fi
    
    # Create snapshot
    local snapshot=$(./state-manager.sh snapshot test_namespace "Test snapshot")
    if [[ -f "$snapshot" ]]; then
        log_success "Snapshot creation working"
    else
        log_fail "Snapshot creation failed"
    fi
    
    # Cleanup
    ./state-manager.sh delete test_key test_namespace
}

# Test conflict detection
test_conflict_detection() {
    log_test "Testing conflict detection..."
    
    # Agent 1 claims resource
    export AGENT_ID="test_coder_001"
    ./detect-conflicts.sh claim file "/test/file.js" "$AGENT_ID" modify 60
    
    # Agent 2 tries to claim same resource
    export AGENT_ID="test_coder_002"
    if ! ./detect-conflicts.sh claim file "/test/file.js" "$AGENT_ID" modify 60 2>/dev/null; then
        log_success "Conflict detection working"
    else
        log_fail "Conflict detection failed"
    fi
    
    # List conflicts
    local conflicts=$(./detect-conflicts.sh list)
    if [[ "$conflicts" =~ "resource_contention" ]]; then
        log_success "Conflict listing working"
    else
        log_fail "Conflict listing failed"
    fi
    
    # Cleanup
    ./detect-conflicts.sh cleanup 0
}

# Test conflict resolution
test_conflict_resolution() {
    log_test "Testing conflict resolution..."
    
    # Find active conflicts
    local conflict_file=$(find "${CLAUDE_LOGS_DIR}/metaclaude/conflicts/active" -name "*.conflict" | head -1)
    
    if [[ -f "$conflict_file" ]]; then
        # Resolve conflict
        ./resolve-conflicts.sh resolve "$conflict_file" auto
        
        # Check if resolved
        if [[ ! -f "$conflict_file" ]]; then
            log_success "Conflict resolution working"
        else
            log_fail "Conflict resolution failed"
        fi
    else
        log_info "No conflicts to resolve"
    fi
}

# Test role enforcement
test_role_enforcement() {
    log_test "Testing role enforcement..."
    
    # Test orchestrator forbidden tool
    local result=$(./role-enforcer.sh check orchestrator Write)
    if [[ "$result" =~ "FORBIDDEN" ]]; then
        log_success "Role enforcement working (forbidden tool)"
    else
        log_fail "Role enforcement failed (should forbid)"
    fi
    
    # Test coder allowed tool
    result=$(./role-enforcer.sh check coder Write)
    if [[ "$result" =~ "ALLOWED" ]]; then
        log_success "Role enforcement working (allowed tool)"
    else
        log_fail "Role enforcement failed (should allow)"
    fi
    
    # Test role configuration
    local role_config=$(./role-enforcer.sh role orchestrator)
    if [[ "$role_config" =~ "orchestration" ]]; then
        log_success "Role configuration working"
    else
        log_fail "Role configuration failed"
    fi
}

# Test state synchronization
test_state_sync() {
    log_test "Testing state synchronization..."
    
    # Agent 1 syncs state
    export AGENT_ID="sync_agent_001"
    ./state-sync.sh sync test_sync sync_key '{"data": "agent1"}' "$AGENT_ID"
    
    # Agent 2 syncs different value
    export AGENT_ID="sync_agent_002"
    ./state-sync.sh sync test_sync sync_key '{"data": "agent2"}' "$AGENT_ID"
    
    # Process sync queue
    ./state-sync.sh process test_sync
    
    # Check for conflicts or resolution
    local sync_status=$(./state-sync.sh status)
    if [[ "$sync_status" =~ "processed" ]]; then
        log_success "State sync working"
    else
        log_fail "State sync failed"
    fi
}

# Integration test
test_integration() {
    log_test "Testing coordination integration..."
    
    # Simulate orchestrator delegating to coder
    export AGENT_TYPE="orchestrator"
    export AGENT_ID="orch_001"
    export TOOL_NAME="Task"
    export TOOL_OUTPUT='{"agent_type": "coder", "task": "implement feature"}'
    
    # This should pass role enforcement
    if ./role-enforcer.sh check orchestrator Task | grep -q "ALLOWED"; then
        log_success "Orchestrator can delegate"
    else
        log_fail "Orchestrator delegation blocked"
    fi
    
    # Broadcast the delegation
    ./broadcast.sh
    
    # Subscribe as coder
    export AGENT_ID="coder_001"
    export AGENT_TYPE="coder"
    ./subscribe.sh create "$AGENT_ID" "$AGENT_TYPE" "coordination"
    
    # Read delegation message
    local delegation=$(./subscribe.sh read "$AGENT_ID" 1)
    if [[ "$delegation" =~ "implement feature" ]]; then
        log_success "Integration working"
    else
        log_fail "Integration failed"
    fi
    
    # Cleanup
    ./subscribe.sh remove "$AGENT_ID"
}

# Performance test
test_performance() {
    log_test "Testing coordination performance..."
    
    local start_time=$(date +%s.%N)
    
    # Rapid state updates
    for i in {1..10}; do
        ./state-manager.sh set "perf_test_$i" "$i" perf_test
    done
    
    # Rapid broadcasts
    for i in {1..10}; do
        export TOOL_OUTPUT="Performance test $i"
        ./broadcast.sh
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    log_info "Performance test completed in ${duration}s"
    
    # Cleanup
    for i in {1..10}; do
        ./state-manager.sh delete "perf_test_$i" perf_test 2>/dev/null || true
    done
}

# Main test runner
main() {
    log_info "Starting MetaClaude Coordination Layer Tests"
    echo ""
    
    # Change to coordination directory
    cd "$(dirname "$0")"
    
    # Source common utilities
    export CLAUDE_LOGS_DIR="${CLAUDE_LOGS_DIR:-/tmp/claude-logs}"
    export CLAUDE_HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$(dirname "$(dirname "$0")")}"
    
    # Run tests
    test_broadcast_system
    echo ""
    
    test_state_management
    echo ""
    
    test_conflict_detection
    echo ""
    
    test_conflict_resolution
    echo ""
    
    test_role_enforcement
    echo ""
    
    test_state_sync
    echo ""
    
    test_integration
    echo ""
    
    test_performance
    echo ""
    
    log_info "All tests completed!"
}

# Execute tests
main "$@"