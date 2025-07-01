#!/bin/bash
# Quick validation script for MetaClaude reinforcement balance

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}MetaClaude Reinforcement Balance Validator${NC}"
echo "=========================================="

# Function to display summary
display_summary() {
    local target="${1:-.}"
    
    echo -e "\n${YELLOW}Analyzing: $target${NC}"
    
    # Run balance check
    local balance_result=$("$SCRIPT_DIR/balance-checker.sh" "$target" 2>/dev/null)
    
    # Extract project health
    local health=$(echo "$balance_result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data['project_balance']['health'])
except:
    print('unknown')
" 2>/dev/null || echo "unknown")
    
    local balance_pct=$(echo "$balance_result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(f\"{data['project_balance']['balance_percentage']:.1f}%\")
except:
    print('N/A')
" 2>/dev/null || echo "N/A")
    
    # Display health status
    case "$health" in
        "good")
            echo -e "${GREEN}✅ Project Balance: GOOD ($balance_pct balanced)${NC}"
            ;;
        "fair")
            echo -e "${YELLOW}⚠️  Project Balance: FAIR ($balance_pct balanced)${NC}"
            ;;
        "poor")
            echo -e "${RED}❌ Project Balance: POOR ($balance_pct balanced)${NC}"
            ;;
        *)
            echo -e "${RED}❓ Project Balance: UNKNOWN${NC}"
            ;;
    esac
    
    # Show top issues
    echo -e "\n${YELLOW}Top Issues:${NC}"
    echo "$balance_result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    issues = []
    
    # Collect all issues
    for analysis in data['balance_analysis']:
        file = analysis['file']
        for issue in analysis.get('issues', []):
            concept = issue['concept']
            issue_type = issue['issue']
            issues.append((file, concept, issue_type))
    
    # Display top 5
    if issues:
        for i, (file, concept, issue_type) in enumerate(issues[:5]):
            issue_desc = 'Over-emphasized' if 'over' in issue_type else 'Under-emphasized'
            print(f'  {i+1}. {file}: {concept} is {issue_desc}')
    else:
        print('  ✓ No significant issues found')
        
except Exception as e:
    print(f'  Error parsing results: {e}')
" 2>/dev/null
    
    # Show recommendations
    echo -e "\n${YELLOW}Recommendations:${NC}"
    echo "$balance_result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    recs = data.get('recommendations', [])
    
    if recs:
        shown = set()
        for rec in recs[:3]:
            action = rec.get('action', 'unknown')
            suggestion = rec.get('suggestion', '')
            if suggestion not in shown:
                print(f'  • {suggestion}')
                shown.add(suggestion)
    else:
        print('  ✓ No specific recommendations')
        
except:
    print('  Error parsing recommendations')
" 2>/dev/null
}

# Function to show quick stats
show_quick_stats() {
    local target="${1:-.}"
    
    echo -e "\n${YELLOW}Quick Statistics:${NC}"
    
    # Count files
    local total_files=$(find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | grep -v node_modules | grep -v .git | wc -l)
    echo "  Total analyzable files: $total_files"
    
    # Run density check for most mentioned concepts
    local density_result=$("$SCRIPT_DIR/concept-density.sh" "$target" 2>/dev/null)
    
    echo -e "\n${YELLOW}Concept Distribution:${NC}"
    echo "$density_result" | python3 -c "
import json, sys
from collections import defaultdict

try:
    data = json.loads(sys.stdin.read())
    concept_counts = defaultdict(int)
    
    for item in data.get('analysis', []):
        for concept, details in item.get('concepts', {}).items():
            concept_counts[concept] += details.get('count', 0)
    
    # Sort by count
    sorted_concepts = sorted(concept_counts.items(), key=lambda x: x[1], reverse=True)
    
    for concept, count in sorted_concepts:
        print(f'  • {concept}: {count} total mentions')
        
except:
    print('  Error calculating distribution')
" 2>/dev/null
}

# Main execution
main() {
    local target="${1:-.}"
    local mode="${2:-summary}"  # summary or full
    
    if [ "$mode" = "full" ]; then
        # Run all checks
        display_summary "$target"
        show_quick_stats "$target"
        
        echo -e "\n${YELLOW}Next Steps:${NC}"
        echo "  1. Review files with issues using: $SCRIPT_DIR/concept-density.sh <file>"
        echo "  2. Get consolidation suggestions: $SCRIPT_DIR/suggest-consolidation.sh <file>"
        echo "  3. Visualize concept distribution: $SCRIPT_DIR/concept-map.sh"
    else
        # Quick summary only
        display_summary "$target"
    fi
    
    echo -e "\n=========================================="
}

# Execute
main "$@"