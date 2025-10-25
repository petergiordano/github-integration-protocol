#!/bin/bash
# Update issue status label
# Usage: ./update-issue-status.sh <issue-number-or-id> <status>

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/issue-utils.sh"

# Parse arguments
ISSUE="$1"
STATUS="$2"

# Validate required arguments
if [ -z "$ISSUE" ] || [ -z "$STATUS" ]; then
    echo "Usage: $0 <issue-number-or-id> <status>"
    echo ""
    echo "Status values: todo, in-progress, complete"
    echo ""
    echo "Examples:"
    echo "  $0 123 in-progress           # Update issue #123"
    echo "  $0 FEAT-001 complete         # Update by ID"
    echo ""
    exit 1
fi

# Update status
update_issue_status "$ISSUE" "$STATUS"

exit $?
