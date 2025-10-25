#!/bin/bash
# Issue creation utilities and shared functions
# Used by all issue creation scripts
# Version 3.0 - Portable with configuration support

set -e

# ============================================================================
# Load Configuration
# ============================================================================

# Find config file (supports multiple possible locations)
CONFIG_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Search locations in order of preference
CONFIG_SEARCH_PATHS=(
    "${SCRIPT_DIR}/../.github-integration/config.sh"
    "${SCRIPT_DIR}/.github-integration/config.sh"
    "$(pwd)/.github-integration/config.sh"
)

for path in "${CONFIG_SEARCH_PATHS[@]}"; do
    if [ -f "$path" ]; then
        CONFIG_FILE="$path"
        break
    fi
done

if [ -z "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found!"
    echo "Searched locations:"
    for path in "${CONFIG_SEARCH_PATHS[@]}"; do
        echo "  - $path"
    done
    echo ""
    echo "Run the installer: ./github-integration-kit/install.sh"
    exit 1
fi

# Source configuration
source "$CONFIG_FILE"

# ============================================================================
# Backwards Compatibility
# ============================================================================

# Ensure required variables are set (with defaults)
REPO="${REPO:-${REPO_OWNER}/${REPO_NAME}}"
PROJECT_NUMBER="${PROJECT_NUMBER:-1}"
MAX_RETRY_ATTEMPTS="${MAX_RETRY_ATTEMPTS:-${GH_MAX_RETRIES:-3}}"
RETRY_DELAY="${RETRY_DELAY:-${GH_RETRY_DELAY:-2}}"

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_retry() {
    echo -e "${YELLOW}[RETRY]${NC} $1"
}

# ============================================================================
# GitHub CLI Retry Wrapper
# ============================================================================

gh_with_retry() {
    local attempt=1
    local output=""
    local exit_code=0

    while [ $attempt -le $MAX_RETRY_ATTEMPTS ]; do
        log_info "Attempt $attempt/$MAX_RETRY_ATTEMPTS: $@"

        # Execute command and capture output
        if output=$(eval "$@" 2>&1); then
            exit_code=0
            echo "$output"
            return 0
        else
            exit_code=$?
            log_warning "Attempt $attempt failed with exit code $exit_code"

            if [ $attempt -lt $MAX_RETRY_ATTEMPTS ]; then
                log_retry "Retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
            fi
        fi

        ((attempt++))
    done

    log_error "All retry attempts failed"
    log_error "Last output: $output"
    return $exit_code
}

# ============================================================================
# Authentication Check
# ============================================================================

check_gh_auth() {
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI not authenticated"
        log_info "Run: gh auth login"
        return 1
    fi
    return 0
}

# ============================================================================
# ID Generation
# ============================================================================

get_next_id() {
    local prefix="$1"
    local max_num=0

    log_info "Finding next ${prefix} ID..."

    # Get all issues with this prefix
    local issues=$(gh issue list --repo "$REPO" --limit 1000 --state all --json title --jq '.[].title' 2>/dev/null || echo "")

    # Extract numbers from matching titles
    while IFS= read -r title; do
        if [[ "$title" =~ ^\[${prefix}-([0-9]+)\] ]]; then
            local num="${BASH_REMATCH[1]}"
            # Remove leading zeros and compare
            num=$((10#$num))
            if [ $num -gt $max_num ]; then
                max_num=$num
            fi
        fi
    done <<< "$issues"

    # Generate next ID with zero padding
    local next_num=$((max_num + 1))
    printf "${prefix}-%03d" $next_num
}

# ============================================================================
# Phase Detection
# ============================================================================

detect_current_phase() {
    # Try to detect phase from git branch name
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

    # Check if branch name contains a phase
    for phase in "${PHASES[@]}"; do
        # Convert to lowercase for comparison
        local phase_lower=$(echo "$phase" | tr '[:upper:]' '[:lower:]')
        local branch_lower=$(echo "$branch" | tr '[:upper:]' '[:lower:]')

        if [[ "$branch_lower" == *"$phase_lower"* ]]; then
            echo "$phase"
            return 0
        fi
    done

    # Try to detect from recent commits
    local recent_commit=$(git log -1 --pretty=%B 2>/dev/null || echo "")
    for phase in "${PHASES[@]}"; do
        if [[ "$recent_commit" == *"$phase"* ]]; then
            echo "$phase"
            return 0
        fi
    done

    # Default to first phase
    echo "${PHASES[0]}"
}

# ============================================================================
# Validation Functions
# ============================================================================

validate_title() {
    local title="$1"

    if [ -z "$title" ]; then
        log_error "Title cannot be empty"
        return 1
    fi

    if [ ${#title} -lt 5 ]; then
        log_error "Title too short (minimum 5 characters)"
        return 1
    fi

    if [ ${#title} -gt 200 ]; then
        log_error "Title too long (maximum 200 characters)"
        return 1
    fi

    return 0
}

validate_description() {
    local description="$1"

    if [ -z "$description" ]; then
        log_error "Description cannot be empty"
        return 1
    fi

    if [ ${#description} -lt 10 ]; then
        log_error "Description too short (minimum 10 characters)"
        return 1
    fi

    return 0
}

validate_phase() {
    local phase="$1"

    if [ -z "$phase" ]; then
        return 0  # Optional
    fi

    # Check if phase is in configured phases
    for valid_phase in "${PHASES[@]}"; do
        if [ "$phase" = "$valid_phase" ]; then
            return 0
        fi
    done

    log_warning "Phase '$phase' not in configured phases"
    log_info "Valid phases: ${PHASES[*]}"
    return 1
}

validate_priority() {
    local priority="$1"

    if [ -z "$priority" ]; then
        return 0  # Optional
    fi

    case "${priority,,}" in
        high|medium|low)
            return 0
            ;;
        *)
            log_error "Invalid priority: $priority (use: high, medium, low)"
            return 1
            ;;
    esac
}

# ============================================================================
# Issue Body Generation
# ============================================================================

generate_issue_body() {
    local description="$1"
    local phase="$2"
    local priority="$3"
    shift 3
    local acceptance_criteria=("$@")

    local body="## Description\n${description}\n\n"

    # Acceptance criteria
    body+="## Acceptance Criteria\n"
    if [ ${#acceptance_criteria[@]} -eq 0 ]; then
        # Use default criteria from config
        for criterion in "${DEFAULT_ACCEPTANCE_CRITERIA[@]}"; do
            body+="- [ ] ${criterion}\n"
        done
    else
        for criterion in "${acceptance_criteria[@]}"; do
            body+="- [ ] ${criterion}\n"
        done
    fi

    # Phase
    if [ -n "$phase" ]; then
        body+="\n## Phase\n${phase}\n"
    fi

    # Priority
    if [ -n "$priority" ]; then
        body+="\n## Priority\n${priority}\n"
    fi

    # Status
    body+="\n## Status\n⬜ Todo\n"

    echo -e "$body"
}

# ============================================================================
# Issue Creation
# ============================================================================

create_issue() {
    local prefix="$1"
    local title="$2"
    local description="$3"
    local phase="$4"
    local priority="${5:-medium}"
    shift 5
    local additional_labels=("$@")

    # Validate inputs
    validate_title "$title" || return 1
    validate_description "$description" || return 1
    validate_phase "$phase" || return 1
    validate_priority "$priority" || return 1

    # Check authentication
    check_gh_auth || return 1

    # Get next ID
    local issue_id=$(get_next_id "$prefix")
    log_success "Generated ID: $issue_id"

    # Build full title
    local full_title="[${issue_id}]: ${title}"

    # Generate body
    local body=$(generate_issue_body "$description" "$phase" "$priority")

    # Build labels array
    local labels=()

    # Add type label
    case "$prefix" in
        "$FEATURE_PREFIX")
            labels+=("enhancement")
            ;;
        "$ENHANCEMENT_PREFIX")
            labels+=("enhancement")
            ;;
        "$BUG_PREFIX")
            labels+=("bug")
            ;;
    esac

    # Add status label
    if [ "$AUTO_ADD_TODO_STATUS" = "true" ]; then
        labels+=("$STATUS_TODO")
    fi

    # Add phase label
    if [ -n "$phase" ]; then
        labels+=("$phase")
    fi

    # Add priority label
    if [ -n "$priority" ]; then
        labels+=("priority-${priority,,}")
    fi

    # Add additional labels
    labels+=("${additional_labels[@]}")

    # Create labels string
    local labels_str=$(IFS=','; echo "${labels[*]}")

    # Create issue
    log_info "Creating issue: $full_title"
    local issue_url=$(gh_with_retry gh issue create \
        --repo "$REPO" \
        --title "$full_title" \
        --body "$body" \
        --label "$labels_str")

    if [ $? -eq 0 ]; then
        log_success "Issue created: $issue_url"
        log_success "Issue ID: $issue_id"
        return 0
    else
        log_error "Failed to create issue"
        return 1
    fi
}

# ============================================================================
# Status Update
# ============================================================================

update_issue_status() {
    local issue_identifier="$1"
    local new_status="$2"

    check_gh_auth || return 1

    # Validate status
    case "$new_status" in
        "$STATUS_TODO"|"$STATUS_IN_PROGRESS"|"$STATUS_COMPLETE"|todo|in-progress|complete|wip|done)
            ;;
        *)
            log_error "Invalid status: $new_status"
            log_info "Valid statuses: todo, in-progress, complete"
            return 1
            ;;
    esac

    # Normalize status
    case "$new_status" in
        todo)
            new_status="$STATUS_TODO"
            ;;
        in-progress|wip)
            new_status="$STATUS_IN_PROGRESS"
            ;;
        complete|done)
            new_status="$STATUS_COMPLETE"
            ;;
    esac

    # Resolve issue number from ID if needed
    local issue_number="$issue_identifier"
    if [[ ! "$issue_identifier" =~ ^[0-9]+$ ]]; then
        # It's an ID like FEAT-001, search for it
        log_info "Searching for issue: $issue_identifier"
        issue_number=$(gh issue list --repo "$REPO" --limit 1000 --state all --json number,title --jq ".[] | select(.title | contains(\"[$issue_identifier]\")) | .number" | head -1)

        if [ -z "$issue_number" ]; then
            log_error "Issue not found: $issue_identifier"
            return 1
        fi
        log_success "Found issue #$issue_number"
    fi

    # Remove old status labels
    log_info "Removing old status labels..."
    for status in "$STATUS_TODO" "$STATUS_IN_PROGRESS" "$STATUS_COMPLETE"; do
        gh issue edit "$issue_number" --repo "$REPO" --remove-label "$status" 2>/dev/null || true
    done

    # Add new status label
    log_info "Adding new status: $new_status"
    gh_with_retry gh issue edit "$issue_number" --repo "$REPO" --add-label "$new_status"

    if [ $? -eq 0 ]; then
        log_success "Status updated to: $new_status"
        return 0
    else
        log_error "Failed to update status"
        return 1
    fi
}

# ============================================================================
# Export Functions
# ============================================================================

# Make functions available to scripts that source this file
export -f gh_with_retry
export -f check_gh_auth
export -f get_next_id
export -f detect_current_phase
export -f validate_title
export -f validate_description
export -f validate_phase
export -f validate_priority
export -f generate_issue_body
export -f create_issue
export -f update_issue_status
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_retry
