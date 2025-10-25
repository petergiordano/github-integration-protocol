#!/bin/bash
# Validate GitHub integration workflow setup
# Checks all prerequisites and configurations

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/issue-utils.sh"

# ============================================================================
# Validation Functions
# ============================================================================

PASSED=0
FAILED=0
WARNINGS=0

check_item() {
    local description="$1"
    local command="$2"

    echo -n "Checking: $description... "

    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

check_item_warn() {
    local description="$1"
    local command="$2"

    echo -n "Checking: $description... "

    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}⚠ WARN${NC}"
        ((WARNINGS++))
        return 1
    fi
}

# ============================================================================
# Main Validation
# ============================================================================

main() {
    echo ""
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo -e "${BOLD}${BLUE}  GitHub Workflow Validation${NC}"
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo ""

    # ========================================================================
    # Configuration
    # ========================================================================

    echo -e "${BOLD}Configuration:${NC}"
    echo "  Repository: $REPO"
    echo "  Project: #$PROJECT_NUMBER"
    echo "  Config file: $CONFIG_FILE"
    echo ""

    # ========================================================================
    # Prerequisites
    # ========================================================================

    echo -e "${BOLD}1. Prerequisites${NC}"
    echo ""

    check_item "Git installed" "command -v git"
    check_item "GitHub CLI installed" "command -v gh"

    if command -v gh &> /dev/null; then
        local gh_version=$(gh version 2>&1 | head -1 | awk '{print $3}')
        echo "  GitHub CLI version: $gh_version"
    fi

    check_item "Bash 4.0+" "[ \${BASH_VERSINFO[0]} -ge 4 ]"

    if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
        echo "  Bash version: ${BASH_VERSION}"
    fi

    echo ""

    # ========================================================================
    # GitHub Authentication
    # ========================================================================

    echo -e "${BOLD}2. GitHub Authentication${NC}"
    echo ""

    check_item "GitHub CLI authenticated" "gh auth status"

    if gh auth status &> /dev/null; then
        local username=$(gh api user -q .login 2>/dev/null || echo "unknown")
        echo "  Authenticated as: $username"
    fi

    echo ""

    # ========================================================================
    # Repository Access
    # ========================================================================

    echo -e "${BOLD}3. Repository Access${NC}"
    echo ""

    check_item "Repository exists and accessible" "gh repo view $REPO"

    if gh repo view "$REPO" &> /dev/null; then
        local repo_url=$(gh repo view "$REPO" --json url -q .url 2>/dev/null || echo "")
        echo "  Repository URL: $repo_url"
    fi

    check_item "Issues enabled" "gh issue list --repo $REPO --limit 1"

    echo ""

    # ========================================================================
    # Labels
    # ========================================================================

    echo -e "${BOLD}4. Required Labels${NC}"
    echo ""

    local labels_exist=true

    # Status labels
    check_item_warn "Status label: $STATUS_TODO" "gh label list --repo $REPO | grep -q '$STATUS_TODO'" || labels_exist=false
    check_item_warn "Status label: $STATUS_IN_PROGRESS" "gh label list --repo $REPO | grep -q '$STATUS_IN_PROGRESS'" || labels_exist=false
    check_item_warn "Status label: $STATUS_COMPLETE" "gh label list --repo $REPO | grep -q '$STATUS_COMPLETE'" || labels_exist=false

    # Priority labels
    check_item_warn "Priority label: $PRIORITY_HIGH" "gh label list --repo $REPO | grep -q '$PRIORITY_HIGH'" || labels_exist=false
    check_item_warn "Priority label: $PRIORITY_MEDIUM" "gh label list --repo $REPO | grep -q '$PRIORITY_MEDIUM'" || labels_exist=false
    check_item_warn "Priority label: $PRIORITY_LOW" "gh label list --repo $REPO | grep -q '$PRIORITY_LOW'" || labels_exist=false

    # Type labels
    check_item_warn "Type label: enhancement" "gh label list --repo $REPO | grep -q 'enhancement'" || labels_exist=false
    check_item_warn "Type label: bug" "gh label list --repo $REPO | grep -q 'bug'" || labels_exist=false

    if [ "$labels_exist" = false ]; then
        echo ""
        echo -e "${YELLOW}  → Run: ./scripts/setup-github-labels.sh${NC}"
    fi

    echo ""

    # ========================================================================
    # Scripts
    # ========================================================================

    echo -e "${BOLD}5. Scripts${NC}"
    echo ""

    check_item "issue-utils.sh exists" "[ -f '$SCRIPT_DIR/issue-utils.sh' ]"
    check_item "create-feature-issue.sh exists" "[ -f '$SCRIPT_DIR/create-feature-issue.sh' ]"
    check_item "create-enhancement-issue.sh exists" "[ -f '$SCRIPT_DIR/create-enhancement-issue.sh' ]"
    check_item "create-bug-issue.sh exists" "[ -f '$SCRIPT_DIR/create-bug-issue.sh' ]"
    check_item "update-issue-status.sh exists" "[ -f '$SCRIPT_DIR/update-issue-status.sh' ]"
    check_item "setup-github-labels.sh exists" "[ -f '$SCRIPT_DIR/setup-github-labels.sh' ]"

    echo ""

    # ========================================================================
    # GitHub Actions
    # ========================================================================

    echo -e "${BOLD}6. GitHub Actions${NC}"
    echo ""

    local workflow_file="${PROJECT_ROOT}/.github/workflows/auto-label.yml"
    check_item_warn "Auto-label workflow exists" "[ -f '$workflow_file' ]"

    if [ -f "$workflow_file" ]; then
        echo "  Workflow file: $workflow_file"
    fi

    echo ""

    # ========================================================================
    # Issue Templates
    # ========================================================================

    echo -e "${BOLD}7. Issue Templates${NC}"
    echo ""

    local templates_dir="${PROJECT_ROOT}/.github/ISSUE_TEMPLATE"
    check_item_warn "Issue templates directory" "[ -d '$templates_dir' ]"

    if [ -d "$templates_dir" ]; then
        local template_count=$(ls -1 "$templates_dir"/*.yml 2>/dev/null | wc -l || echo "0")
        echo "  Templates found: $template_count"
    fi

    echo ""

    # ========================================================================
    # Summary
    # ========================================================================

    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo -e "${BOLD}Validation Summary${NC}"
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}   $PASSED"
    echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "  ${RED}Failed:${NC}   $FAILED"
    echo ""

    if [ $FAILED -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}✓ All checks passed!${NC}"
            echo ""
            echo "You're ready to use the GitHub integration:"
            echo "  ./scripts/create-feature-issue.sh \"My Feature\" \"Description\""
            echo ""
        else
            echo -e "${YELLOW}⚠ Some optional features missing${NC}"
            echo ""
            echo "Fix warnings with:"
            echo "  ./scripts/setup-github-labels.sh"
            echo ""
        fi
        exit 0
    else
        echo -e "${RED}✗ Validation failed${NC}"
        echo ""
        echo "Fix required issues before continuing."
        echo ""
        exit 1
    fi
}

main "$@"
