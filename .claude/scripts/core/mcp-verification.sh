#!/bin/bash

# MCP Verification Script for Global Script Registry
# Verifies MCP CLI installation and tests server connectivity

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Exit codes
EXIT_SUCCESS=0
EXIT_MCP_NOT_INSTALLED=1
EXIT_NO_SERVERS=2
EXIT_CONNECTION_FAILED=3

echo -e "${BLUE}=== MCP Verification Tool ===${NC}"
echo ""

# Step 1: Check if MCP CLI is installed
echo -e "${YELLOW}[1/4] Checking MCP CLI installation...${NC}"
if npx @modelcontextprotocol/cli --version &>/dev/null; then
    MCP_VERSION=$(npx @modelcontextprotocol/cli --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ MCP CLI installed (version: ${MCP_VERSION})${NC}"
else
    echo -e "${RED}✗ MCP CLI not found${NC}"
    echo "  Install with: npm install -g @modelcontextprotocol/cli"
    exit $EXIT_MCP_NOT_INSTALLED
fi

# Step 2: List available MCP servers
echo ""
echo -e "${YELLOW}[2/4] Listing available MCP servers...${NC}"
SERVERS=$(npx @modelcontextprotocol/cli list 2>/dev/null || echo "")

if [ -z "$SERVERS" ]; then
    echo -e "${RED}✗ No MCP servers configured${NC}"
    echo "  Configure servers in your MCP configuration file"
    exit $EXIT_NO_SERVERS
else
    echo -e "${GREEN}✓ Found MCP servers:${NC}"
    echo "$SERVERS" | while IFS= read -r server; do
        echo "  - $server"
    done
fi

# Step 3: Test connectivity to each server
echo ""
echo -e "${YELLOW}[3/4] Testing server connectivity...${NC}"
CONNECTION_FAILED=0

# Parse server list and test each one
echo "$SERVERS" | while IFS= read -r server; do
    if [ -n "$server" ]; then
        SERVER_NAME=$(echo "$server" | awk '{print $1}')
        echo -n "  Testing $SERVER_NAME... "
        
        # Attempt to ping or connect to the server
        if npx @modelcontextprotocol/cli test "$SERVER_NAME" &>/dev/null; then
            echo -e "${GREEN}✓ Connected${NC}"
        else
            echo -e "${RED}✗ Failed${NC}"
            CONNECTION_FAILED=1
        fi
    fi
done

# Step 4: Generate status report
echo ""
echo -e "${YELLOW}[4/4] Status Report${NC}"
echo "================================"
echo "MCP CLI Version: ${MCP_VERSION}"
echo "Total Servers: $(echo "$SERVERS" | wc -l | tr -d ' ')"
echo "Connection Status: $([ $CONNECTION_FAILED -eq 0 ] && echo -e "${GREEN}All servers reachable${NC}" || echo -e "${RED}Some servers unreachable${NC}")"
echo "================================"

# Additional diagnostics
if [ "$1" == "--verbose" ] || [ "$1" == "-v" ]; then
    echo ""
    echo -e "${YELLOW}Verbose Diagnostics:${NC}"
    echo "MCP Config Location: $(npx @modelcontextprotocol/cli config path 2>/dev/null || echo "unknown")"
    echo "Node Version: $(node --version)"
    echo "NPM Version: $(npm --version)"
    echo ""
    echo "MCP Environment Variables:"
    env | grep -i MCP_ || echo "  (none found)"
fi

# Exit with appropriate code
if [ $CONNECTION_FAILED -ne 0 ]; then
    echo ""
    echo -e "${RED}⚠ Some servers failed connectivity tests${NC}"
    exit $EXIT_CONNECTION_FAILED
fi

echo ""
echo -e "${GREEN}✓ All MCP components verified successfully${NC}"
exit $EXIT_SUCCESS