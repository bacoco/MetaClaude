#!/bin/bash
# MetaClaude Boundary Visualization
# Generates text diagrams of agent boundaries and interactions

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERMISSION_MATRIX="${SCRIPT_DIR}/permission-matrix.json"
LOG_DIR="${SCRIPT_DIR}/../../../logs/metaclaude"
HANDOFF_LOG="${LOG_DIR}/handoffs.jsonl"

# ANSI color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to draw a box around text
draw_box() {
    local title="$1"
    local content="$2"
    local color="${3:-${NC}}"
    local width=60
    
    # Top border
    echo -e "${color}┌$(printf '─%.0s' $(seq 1 $((width-2))))┐${NC}"
    
    # Title
    local title_padding=$(( (width - ${#title} - 2) / 2 ))
    echo -e "${color}│$(printf ' %.0s' $(seq 1 ${title_padding}))${title}$(printf ' %.0s' $(seq 1 $((width - title_padding - ${#title} - 2))))│${NC}"
    
    # Separator
    echo -e "${color}├$(printf '─%.0s' $(seq 1 $((width-2))))┤${NC}"
    
    # Content
    while IFS= read -r line; do
        local line_length=${#line}
        local padding=$((width - line_length - 2))
        echo -e "${color}│ ${line}$(printf ' %.0s' $(seq 1 ${padding}))│${NC}"
    done <<< "${content}"
    
    # Bottom border
    echo -e "${color}└$(printf '─%.0s' $(seq 1 $((width-2))))┘${NC}"
}

# Function to visualize agent boundaries
visualize_agent_boundaries() {
    echo "MetaClaude Agent Boundary Visualization"
    echo "======================================"
    echo ""
    
    # Extract agent types from permission matrix
    local agents=$(jq -r '.agent_types | keys[]' "${PERMISSION_MATRIX}" 2>/dev/null)
    
    # Orchestrator at the center
    echo "                    ┌─────────────────────┐"
    echo "                    │   ORCHESTRATOR      │"
    echo "                    │   (System Scope)    │"
    echo "                    └──────────┬──────────┘"
    echo "                               │"
    echo "          ┌────────────────────┼────────────────────┐"
    echo "          │                    │                    │"
    echo "          ▼                    ▼                    ▼"
    
    # Specialist agents
    echo "┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐"
    echo "│ DESIGN ANALYST  │  │ STYLE GUIDE     │  │ UI GENERATOR    │"
    echo "│ (Analysis)      │  │ (Design System) │  │ (Implementation)│"
    echo "└─────────────────┘  └─────────────────┘  └─────────────────┘"
    echo ""
    echo "┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐"
    echo "│ UX RESEARCHER   │  │ BRAND           │  │ ACCESSIBILITY   │"
    echo "│ (Research)      │  │ STRATEGIST      │  │ AUDITOR         │"
    echo "│                 │  │ (Strategy)      │  │ (Quality)       │"
    echo "└─────────────────┘  └─────────────────┘  └─────────────────┘"
    echo ""
}

# Function to show permission summary for an agent
show_agent_permissions() {
    local agent_type="${1}"
    
    local permissions=$(jq -r ".agent_types.\"${agent_type}\"" "${PERMISSION_MATRIX}" 2>/dev/null)
    
    if [ "${permissions}" = "null" ]; then
        echo "Unknown agent type: ${agent_type}"
        return 1
    fi
    
    local description=$(echo "${permissions}" | jq -r '.description')
    local scope=$(echo "${permissions}" | jq -r '.scope')
    
    # Build content
    local content="Scope: ${scope}\n"
    content+="\nAllowed Tools:\n"
    content+=$(echo "${permissions}" | jq -r '.permissions.tools[]' | sed 's/^/  • /')
    content+="\n\nAgent Operations:\n"
    content+=$(echo "${permissions}" | jq -r '.permissions.agents[]' | sed 's/^/  • /')
    content+="\n\nMemory Access:\n"
    content+=$(echo "${permissions}" | jq -r '.permissions.memory[]' | sed 's/^/  • /')
    
    # Choose color based on scope
    local color="${CYAN}"
    case "${scope}" in
        "system") color="${RED}" ;;
        "quality") color="${GREEN}" ;;
        "strategy") color="${PURPLE}" ;;
        "implementation") color="${BLUE}" ;;
        "research") color="${YELLOW}" ;;
    esac
    
    draw_box "${agent_type^^}: ${description}" "${content}" "${color}"
}

# Function to visualize recent handoffs
visualize_handoffs() {
    echo ""
    echo "Recent Agent Handoffs"
    echo "===================="
    echo ""
    
    if [ ! -f "${HANDOFF_LOG}" ]; then
        echo "No handoffs recorded yet."
        return
    fi
    
    # Get last 10 handoffs
    local handoffs=$(tail -n 10 "${HANDOFF_LOG}" | jq -s '.')
    
    if [ "${handoffs}" = "[]" ]; then
        echo "No handoffs recorded yet."
        return
    fi
    
    echo "Time        Source Agent      →  Target Agent       Operation           Status"
    echo "────────────────────────────────────────────────────────────────────────────"
    
    echo "${handoffs}" | jq -r '.[] | 
        select(.source_agent and .target_agent) |
        [
            (.timestamp | split("T")[1] | split(".")[0]),
            (.source_agent | .[0:15]),
            "→",
            (.target_agent | .[0:15]),
            (.operation | .[0:18]),
            .status
        ] | @tsv' | column -t
}

# Function to show boundary violations
show_violations() {
    local validation_log="${LOG_DIR}/permission-validations.jsonl"
    
    echo ""
    echo "Recent Boundary Violations"
    echo "========================="
    echo ""
    
    if [ ! -f "${validation_log}" ]; then
        echo "No violations recorded."
        return
    fi
    
    # Get blocked operations
    local violations=$(grep '"result":"blocked"' "${validation_log}" | tail -n 10 | jq -s '.')
    
    if [ "${violations}" = "[]" ]; then
        echo "No violations recorded."
        return
    fi
    
    echo -e "${RED}Time        Agent             Operation         Resource           Reason${NC}"
    echo "────────────────────────────────────────────────────────────────────────"
    
    echo "${violations}" | jq -r '.[] | 
        [
            (.timestamp | split("T")[1] | split(".")[0]),
            .agent,
            .operation,
            .resource,
            .reason
        ] | @tsv' | column -t
}

# Function to generate interaction matrix
generate_interaction_matrix() {
    echo ""
    echo "Agent Interaction Matrix"
    echo "======================="
    echo ""
    
    # Get all agent types
    local agents=($(jq -r '.agent_types | keys[]' "${PERMISSION_MATRIX}" 2>/dev/null))
    
    # Header
    printf "%-20s" "FROM \\ TO"
    for target in "${agents[@]}"; do
        printf "%-15s" "${target:0:13}"
    done
    echo ""
    
    # Separator
    printf "%-20s" "────────────"
    for target in "${agents[@]}"; do
        printf "%-15s" "─────────────"
    done
    echo ""
    
    # Matrix
    for source in "${agents[@]}"; do
        printf "%-20s" "${source:0:18}"
        for target in "${agents[@]}"; do
            if [ "${source}" = "${target}" ]; then
                printf "%-15s" "SELF"
            else
                # Check delegation rules
                local rule="?"
                if [ "${source}" = "orchestrator" ]; then
                    rule="✓ ALLOWED"
                elif [ "${target}" = "orchestrator" ]; then
                    rule="→ REQUEST"
                else
                    rule="⚠ APPROVAL"
                fi
                printf "%-15s" "${rule}"
            fi
        done
        echo ""
    done
}

# Main function
main() {
    local command="${1:-all}"
    
    case "${command}" in
        "boundaries")
            visualize_agent_boundaries
            ;;
        "agent")
            if [ $# -lt 2 ]; then
                echo "Usage: $0 agent <agent_type>" >&2
                exit 1
            fi
            show_agent_permissions "${2}"
            ;;
        "handoffs")
            visualize_handoffs
            ;;
        "violations")
            show_violations
            ;;
        "matrix")
            generate_interaction_matrix
            ;;
        "all")
            visualize_agent_boundaries
            echo ""
            generate_interaction_matrix
            echo ""
            visualize_handoffs
            echo ""
            show_violations
            ;;
        *)
            echo "Usage: $0 {boundaries|agent|handoffs|violations|matrix|all} [args...]" >&2
            echo "" >&2
            echo "Commands:" >&2
            echo "  boundaries    - Show agent boundary diagram" >&2
            echo "  agent <type>  - Show permissions for specific agent" >&2
            echo "  handoffs      - Show recent agent handoffs" >&2
            echo "  violations    - Show recent boundary violations" >&2
            echo "  matrix        - Show agent interaction matrix" >&2
            echo "  all           - Show all visualizations" >&2
            exit 1
            ;;
    esac
}

# Run main function
main "$@"