#!/bin/bash
# Create a bug issue with automatic ID generation
# Usage: ./create-bug-issue.sh "Title" "Description" ["Phase"] ["Priority"]

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/issue-utils.sh"

# Parse arguments
TITLE="$1"
DESCRIPTION="$2"
PHASE="${3:-$(detect_current_phase)}"
PRIORITY="${4:-high}"  # Bugs default to high priority

# Validate required arguments
if [ -z "$TITLE" ] || [ -z "$DESCRIPTION" ]; then
    echo "Usage: $0 \"Title\" \"Description\" [\"Phase\"] [\"Priority\"]"
    echo ""
    echo "Examples:"
    echo "  $0 \"Login fails\" \"Users cannot log in with OAuth\""
    echo "  $0 \"Login fails\" \"Users cannot log in with OAuth\" \"Phase 1\" \"high\""
    echo ""
    exit 1
fi

# Display configuration
log_info "Creating bug issue..."
log_info "Repository: $REPO"
log_info "Prefix: $BUG_PREFIX"
log_info "Title: $TITLE"
log_info "Phase: $PHASE"
log_info "Priority: $PRIORITY"
echo ""

# Create the issue
create_issue "$BUG_PREFIX" "$TITLE" "$DESCRIPTION" "$PHASE" "$PRIORITY"

exit $?
