#!/bin/bash
# GitHub Integration Configuration
# This file is auto-generated during installation
# Customize these values for your project

# ============================================================================
# REQUIRED: Repository Settings
# ============================================================================

# GitHub repository owner (username or organization)
REPO_OWNER="REPLACE_WITH_OWNER"

# Repository name
REPO_NAME="REPLACE_WITH_REPO"

# Full repository path (auto-generated)
REPO="${REPO_OWNER}/${REPO_NAME}"

# GitHub Project number (find in your project URL)
PROJECT_NUMBER="1"

# ============================================================================
# OPTIONAL: Issue Prefix Customization
# ============================================================================

# Prefix for feature issues (creates FEAT-001, FEAT-002, etc.)
FEATURE_PREFIX="FEAT"

# Prefix for enhancement issues
ENHANCEMENT_PREFIX="ENH"

# Prefix for bug issues
BUG_PREFIX="BUG"

# ============================================================================
# OPTIONAL: Phase/Milestone Configuration
# ============================================================================

# Define your project phases (customize as needed)
# These will be created as labels and used in issue templates
PHASES=(
  "Phase 1"
  "Phase 2"
  "Phase 3"
  "Phase 4"
  "Phase 5"
)

# Alternatively, use sprint-based phases:
# PHASES=(
#   "Sprint 1"
#   "Sprint 2"
#   "Sprint 3"
#   "Backlog"
# )

# Or milestone-based:
# PHASES=(
#   "Planning"
#   "Development"
#   "Testing"
#   "Deployment"
# )

# ============================================================================
# OPTIONAL: Retry Configuration
# ============================================================================

# Maximum retry attempts for GitHub API calls
MAX_RETRY_ATTEMPTS="${GH_MAX_RETRIES:-3}"

# Delay between retries (seconds)
RETRY_DELAY="${GH_RETRY_DELAY:-2}"

# ============================================================================
# OPTIONAL: Label Names
# ============================================================================

# Status labels
STATUS_TODO="status-todo"
STATUS_IN_PROGRESS="status-in-progress"
STATUS_COMPLETE="status-complete"

# Priority labels
PRIORITY_HIGH="priority-high"
PRIORITY_MEDIUM="priority-medium"
PRIORITY_LOW="priority-low"

# ============================================================================
# OPTIONAL: Label Colors (Hex codes without #)
# ============================================================================

# Status label color (blue)
STATUS_COLOR="4C9AFF"

# Priority colors
PRIORITY_HIGH_COLOR="D73A4A"    # Red
PRIORITY_MEDIUM_COLOR="FB8500"  # Orange
PRIORITY_LOW_COLOR="7BC043"     # Green

# Phase label color (purple)
PHASE_COLOR="B392F0"

# Type label colors
ENHANCEMENT_COLOR="A8DADC"      # Cyan
BUG_COLOR="F1FAEE"              # Light gray

# ============================================================================
# ADVANCED: Issue Template Customization
# ============================================================================

# Default acceptance criteria for features
DEFAULT_ACCEPTANCE_CRITERIA=(
  "Implementation is complete and working"
  "Code follows project standards"
  "Tests are passing"
  "Documentation is updated"
)

# Default acceptance criteria for bugs
DEFAULT_BUG_CRITERIA=(
  "Bug is reproducible"
  "Root cause identified"
  "Fix implemented and tested"
  "Regression tests added"
)

# ============================================================================
# ADVANCED: Automation Settings
# ============================================================================

# Auto-detect phase from git branch name (true/false)
AUTO_DETECT_PHASE=true

# Auto-add status-todo label on issue creation (true/false)
AUTO_ADD_TODO_STATUS=true

# Enable GitHub Actions auto-labeling (true/false)
ENABLE_AUTO_LABELING=true

# ============================================================================
# DO NOT EDIT: Internal Configuration
# ============================================================================

# Script version
CONFIG_VERSION="1.0.0"

# Config file location
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${CONFIG_DIR}/../.." && pwd)"

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
