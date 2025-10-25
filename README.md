# GitHub Integration Protocol - Portable Kit

A production-grade GitHub Issues management system that can be deployed to any repository. Uses GitHub Issues as a database and single source of truth for project management.

## Features

- **Database-Driven Development**: GitHub Issues as authoritative data source
- **Automated Issue Creation**: CLI scripts for features, enhancements, and bugs
- **Sequential ID Generation**: Auto-generated FEAT-001, ENH-001, BUG-001 identifiers
- **Status Tracking**: todo → in-progress → complete workflow
- **Retry Logic**: Automatic 3-attempt retry with exponential backoff
- **GitHub Actions**: Auto-labeling and comment commands
- **Multi-Agent Support**: Protocols for AI agent collaboration
- **VS Code Integration**: Task automation built-in

## Quick Start

### 1. Install the Integration

```bash
# Clone or download this kit
cd your-project-root

# Run the installer
./github-integration-kit/install.sh
```

### 2. Configure Your Project

Edit the generated `.github-integration/config.sh`:

```bash
# Repository settings
REPO_OWNER="your-github-username"
REPO_NAME="your-repo-name"
PROJECT_NUMBER="1"

# Issue prefix customization
FEATURE_PREFIX="FEAT"
ENHANCEMENT_PREFIX="ENH"
BUG_PREFIX="BUG"

# Phase/milestone names (customize as needed)
PHASES=("Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5")
```

### 3. Setup GitHub Labels

```bash
./scripts/setup-github-labels.sh
```

### 4. Validate Installation

```bash
./scripts/validate-workflow.sh
```

### 5. Create Your First Issue

```bash
./scripts/create-feature-issue.sh "My First Feature" "Description here" "Phase 1" "High"
```

## What Gets Installed

```
your-project/
├── .github/
│   ├── workflows/
│   │   └── auto-label.yml          # Auto-labeling automation
│   └── ISSUE_TEMPLATE/
│       ├── config.yml
│       ├── feature_form.yml
│       ├── enhancement_form.yml
│       └── bug_form.yml
├── .github-integration/
│   ├── config.sh                   # Your project configuration
│   └── templates/                  # Documentation templates
├── scripts/
│   ├── issue-utils.sh              # Core library
│   ├── create-feature-issue.sh
│   ├── create-enhancement-issue.sh
│   ├── create-bug-issue.sh
│   ├── update-issue-status.sh
│   ├── setup-github-labels.sh
│   └── validate-workflow.sh
└── docs/
    ├── GITHUB_INTEGRATION.md       # Usage guide
    └── AGENTS.md                   # AI agent protocol (optional)
```

## Configuration Options

### Basic Configuration (`.github-integration/config.sh`)

```bash
# Required settings
REPO_OWNER="username"              # GitHub username or org
REPO_NAME="repo-name"              # Repository name
PROJECT_NUMBER="1"                 # GitHub Project number

# Optional: Customize issue prefixes
FEATURE_PREFIX="FEAT"              # Feature prefix (FEAT-001)
ENHANCEMENT_PREFIX="ENH"           # Enhancement prefix
BUG_PREFIX="BUG"                   # Bug prefix

# Optional: Phase/milestone configuration
PHASES=(
  "Planning"
  "Development"
  "Testing"
  "Deployment"
)

# Optional: Retry configuration
MAX_RETRY_ATTEMPTS=3
RETRY_DELAY=2
```

### Advanced Configuration

```bash
# Custom label colors
STATUS_COLOR="4C9AFF"              # Blue
PRIORITY_HIGH_COLOR="D73A4A"       # Red
PRIORITY_MEDIUM_COLOR="FB8500"     # Orange
PRIORITY_LOW_COLOR="7BC043"        # Green
PHASE_COLOR="B392F0"               # Purple

# Status labels (customize names)
STATUS_TODO="status-todo"
STATUS_IN_PROGRESS="status-in-progress"
STATUS_COMPLETE="status-complete"

# Priority labels
PRIORITY_HIGH="priority-high"
PRIORITY_MEDIUM="priority-medium"
PRIORITY_LOW="priority-low"
```

## Usage Examples

### Create Issues

```bash
# Feature with auto-detected phase
./scripts/create-feature-issue.sh "User authentication" "Implement OAuth login"

# Enhancement with specific phase
./scripts/create-enhancement-issue.sh "Improve performance" "Optimize database queries" "Phase 2" "High"

# Bug fix
./scripts/create-bug-issue.sh "Fix login redirect" "Users not redirected after login" "Phase 1" "High"
```

### Update Issue Status

```bash
# Update by issue number
./scripts/update-issue-status.sh "123" "status-in-progress"

# Update by ID
./scripts/update-issue-status.sh "FEAT-001" "status-complete"
```

### Comment Commands (via GitHub Actions)

In any issue comment, use:
- `/status todo` - Set status to todo
- `/status in-progress` - Set status to in-progress
- `/status complete` - Set status to complete
- `/priority high` - Set priority to high
- `/priority medium` - Set priority to medium
- `/priority low` - Set priority to low

## Customization Guide

### Custom Issue Types

To add a new issue type (e.g., "TASK"):

1. Edit `.github-integration/config.sh`:
```bash
TASK_PREFIX="TASK"
```

2. Create script `scripts/create-task-issue.sh`:
```bash
#!/bin/bash
source "$(dirname "$0")/issue-utils.sh"
# Use the create_issue function with "TASK" prefix
```

3. Add to GitHub Actions workflow in `.github/workflows/auto-label.yml`:
```yaml
'[TASK-': ['task']
```

### Custom Phases

Edit your config file:
```bash
PHASES=(
  "Sprint 1"
  "Sprint 2"
  "Sprint 3"
  "Backlog"
)
```

Then run:
```bash
./scripts/setup-github-labels.sh
```

### AI Agent Integration (Optional)

For multi-agent collaboration:

1. Copy agent templates:
```bash
cp .github-integration/templates/AGENTS.md ./
cp .github-integration/templates/CLAUDE.md ./
```

2. Customize for your workflow
3. Add `.aicontext/context.md` for handoffs

## Architecture

### Core Principles

1. **GitHub Issues = Single Source of Truth**
   - No file-based status tracking
   - All state lives in GitHub
   - Labels represent status/priority/phase

2. **Simple Individual Issues**
   - One issue = one task
   - No complex dependency webs
   - Clear, actionable descriptions

3. **Resilient Operations**
   - Automatic retry on failure
   - Fallback to GitHub web UI
   - Validation before operations

### Label System

| Type | Purpose | Auto-Applied |
|------|---------|--------------|
| `status-*` | Track progress | Yes (on creation) |
| `priority-*` | Set importance | Optional |
| `Phase X` | Group by milestone | Optional |
| `enhancement` / `bug` | Issue type | Yes (via prefix) |

### Issue Lifecycle

```
CREATE → [status-todo] → [status-in-progress] → [status-complete]
   ↓           ↓                  ↓                     ↓
Script    Working on it    Implementation        Closed
```

## Requirements

- GitHub CLI (`gh`) version 2.0+
- Git
- Bash 4.0+
- GitHub repository with issues enabled
- GitHub token with `repo` and `project` scopes

## Troubleshooting

### "gh not found"
```bash
# Install GitHub CLI
brew install gh  # macOS
# or see https://cli.github.com/
```

### "API rate limit exceeded"
```bash
# Increase retry delay
export GH_RETRY_DELAY=5
```

### "Label already exists"
```bash
# Labels are idempotent - safe to re-run
./scripts/setup-github-labels.sh
```

### Script failures
```bash
# Run validation
./scripts/validate-workflow.sh

# Check authentication
gh auth status

# Re-authenticate if needed
gh auth login
```

## Uninstallation

To remove the integration:

```bash
# Remove scripts
rm -rf scripts/

# Remove GitHub configs
rm -rf .github/workflows/auto-label.yml
rm -rf .github/ISSUE_TEMPLATE/

# Remove config
rm -rf .github-integration/

# Remove labels (manual via GitHub UI)
```

## Support

- Issues: Use your repository's GitHub Issues
- Documentation: See `docs/GITHUB_INTEGRATION.md`
- Original Project: https://github.com/petergiordano/category-blueprint

## License

MIT License - Free to use in any project

---

**Built with ❤️ for database-driven development**
