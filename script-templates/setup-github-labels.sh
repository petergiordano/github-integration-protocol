#!/bin/bash
# Setup GitHub labels for database-driven workflow
# Creates status, priority, phase, and type labels

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/issue-utils.sh"

# ============================================================================
# Label Creation Function
# ============================================================================

create_label() {
    local name="$1"
    local color="$2"
    local description="$3"

    log_info "Creating label: $name"

    # Try to create label
    if gh label create "$name" --color "$color" --description "$description" --repo "$REPO" 2>/dev/null; then
        log_success "Created: $name"
    else
        # Label might already exist, try to update it
        if gh label edit "$name" --color "$color" --description "$description" --repo "$REPO" 2>/dev/null; then
            log_warning "Updated existing: $name"
        else
            log_error "Failed to create/update: $name"
        fi
    fi
}

# ============================================================================
# Main Setup
# ============================================================================

main() {
    echo ""
    log_info "Setting up GitHub labels for: $REPO"
    echo ""

    # Check authentication
    check_gh_auth || exit 1

    # ========================================================================
    # Status Labels
    # ========================================================================

    log_info "Creating status labels..."
    echo ""

    create_label "$STATUS_TODO" "$STATUS_COLOR" "Task not yet started"
    create_label "$STATUS_IN_PROGRESS" "$STATUS_COLOR" "Currently being worked on"
    create_label "$STATUS_COMPLETE" "$STATUS_COLOR" "Task completed"

    echo ""

    # ========================================================================
    # Priority Labels
    # ========================================================================

    log_info "Creating priority labels..."
    echo ""

    create_label "$PRIORITY_HIGH" "$PRIORITY_HIGH_COLOR" "High priority"
    create_label "$PRIORITY_MEDIUM" "$PRIORITY_MEDIUM_COLOR" "Medium priority"
    create_label "$PRIORITY_LOW" "$PRIORITY_LOW_COLOR" "Low priority"

    echo ""

    # ========================================================================
    # Phase Labels
    # ========================================================================

    log_info "Creating phase labels..."
    echo ""

    for phase in "${PHASES[@]}"; do
        create_label "$phase" "$PHASE_COLOR" "Development phase: $phase"
    done

    echo ""

    # ========================================================================
    # Type Labels
    # ========================================================================

    log_info "Creating type labels..."
    echo ""

    create_label "enhancement" "$ENHANCEMENT_COLOR" "New feature or improvement"
    create_label "bug" "$BUG_COLOR" "Something isn't working"

    echo ""

    # ========================================================================
    # Summary
    # ========================================================================

    log_success "Label setup complete!"
    echo ""
    log_info "Created labels:"
    log_info "  Status: $STATUS_TODO, $STATUS_IN_PROGRESS, $STATUS_COMPLETE"
    log_info "  Priority: $PRIORITY_HIGH, $PRIORITY_MEDIUM, $PRIORITY_LOW"
    log_info "  Phases: ${PHASES[*]}"
    log_info "  Types: enhancement, bug"
    echo ""
    log_info "View labels: gh label list --repo $REPO"
    echo ""
}

main "$@"
