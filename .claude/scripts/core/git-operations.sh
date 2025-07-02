#!/bin/bash

# Git Operations Helper
# Common git operations for MetaClaude specialists

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
OPERATION=""
BRANCH_NAME=""
COMMIT_MESSAGE=""
REMOTE="origin"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 OPERATION [OPTIONS]

Common git operations for MetaClaude workflows.

Operations:
    check-status         Check git repository status
    create-branch        Create and checkout new branch
    safe-commit         Commit with pre-checks
    push-branch         Push branch with upstream tracking
    check-conflicts     Check for merge conflicts
    stash-changes       Stash current changes
    
Options:
    --branch NAME       Branch name (for create-branch, push-branch)
    --message MSG       Commit message (for safe-commit)
    --remote REMOTE     Remote name (default: origin)
    --include-all       Include all changes in commit

Examples:
    # Check repository status
    $0 check-status
    
    # Create new feature branch
    $0 create-branch --branch feature/new-ui
    
    # Safe commit with checks
    $0 safe-commit --message "Add validation logic"
    
    # Push branch with tracking
    $0 push-branch --branch feature/new-ui

EOF
    exit 0
}

# Parse command line arguments
if [[ $# -eq 0 ]]; then
    usage
fi

OPERATION="$1"
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            BRANCH_NAME="$2"
            shift 2
            ;;
        --message)
            COMMIT_MESSAGE="$2"
            shift 2
            ;;
        --remote)
            REMOTE="$2"
            shift 2
            ;;
        --include-all)
            INCLUDE_ALL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Operation functions

check_status() {
    echo -e "${BLUE}Git Repository Status:${NC}"
    echo
    
    # Current branch
    CURRENT_BRANCH=$(git branch --show-current)
    echo -e "${GREEN}Current branch:${NC} $CURRENT_BRANCH"
    
    # Check if branch is up to date
    git fetch --quiet
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "none")
    BASE=$(git merge-base @ @{u} 2>/dev/null || echo "none")
    
    if [[ "$REMOTE" == "none" ]]; then
        echo -e "${YELLOW}Branch has no upstream${NC}"
    elif [[ "$LOCAL" == "$REMOTE" ]]; then
        echo -e "${GREEN}Branch is up to date${NC}"
    elif [[ "$LOCAL" == "$BASE" ]]; then
        echo -e "${YELLOW}Branch is behind upstream${NC}"
    elif [[ "$REMOTE" == "$BASE" ]]; then
        echo -e "${YELLOW}Branch is ahead of upstream${NC}"
    else
        echo -e "${RED}Branch has diverged from upstream${NC}"
    fi
    
    # Uncommitted changes
    echo
    if [[ -n $(git status --porcelain) ]]; then
        echo -e "${YELLOW}Uncommitted changes:${NC}"
        git status --short
    else
        echo -e "${GREEN}No uncommitted changes${NC}"
    fi
    
    # Output parseable data
    echo
    echo "branch=$CURRENT_BRANCH"
    echo "has_changes=$(if [[ -n $(git status --porcelain) ]]; then echo true; else echo false; fi)"
    echo "is_clean=$(if [[ -z $(git status --porcelain) ]]; then echo true; else echo false; fi)"
}

create_branch() {
    if [[ -z "$BRANCH_NAME" ]]; then
        echo -e "${RED}Error: Branch name required${NC}"
        echo "Use: $0 create-branch --branch NAME"
        exit 1
    fi
    
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo -e "${RED}Error: Branch '$BRANCH_NAME' already exists${NC}"
        exit 1
    fi
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
        read -p "Stash changes before creating branch? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git stash push -m "Auto-stash before creating branch $BRANCH_NAME"
            echo -e "${GREEN}Changes stashed${NC}"
        fi
    fi
    
    # Create and checkout branch
    echo -e "${BLUE}Creating branch: $BRANCH_NAME${NC}"
    git checkout -b "$BRANCH_NAME"
    
    echo -e "${GREEN}✓ Branch created and checked out${NC}"
    echo "branch=$BRANCH_NAME"
    echo "created=true"
}

safe_commit() {
    if [[ -z "$COMMIT_MESSAGE" ]]; then
        echo -e "${RED}Error: Commit message required${NC}"
        echo "Use: $0 safe-commit --message MSG"
        exit 1
    fi
    
    # Check for changes
    if [[ -z $(git status --porcelain) ]]; then
        echo -e "${YELLOW}No changes to commit${NC}"
        echo "has_changes=false"
        exit 0
    fi
    
    # Run pre-commit checks if available
    if [[ -f .pre-commit-config.yaml ]]; then
        echo -e "${BLUE}Running pre-commit checks...${NC}"
        if ! pre-commit run --all-files; then
            echo -e "${RED}Pre-commit checks failed${NC}"
            echo "pre_commit_passed=false"
            exit 1
        fi
    fi
    
    # Stage changes
    if [[ "${INCLUDE_ALL:-false}" == "true" ]]; then
        git add -A
    else
        git add -u
    fi
    
    # Commit
    echo -e "${BLUE}Committing changes...${NC}"
    git commit -m "$COMMIT_MESSAGE"
    
    COMMIT_HASH=$(git rev-parse HEAD)
    echo -e "${GREEN}✓ Changes committed${NC}"
    echo "committed=true"
    echo "commit_hash=$COMMIT_HASH"
}

push_branch() {
    if [[ -z "$BRANCH_NAME" ]]; then
        BRANCH_NAME=$(git branch --show-current)
    fi
    
    echo -e "${BLUE}Pushing branch: $BRANCH_NAME${NC}"
    
    # Check if branch has upstream
    if ! git rev-parse --abbrev-ref "$BRANCH_NAME@{upstream}" > /dev/null 2>&1; then
        echo -e "${YELLOW}Setting upstream tracking${NC}"
        git push -u "$REMOTE" "$BRANCH_NAME"
    else
        git push
    fi
    
    echo -e "${GREEN}✓ Branch pushed${NC}"
    echo "pushed=true"
    echo "branch=$BRANCH_NAME"
    echo "remote=$REMOTE"
}

check_conflicts() {
    BASE_BRANCH="${1:-main}"
    CURRENT_BRANCH=$(git branch --show-current)
    
    echo -e "${BLUE}Checking for conflicts with $BASE_BRANCH${NC}"
    
    # Fetch latest
    git fetch "$REMOTE" "$BASE_BRANCH"
    
    # Test merge
    git merge-tree $(git merge-base HEAD "$REMOTE/$BASE_BRANCH") HEAD "$REMOTE/$BASE_BRANCH" > /tmp/merge-test 2>&1
    
    if grep -q "<<<<<<< " /tmp/merge-test; then
        echo -e "${RED}Merge conflicts detected${NC}"
        echo "has_conflicts=true"
        echo "conflicted_files=$(grep -l '<<<<<<< ' /tmp/merge-test | wc -l)"
    else
        echo -e "${GREEN}No merge conflicts${NC}"
        echo "has_conflicts=false"
    fi
    
    rm -f /tmp/merge-test
}

stash_changes() {
    if [[ -z $(git status --porcelain) ]]; then
        echo -e "${YELLOW}No changes to stash${NC}"
        echo "stashed=false"
        exit 0
    fi
    
    STASH_MSG="MetaClaude auto-stash $(date +%Y-%m-%d-%H%M%S)"
    git stash push -m "$STASH_MSG"
    
    echo -e "${GREEN}✓ Changes stashed${NC}"
    echo "stashed=true"
    echo "stash_message=$STASH_MSG"
}

# Execute operation
case "$OPERATION" in
    check-status)
        check_status
        ;;
    create-branch)
        create_branch
        ;;
    safe-commit)
        safe_commit
        ;;
    push-branch)
        push_branch
        ;;
    check-conflicts)
        check_conflicts
        ;;
    stash-changes)
        stash_changes
        ;;
    *)
        echo -e "${RED}Error: Unknown operation '$OPERATION'${NC}"
        usage
        ;;
esac