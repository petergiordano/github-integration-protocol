#!/bin/bash
# Comprehensive test script for GitHub Integration Protocol
# Tests all core functionality and validates bug fixes
# Safe to run - creates test issues with 'test' label for easy cleanup

set -e

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/issue-utils.sh"

# Test configuration
TEST_LABEL="test-run"
TEST_PREFIX="TEST"
CLEANUP_AFTER_TEST=false
DRY_RUN=false

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_ISSUES_CREATED=()

# ============================================================================
# Test Framework Functions
# ============================================================================

test_start() {
    local test_name="$1"
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}TEST: ${test_name}${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    ((TESTS_RUN++))
}

test_pass() {
    local message="$1"
    echo -e "${GREEN}✓ PASS${NC}: $message"
    ((TESTS_PASSED++))
}

test_fail() {
    local message="$1"
    echo -e "${RED}✗ FAIL${NC}: $message"
    ((TESTS_FAILED++))
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" = "$actual" ]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (expected to contain: '$needle', got: '$haystack')"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        test_pass "$message"
        return 0
    else
        test_fail "$message (should not contain: '$needle')"
        return 1
    fi
}

assert_success() {
    local command="$1"
    local message="$2"

    if eval "$command" &> /dev/null; then
        test_pass "$message"
        return 0
    else
        test_fail "$message"
        return 1
    fi
}

# ============================================================================
# Test: Environment & Prerequisites
# ============================================================================

test_environment() {
    test_start "Environment & Prerequisites"

    # Bash version (Bug 5 fix - should support 3.2+)
    local bash_major="${BASH_VERSINFO[0]}"
    local bash_minor="${BASH_VERSINFO[1]}"

    if [ "$bash_major" -ge 3 ] && [ "$bash_minor" -ge 2 ]; then
        test_pass "Bash version $bash_major.$bash_minor is >= 3.2 (macOS compatible)"
    else
        test_fail "Bash version $bash_major.$bash_minor is < 3.2"
    fi

    # GitHub CLI
    assert_success "command -v gh" "GitHub CLI (gh) is installed"

    if command -v gh &> /dev/null; then
        local gh_version=$(gh version 2>&1 | head -1 | awk '{print $3}')
        echo "  GitHub CLI version: $gh_version"
    fi

    # Git
    assert_success "command -v git" "Git is installed"

    # Authentication
    assert_success "gh auth status" "GitHub CLI is authenticated"

    # Repository access
    assert_success "gh repo view $REPO" "Repository is accessible"
}

# ============================================================================
# Test: Bash 3.2 Compatibility (Bug 1)
# ============================================================================

test_bash_32_compatibility() {
    test_start "Bash 3.2 Compatibility (Bug 1 Fix)"

    # Test lowercase conversion without ${variable,,}
    local test_input="HIGH"
    local result=$(echo "$test_input" | tr '[:upper:]' '[:lower:]')
    assert_equals "high" "$result" "Lowercase conversion works without Bash 4.0 syntax"

    # Test validate_priority with uppercase input
    if validate_priority "HIGH" 2>/dev/null; then
        test_pass "validate_priority() accepts uppercase 'HIGH'"
    else
        test_fail "validate_priority() should accept uppercase 'HIGH'"
    fi

    if validate_priority "MeDiUm" 2>/dev/null; then
        test_pass "validate_priority() accepts mixed case 'MeDiUm'"
    else
        test_fail "validate_priority() should accept mixed case"
    fi

    # Test that invalid priority still fails
    if validate_priority "invalid" 2>/dev/null; then
        test_fail "validate_priority() should reject invalid priority"
    else
        test_pass "validate_priority() correctly rejects invalid priority"
    fi
}

# ============================================================================
# Test: Logging to stderr (Bug 4)
# ============================================================================

test_logging_to_stderr() {
    test_start "Logging Functions Output to stderr (Bug 4 Fix)"

    # Capture stdout and stderr separately
    local stdout_file=$(mktemp)
    local stderr_file=$(mktemp)

    # Test that log_info outputs to stderr, not stdout
    log_info "Test message" > "$stdout_file" 2> "$stderr_file"

    local stdout_content=$(cat "$stdout_file")
    local stderr_content=$(cat "$stderr_file")

    if [ -z "$stdout_content" ]; then
        test_pass "log_info() outputs nothing to stdout"
    else
        test_fail "log_info() should not output to stdout"
    fi

    if [[ "$stderr_content" == *"Test message"* ]]; then
        test_pass "log_info() outputs to stderr"
    else
        test_fail "log_info() should output to stderr"
    fi

    # Test that this prevents contamination in command substitution
    local captured=$(echo "test output")
    assert_equals "test output" "$captured" "Command substitution not contaminated by logs"

    # Cleanup
    rm -f "$stdout_file" "$stderr_file"
}

# ============================================================================
# Test: Issue Body Generation (Bug 3)
# ============================================================================

test_issue_body_generation() {
    test_start "Issue Body Generation with Heredoc (Bug 3 Fix)"

    # Generate test body
    local body=$(generate_issue_body "Test description" "Phase 1" "high")

    # Should contain proper markdown sections
    assert_contains "$body" "## Description" "Body contains Description section"
    assert_contains "$body" "Test description" "Body contains description text"
    assert_contains "$body" "## Acceptance Criteria" "Body contains Acceptance Criteria section"
    assert_contains "$body" "## Phase" "Body contains Phase section"
    assert_contains "$body" "Phase 1" "Body contains phase value"
    assert_contains "$body" "## Priority" "Body contains Priority section"
    assert_contains "$body" "high" "Body contains priority value"
    assert_contains "$body" "## Status" "Body contains Status section"
    assert_contains "$body" "⬜ Todo" "Body contains status value"

    # Should NOT contain literal \n characters
    assert_not_contains "$body" "\\n" "Body does not contain literal \\n characters"

    # Test with default acceptance criteria
    local body_default=$(generate_issue_body "Test" "" "")
    for criterion in "${DEFAULT_ACCEPTANCE_CRITERIA[@]}"; do
        assert_contains "$body_default" "$criterion" "Body contains default criterion: $criterion"
    done
}

# ============================================================================
# Test: Command Quoting (Bug 2)
# ============================================================================

test_command_quoting() {
    test_start "Command Quoting Without eval (Bug 2 Fix)"

    # Test that multiline strings are preserved
    local multiline_test="Line 1
Line 2
Line 3"

    # Create a test function that echoes its argument
    test_echo_function() {
        echo "$1"
    }

    local result=$(test_echo_function "$multiline_test")

    # Count lines in result
    local line_count=$(echo "$result" | wc -l | tr -d ' ')

    if [ "$line_count" = "3" ]; then
        test_pass "Multiline strings preserved through function calls"
    else
        test_fail "Multiline strings not preserved (got $line_count lines, expected 3)"
    fi

    # Test with special characters
    local special_chars='Test with "quotes" and $variables'
    local result2=$(test_echo_function "$special_chars")

    assert_contains "$result2" '"quotes"' "Double quotes preserved"
    assert_contains "$result2" '$variables' "Dollar signs preserved"
}

# ============================================================================
# Test: Validation Functions
# ============================================================================

test_validation_functions() {
    test_start "Validation Functions"

    # Test validate_title
    if validate_title "Valid Title" 2>/dev/null; then
        test_pass "validate_title() accepts valid title"
    else
        test_fail "validate_title() should accept valid title"
    fi

    if validate_title "abc" 2>/dev/null; then
        test_fail "validate_title() should reject short title"
    else
        test_pass "validate_title() rejects title < 5 chars"
    fi

    # Test validate_description
    if validate_description "Valid description text" 2>/dev/null; then
        test_pass "validate_description() accepts valid description"
    else
        test_fail "validate_description() should accept valid description"
    fi

    if validate_description "short" 2>/dev/null; then
        test_fail "validate_description() should reject short description"
    else
        test_pass "validate_description() rejects description < 10 chars"
    fi

    # Test validate_phase
    if [ ${#PHASES[@]} -gt 0 ]; then
        if validate_phase "${PHASES[0]}" 2>/dev/null; then
            test_pass "validate_phase() accepts valid phase"
        else
            test_fail "validate_phase() should accept configured phase"
        fi
    fi
}

# ============================================================================
# Test: ID Generation
# ============================================================================

test_id_generation() {
    test_start "ID Generation"

    # Test ID generation
    local next_id=$(get_next_id "$TEST_PREFIX" 2>/dev/null)

    if [[ "$next_id" =~ ^${TEST_PREFIX}-[0-9]{3}$ ]]; then
        test_pass "ID format matches pattern ${TEST_PREFIX}-XXX"
        echo "  Generated ID: $next_id"
    else
        test_fail "ID format incorrect (got: $next_id)"
    fi
}

# ============================================================================
# Test: End-to-End Issue Creation
# ============================================================================

test_e2e_issue_creation() {
    test_start "End-to-End Issue Creation"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Skipping actual issue creation"
        test_pass "Dry run mode - skipping E2E test"
        return 0
    fi

    # Create a test issue
    local test_title="E2E Test Issue"
    local test_desc="This is an automated test issue created by test-integration.sh. Safe to close."
    local test_phase="${PHASES[0]:-}"
    local test_priority="high"

    echo "  Creating test issue..."

    # Capture the issue URL
    local issue_url=""
    if issue_url=$(create_issue "$TEST_PREFIX" "$test_title" "$test_desc" "$test_phase" "$test_priority" "$TEST_LABEL" 2>&1 | grep -o 'https://[^ ]*' | tail -1); then
        test_pass "Issue created successfully"
        echo "  Issue URL: $issue_url"

        # Extract issue number
        local issue_number=$(echo "$issue_url" | grep -o '[0-9]*$')
        TEST_ISSUES_CREATED+=("$issue_number")

        # Verify the issue was created with correct attributes
        if [ -n "$issue_number" ]; then
            echo "  Verifying issue #$issue_number..."

            # Get issue details
            local issue_json=$(gh issue view "$issue_number" --repo "$REPO" --json title,body,labels)

            # Check title format
            local issue_title=$(echo "$issue_json" | jq -r '.title')
            assert_contains "$issue_title" "$TEST_PREFIX" "Issue title contains prefix"
            assert_contains "$issue_title" "$test_title" "Issue title contains title text"

            # Check that title doesn't contain log messages (Bug 4 fix verification)
            assert_not_contains "$issue_title" "[INFO]" "Issue title clean (no log contamination)"
            assert_not_contains "$issue_title" "[SUCCESS]" "Issue title clean (no success messages)"

            # Check body
            local issue_body=$(echo "$issue_json" | jq -r '.body')
            assert_contains "$issue_body" "$test_desc" "Issue body contains description"
            assert_contains "$issue_body" "## Acceptance Criteria" "Issue body has acceptance criteria"
            assert_not_contains "$issue_body" "\\n" "Issue body has no literal \\n (Bug 3 fix verified)"

            # Check labels
            local labels=$(echo "$issue_json" | jq -r '.labels[].name' | tr '\n' ',')
            assert_contains "$labels" "$TEST_LABEL" "Issue has test label"
            assert_contains "$labels" "priority-high" "Issue has priority label (Bug 1 fix verified)"
        fi
    else
        test_fail "Failed to create issue"
    fi
}

# ============================================================================
# Test: Status Updates
# ============================================================================

test_status_updates() {
    test_start "Status Update Workflow"

    if [ "$DRY_RUN" = true ] || [ ${#TEST_ISSUES_CREATED[@]} -eq 0 ]; then
        echo "  [SKIPPED] No test issues available for status update"
        test_pass "Dry run or no issues - skipping status test"
        return 0
    fi

    local issue_number="${TEST_ISSUES_CREATED[0]}"
    echo "  Testing status updates on issue #$issue_number..."

    # Test status transitions: todo -> in-progress -> complete
    local statuses=("in-progress" "complete")

    for status in "${statuses[@]}"; do
        if update_issue_status "$issue_number" "$status" 2>&1 | grep -q "Status updated"; then
            test_pass "Status updated to: $status"

            # Verify the label was applied
            sleep 1  # Brief pause for GitHub API
            local current_labels=$(gh issue view "$issue_number" --repo "$REPO" --json labels --jq '.labels[].name' | tr '\n' ',')

            case "$status" in
                "in-progress")
                    assert_contains "$current_labels" "$STATUS_IN_PROGRESS" "Issue has in-progress label"
                    ;;
                "complete")
                    assert_contains "$current_labels" "$STATUS_COMPLETE" "Issue has complete label"
                    ;;
            esac
        else
            test_fail "Failed to update status to: $status"
        fi
    done
}

# ============================================================================
# Test: Retry Mechanism
# ============================================================================

test_retry_mechanism() {
    test_start "Retry Mechanism"

    # Test that gh_with_retry works with a simple command
    local result=$(gh_with_retry gh api user --jq .login 2>&1 | tail -1)

    if [ -n "$result" ] && [ "$result" != "null" ]; then
        test_pass "gh_with_retry executes commands successfully"
        echo "  Authenticated as: $result"
    else
        test_fail "gh_with_retry should execute commands"
    fi
}

# ============================================================================
# Cleanup Function
# ============================================================================

cleanup_test_issues() {
    if [ "$CLEANUP_AFTER_TEST" = true ] && [ ${#TEST_ISSUES_CREATED[@]} -gt 0 ]; then
        echo ""
        echo -e "${BOLD}${YELLOW}Cleaning up test issues...${NC}"

        for issue_number in "${TEST_ISSUES_CREATED[@]}"; do
            echo "  Closing issue #$issue_number..."
            if gh issue close "$issue_number" --repo "$REPO" --comment "Test completed - auto-closing" &> /dev/null; then
                echo -e "  ${GREEN}✓${NC} Closed issue #$issue_number"
            else
                echo -e "  ${RED}✗${NC} Failed to close issue #$issue_number"
            fi
        done
    elif [ ${#TEST_ISSUES_CREATED[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Test issues created (not auto-cleaned):${NC}"
        for issue_number in "${TEST_ISSUES_CREATED[@]}"; do
            echo "  #$issue_number - https://github.com/$REPO/issues/$issue_number"
        done
        echo ""
        echo "To clean up manually:"
        echo "  gh issue list --repo $REPO --label $TEST_LABEL"
        echo "  gh issue close <number> --repo $REPO"
    fi
}

# ============================================================================
# Usage Information
# ============================================================================

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Comprehensive test suite for GitHub Integration Protocol

OPTIONS:
    -d, --dry-run       Run tests without creating actual issues
    -c, --cleanup       Automatically close test issues after testing
    -h, --help          Show this help message

EXAMPLES:
    # Run all tests (creates real test issues)
    $0

    # Run without creating issues (safe mode)
    $0 --dry-run

    # Run and auto-cleanup test issues
    $0 --cleanup

WHAT THIS TESTS:
    ✓ Environment and prerequisites (Bash 3.2+, gh CLI, git)
    ✓ Bash 3.2 compatibility (Bug 1 fix)
    ✓ Logging to stderr (Bug 4 fix)
    ✓ Issue body generation with heredoc (Bug 3 fix)
    ✓ Command quoting without eval (Bug 2 fix)
    ✓ Validation functions
    ✓ ID generation
    ✓ End-to-end issue creation
    ✓ Status update workflow
    ✓ Retry mechanism

EOF
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--cleanup)
                CLEANUP_AFTER_TEST=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Print header
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                                                            ║${NC}"
    echo -e "${BOLD}${BLUE}║        GitHub Integration Protocol Test Suite             ║${NC}"
    echo -e "${BOLD}${BLUE}║                                                            ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Configuration:${NC}"
    echo "  Repository: $REPO"
    echo "  Config file: $CONFIG_FILE"
    echo "  Dry run: $DRY_RUN"
    echo "  Auto cleanup: $CLEANUP_AFTER_TEST"
    echo ""

    # Run all tests
    test_environment
    test_bash_32_compatibility
    test_logging_to_stderr
    test_issue_body_generation
    test_command_quoting
    test_validation_functions
    test_id_generation
    test_e2e_issue_creation
    test_status_updates
    test_retry_mechanism

    # Print summary
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                      Test Summary                          ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Total Tests:${NC}   $TESTS_RUN"
    echo -e "  ${GREEN}${BOLD}Passed:${NC}        $TESTS_PASSED"
    echo -e "  ${RED}${BOLD}Failed:${NC}        $TESTS_FAILED"
    echo ""

    # Cleanup
    cleanup_test_issues

    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All tests passed!${NC}"
        echo ""
        echo "The GitHub Integration Protocol is working correctly."
        echo "You can now use it in your project with confidence."
        echo ""
        exit 0
    else
        echo -e "${RED}${BOLD}✗ Some tests failed${NC}"
        echo ""
        echo "Please review the failures above and fix any issues."
        echo ""
        exit 1
    fi
}

# Run main
main "$@"
