# GitHub Integration Protocol - Deployment Guide

Complete guide for deploying this GitHub Issues integration system to any repository.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Customization](#customization)
5. [Verification](#verification)
6. [Usage](#usage)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

1. **Git** (version 2.0+)
   ```bash
   git --version
   ```
   Install: https://git-scm.com/downloads

2. **GitHub CLI** (version 2.0+)
   ```bash
   gh --version
   ```
   Install: https://cli.github.com/

3. **Bash** (version 4.0+)
   ```bash
   bash --version
   ```
   Pre-installed on macOS/Linux. Windows: Use Git Bash or WSL

### GitHub Setup

1. **GitHub Account** with access to target repository
2. **GitHub Personal Access Token** with scopes:
   - `repo` (full control of private repositories)
   - `project` (full control of projects)
   - `read:org` (read organization data)

3. **Authenticate GitHub CLI**:
   ```bash
   gh auth login
   ```
   Follow prompts to authenticate.

4. **Verify authentication**:
   ```bash
   gh auth status
   ```

### Repository Setup

1. **Initialize git** (if not already):
   ```bash
   git init
   git remote add origin https://github.com/your-username/your-repo.git
   ```

2. **Enable GitHub Issues** in repository settings:
   - Go to Settings → Features
   - Ensure "Issues" is checked

3. **Create GitHub Project** (optional but recommended):
   - Go to Projects tab
   - Click "New project"
   - Note the project number from URL

## Installation

### Step 1: Download Integration Kit

**Option A: Clone from source repository**
```bash
cd /tmp
git clone https://github.com/petergiordano/category-blueprint.git
cp -r category-blueprint/github-integration-kit ~/github-integration-kit
```

**Option B: Download as standalone package**
```bash
# If available as a release or separate repo
git clone https://github.com/your-org/github-integration-kit.git ~/github-integration-kit
```

### Step 2: Navigate to Your Project

```bash
cd /path/to/your/project
```

### Step 3: Run Installer

```bash
~/github-integration-kit/install.sh
```

Or if copied to your project:
```bash
./github-integration-kit/install.sh
```

### Step 4: Follow Installation Prompts

The installer will ask for:

1. **GitHub repository owner**: Your username or organization
   ```
   Example: myusername or myorg
   ```

2. **Repository name**: The name of your repository
   ```
   Example: my-awesome-project
   ```

3. **GitHub Project number**: Find in project URL
   ```
   Example: 1
   From: https://github.com/users/myusername/projects/1
   ```

4. **Customize issue prefixes?**: (y/n)
   - Default: FEAT, ENH, BUG
   - Custom: Any 3-4 letter codes

5. **Define phases**: Comma-separated list
   - Default: Phase 1, Phase 2, Phase 3, Phase 4, Phase 5
   - Custom: Sprint 1, Sprint 2, Backlog
   - Or: Planning, Dev, Testing, Deploy

6. **Run label setup now?**: (y/n)
   - Recommended: yes
   - Creates all labels in GitHub

### Step 5: Verify Installation

```bash
./scripts/validate-workflow.sh
```

Expected output:
```
========================================
  GitHub Workflow Validation
========================================

Configuration:
  Repository: myusername/my-awesome-project
  Project: #1
  Config file: .github-integration/config.sh

1. Prerequisites
  ✓ Git installed
  ✓ GitHub CLI installed
  ✓ Bash 4.0+

2. GitHub Authentication
  ✓ GitHub CLI authenticated

3. Repository Access
  ✓ Repository exists and accessible
  ✓ Issues enabled

4. Required Labels
  ✓ All labels created

5. Scripts
  ✓ All scripts installed

6. GitHub Actions
  ✓ Auto-label workflow exists

7. Issue Templates
  ✓ Templates installed

========================================
Validation Summary
========================================
  Passed:   20
  Warnings: 0
  Failed:   0

✓ All checks passed!
```

## Configuration

### Basic Configuration

Edit `.github-integration/config.sh`:

```bash
# Open in your editor
nano .github-integration/config.sh
# or
code .github-integration/config.sh
```

Key settings:
```bash
# Repository
REPO_OWNER="your-username"
REPO_NAME="your-repo"
PROJECT_NUMBER="1"

# Issue prefixes
FEATURE_PREFIX="FEAT"
ENHANCEMENT_PREFIX="ENH"
BUG_PREFIX="BUG"

# Phases
PHASES=(
  "Phase 1"
  "Phase 2"
  "Phase 3"
)
```

### After Configuration Changes

If you change:
- **Prefixes**: Update `.github/workflows/auto-label.yml` manually
- **Phases**: Re-run `./scripts/setup-github-labels.sh`
- **Label names**: Update both scripts and workflow

## Customization

### Custom Issue Types

To add a new issue type (e.g., "TASK"):

1. **Add to config** (`.github-integration/config.sh`):
   ```bash
   TASK_PREFIX="TASK"
   ```

2. **Create script** (`scripts/create-task-issue.sh`):
   ```bash
   #!/bin/bash
   set -e
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "${SCRIPT_DIR}/issue-utils.sh"

   TITLE="$1"
   DESCRIPTION="$2"
   PHASE="${3:-$(detect_current_phase)}"
   PRIORITY="${4:-medium}"

   create_issue "$TASK_PREFIX" "$TITLE" "$DESCRIPTION" "$PHASE" "$PRIORITY"
   ```

3. **Make executable**:
   ```bash
   chmod +x scripts/create-task-issue.sh
   ```

4. **Update workflow** (`.github/workflows/auto-label.yml`):
   ```yaml
   const labelMappings = {
     '[FEAT-': ['enhancement'],
     '[ENH-': ['enhancement'],
     '[BUG-': ['bug'],
     '[TASK-': ['task']  // Add this line
   };
   ```

5. **Create label**:
   ```bash
   gh label create "task" --color "F9C74F" --description "Task item" --repo your-owner/your-repo
   ```

### Custom Phases

1. **Edit config**:
   ```bash
   PHASES=(
     "Sprint 1"
     "Sprint 2"
     "Sprint 3"
     "Backlog"
   )
   ```

2. **Re-create labels**:
   ```bash
   ./scripts/setup-github-labels.sh
   ```

3. **Update issue templates** (`.github/ISSUE_TEMPLATE/*.yml`):
   ```yaml
   - type: dropdown
     id: phase
     attributes:
       label: Phase
       options:
         - Sprint 1
         - Sprint 2
         - Sprint 3
         - Backlog
   ```

### Custom Label Colors

Edit config:
```bash
STATUS_COLOR="4C9AFF"              # Blue
PRIORITY_HIGH_COLOR="D73A4A"       # Red
PRIORITY_MEDIUM_COLOR="FB8500"     # Orange
PRIORITY_LOW_COLOR="7BC043"        # Green
PHASE_COLOR="B392F0"               # Purple
```

Then re-run:
```bash
./scripts/setup-github-labels.sh
```

## Verification

### Test Issue Creation

```bash
# Create a test feature
./scripts/create-feature-issue.sh \
  "Test Feature" \
  "This is a test feature to verify the integration" \
  "Phase 1" \
  "low"
```

Expected output:
```
[INFO] Creating feature issue...
[INFO] Repository: your-username/your-repo
[INFO] Prefix: FEAT
[SUCCESS] Generated ID: FEAT-001
[INFO] Creating issue: [FEAT-001]: Test Feature
[SUCCESS] Issue created: https://github.com/your-username/your-repo/issues/1
[SUCCESS] Issue ID: FEAT-001
```

### Test Status Update

```bash
./scripts/update-issue-status.sh "FEAT-001" "in-progress"
```

### Test Comment Commands

1. Go to the created issue in GitHub
2. Add a comment: `/status complete`
3. Verify the bot adds a reaction and updates labels

### Test GitHub Actions

Check workflow runs:
```bash
gh run list --repo your-username/your-repo --workflow "Auto Label Issues"
```

Or visit: `https://github.com/your-username/your-repo/actions`

## Usage

### Daily Workflow

**Morning**:
```bash
# List your in-progress work
gh issue list --repo your-username/your-repo --label "status-in-progress" --assignee @me
```

**Start new work**:
```bash
# Create issue
./scripts/create-feature-issue.sh "New Feature" "Description" "Phase 1" "high"

# Start working
./scripts/update-issue-status.sh "FEAT-002" "in-progress"
```

**Complete work**:
```bash
# Mark complete
./scripts/update-issue-status.sh "FEAT-002" "complete"

# Close issue
gh issue close --repo your-username/your-repo FEAT-002
```

### Team Collaboration

**View team progress**:
```bash
# All in-progress work
gh issue list --repo your-username/your-repo --label "status-in-progress"

# High priority items
gh issue list --repo your-username/your-repo --label "priority-high"

# Current phase work
gh issue list --repo your-username/your-repo --label "Phase 1"
```

**Assign work**:
```bash
gh issue edit 123 --repo your-username/your-repo --add-assignee username
```

## Troubleshooting

### Common Issues

**1. "Configuration file not found"**
```bash
# Verify installation
ls -la .github-integration/config.sh

# Re-run installer if missing
./github-integration-kit/install.sh
```

**2. "GitHub CLI not authenticated"**
```bash
gh auth login
gh auth status
```

**3. "Label already exists" errors**
```bash
# Safe to ignore - labels are idempotent
# Or delete existing labels first:
gh label list --repo your-username/your-repo
gh label delete "label-name" --repo your-username/your-repo --yes
```

**4. Scripts not executable**
```bash
chmod +x scripts/*.sh
```

**5. "API rate limit exceeded"**
```bash
# Increase retry delay
export GH_RETRY_DELAY=5

# Check rate limit status
gh api rate_limit
```

**6. GitHub Actions not triggering**
```bash
# Check workflow file syntax
cat .github/workflows/auto-label.yml

# Check workflow is enabled
gh workflow list --repo your-username/your-repo
gh workflow enable "Auto Label Issues" --repo your-username/your-repo
```

### Debug Mode

Enable verbose output:
```bash
set -x  # Enable debug mode
./scripts/create-feature-issue.sh "Test" "Description"
set +x  # Disable debug mode
```

### Manual Label Creation

If scripts fail, create labels manually:
```bash
gh label create "status-todo" --color "4C9AFF" --description "Not started" --repo your-username/your-repo
gh label create "status-in-progress" --color "4C9AFF" --description "In progress" --repo your-username/your-repo
gh label create "status-complete" --color "4C9AFF" --description "Complete" --repo your-username/your-repo
```

### Uninstallation

To remove the integration:
```bash
# Remove scripts
rm -rf scripts/

# Remove GitHub configs
rm -rf .github/workflows/auto-label.yml
rm -rf .github/ISSUE_TEMPLATE/

# Remove config
rm -rf .github-integration/

# Labels must be removed via GitHub UI or:
gh label delete "status-todo" --repo your-username/your-repo --yes
# etc...
```

## Next Steps

1. **Create your first real issue**
   ```bash
   ./scripts/create-feature-issue.sh "Your Feature" "Description" "Phase 1" "high"
   ```

2. **Set up your GitHub Project board**
   - Add automation to move issues between columns based on status labels

3. **Customize for your team**
   - Adjust phases to match your workflow
   - Add custom issue types if needed
   - Configure label colors to your brand

4. **Train your team**
   - Share `docs/GITHUB_INTEGRATION.md`
   - Demo comment commands
   - Show CLI workflows

5. **Integrate with CI/CD**
   - Link PR status to issue labels
   - Auto-close issues on PR merge
   - Add deployment gates based on issue status

## Support & Resources

- **Installation issues**: Re-run `./scripts/validate-workflow.sh`
- **GitHub CLI help**: `gh help` or https://cli.github.com/manual/
- **Workflow customization**: See `.github/workflows/auto-label.yml`
- **Source repository**: https://github.com/petergiordano/category-blueprint

---

**Congratulations!** You now have a production-grade GitHub Issues management system. Happy tracking! 🚀
