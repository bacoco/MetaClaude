#!/bin/bash

# MCP Tool Hook for Global Script Registry
# Intercepts use_tool calls and routes to MCP or TES based on tool type

set -e

# Configuration
BRIDGE_SCRIPT="${CLAUDE_SCRIPTS_DIR:-$(dirname "$0")/../core}/mcp-bridge.py"
LOG_FILE="${CLAUDE_LOG_DIR:-/tmp}/mcp-tool-hook.log"
DEBUG="${MCP_HOOK_DEBUG:-0}"

# Color codes for debug output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [ "$DEBUG" -eq 1 ]; then
        case "$level" in
            ERROR) echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
            WARN)  echo -e "${YELLOW}[WARN]${NC} $message" >&2 ;;
            INFO)  echo -e "${BLUE}[INFO]${NC} $message" >&2 ;;
            DEBUG) echo -e "[DEBUG] $message" >&2 ;;
        esac
    fi
}

# Parse use_tool call
parse_tool_call() {
    local tool_name="$1"
    shift
    local params="$*"
    
    log "INFO" "Intercepted tool call: $tool_name"
    log "DEBUG" "Parameters: $params"
    
    # Check if tool exists in registry
    if python3 "$BRIDGE_SCRIPT" list 2>/dev/null | grep -q "^$tool_name "; then
        echo "$tool_name"
        return 0
    else
        log "WARN" "Tool not found in registry: $tool_name"
        return 1
    fi
}

# Execute tool through bridge
execute_tool() {
    local tool_name="$1"
    local params="$2"
    
    log "INFO" "Executing tool: $tool_name"
    
    # Build parameters JSON if needed
    if [ -z "$params" ]; then
        params="{}"
    elif ! echo "$params" | jq . >/dev/null 2>&1; then
        # Convert to JSON if not already
        params=$(echo "$params" | jq -R -s '.')
    fi
    
    # Execute through bridge
    local output
    output=$(python3 "$BRIDGE_SCRIPT" execute "$tool_name" --params "$params" --tes-format 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "INFO" "Tool execution successful"
        echo "$output"
    else
        log "ERROR" "Tool execution failed with code: $exit_code"
        log "ERROR" "Output: $output"
        echo "ERROR: Tool execution failed" >&2
        echo "$output" >&2
        return $exit_code
    fi
}

# Hook entry point
main() {
    # Create log directory if needed
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "INFO" "MCP Tool Hook activated"
    
    # Check if this is a use_tool call
    if [ "$1" == "use_tool" ] || [ "$1" == "--use-tool" ]; then
        shift
        local tool_name="$1"
        shift
        local params="$*"
        
        # Validate tool name
        if [ -z "$tool_name" ]; then
            log "ERROR" "No tool name provided"
            echo "ERROR: Tool name required" >&2
            exit 1
        fi
        
        # Check if tool is registered
        if parse_tool_call "$tool_name" "$params" >/dev/null; then
            # Route to bridge
            execute_tool "$tool_name" "$params"
            exit $?
        else
            # Fallback to default behavior
            log "INFO" "Falling back to default tool handler"
            exec "$@"
        fi
    fi
    
    # Not a use_tool call, pass through
    exec "$@"
}

# Special commands for hook management
case "$1" in
    --install)
        # Install hook into Claude environment
        echo "Installing MCP tool hook..."
        
        # Create hook wrapper
        cat > ~/.claude/hooks/use_tool << 'EOF'
#!/bin/bash
exec "$(dirname "$0")/../../scripts/hooks/mcp-tool-hook.sh" use_tool "$@"
EOF
        chmod +x ~/.claude/hooks/use_tool
        
        echo "MCP tool hook installed successfully"
        exit 0
        ;;
        
    --uninstall)
        # Remove hook
        echo "Uninstalling MCP tool hook..."
        rm -f ~/.claude/hooks/use_tool
        echo "MCP tool hook removed"
        exit 0
        ;;
        
    --status)
        # Check hook status
        if [ -f ~/.claude/hooks/use_tool ]; then
            echo -e "${GREEN}✓ MCP tool hook is installed${NC}"
            
            # Test bridge availability
            if python3 "$BRIDGE_SCRIPT" list >/dev/null 2>&1; then
                echo -e "${GREEN}✓ MCP bridge is available${NC}"
                
                # Count tools
                local mcp_count=$(python3 "$BRIDGE_SCRIPT" list --type mcp 2>/dev/null | grep -c "^[^ ]" || echo 0)
                local tes_count=$(python3 "$BRIDGE_SCRIPT" list --type tes 2>/dev/null | grep -c "^[^ ]" || echo 0)
                
                echo "  MCP tools: $mcp_count"
                echo "  TES tools: $tes_count"
            else
                echo -e "${RED}✗ MCP bridge not available${NC}"
            fi
        else
            echo -e "${RED}✗ MCP tool hook not installed${NC}"
            echo "  Install with: $0 --install"
        fi
        exit 0
        ;;
        
    --test)
        # Test hook functionality
        echo "Testing MCP tool hook..."
        
        # Test logging
        log "TEST" "Hook test initiated"
        echo -e "${GREEN}✓ Logging functional${NC}"
        
        # Test bridge connection
        if python3 "$BRIDGE_SCRIPT" list >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Bridge connection successful${NC}"
        else
            echo -e "${RED}✗ Bridge connection failed${NC}"
            exit 1
        fi
        
        # Test tool execution (if test tool exists)
        if python3 "$BRIDGE_SCRIPT" list 2>/dev/null | grep -q "^test-tool "; then
            if execute_tool "test-tool" '{"test": true}' >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Tool execution successful${NC}"
            else
                echo -e "${YELLOW}⚠ Tool execution failed (may be expected)${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ No test tool available${NC}"
        fi
        
        echo ""
        echo "Hook test completed"
        exit 0
        ;;
esac

# Run main hook logic
main "$@"