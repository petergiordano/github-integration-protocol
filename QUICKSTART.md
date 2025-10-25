# GitHub Integration Protocol - Quick Start

Get up and running in 5 minutes.

## Prerequisites

```bash
# Install GitHub CLI (if not installed)
brew install gh          # macOS
# or visit https://cli.github.com/

# Authenticate
gh auth login
```

## Installation

### 1. Download & Run Installer

```bash
# Navigate to your project
cd /path/to/your/project

# Run installer
/path/to/github-integration-kit/install.sh
```

### 2. Answer Prompts

```
GitHub repository owner: your-username
Repository name: your-repo
GitHub Project number: 1
Customize issue prefixes? n
Run label setup now? y
```

### 3. Verify

```bash
./scripts/validate-workflow.sh
```

Should show: ✓ All checks passed!

## Usage

### Create Your First Issue

```bash
./scripts/create-feature-issue.sh \
  "User Authentication" \
  "Implement OAuth login with Google and GitHub" \
  "Phase 1" \
  "high"
```

Output:
```
[SUCCESS] Issue created: https://github.com/your-username/your-repo/issues/1
[SUCCESS] Issue ID: FEAT-001
```

### Update Issue Status

```bash
# Start working
./scripts/update-issue-status.sh "FEAT-001" "in-progress"

# Complete work
./scripts/update-issue-status.sh "FEAT-001" "complete"
```

### List Issues

```bash
# All issues
gh issue list

# By status
gh issue list --label "status-in-progress"

# By priority
gh issue list --label "priority-high"
```

### Comment Commands

In any GitHub issue, comment:
- `/status in-progress` - Update status
- `/status complete` - Mark complete
- `/priority high` - Change priority

## Available Scripts

```bash
./scripts/create-feature-issue.sh "Title" "Description" "Phase" "Priority"
./scripts/create-enhancement-issue.sh "Title" "Description" "Phase" "Priority"
./scripts/create-bug-issue.sh "Title" "Description" "Phase" "Priority"
./scripts/update-issue-status.sh "ISSUE-ID" "STATUS"
./scripts/setup-github-labels.sh
./scripts/validate-workflow.sh
```

## Workflow

```
1. Create issue
   ./scripts/create-feature-issue.sh "Title" "Description"

2. Start work
   ./scripts/update-issue-status.sh "FEAT-001" "in-progress"

3. Implement feature
   [Your code here]

4. Complete
   ./scripts/update-issue-status.sh "FEAT-001" "complete"

5. Close
   gh issue close FEAT-001
```

## Troubleshooting

### Scripts not found
```bash
ls -la scripts/
# If empty, re-run installer
```

### GitHub CLI errors
```bash
gh auth status
gh auth login  # if not authenticated
```

### Labels missing
```bash
./scripts/setup-github-labels.sh
```

### Validation fails
```bash
./scripts/validate-workflow.sh
# Fix any failed checks
```

## Next Steps

- **Read full docs**: `docs/GITHUB_INTEGRATION.md`
- **Customize**: Edit `.github-integration/config.sh`
- **Deploy guide**: `DEPLOYMENT_GUIDE.md`
- **View issues**: Visit your repository's Issues tab

## Common Commands

```bash
# Create high-priority feature
./scripts/create-feature-issue.sh "Title" "Description" "Phase 1" "high"

# Create bug report
./scripts/create-bug-issue.sh "Bug Title" "Description" "Phase 1" "high"

# Update to in-progress
./scripts/update-issue-status.sh "FEAT-001" "in-progress"

# List all in-progress work
gh issue list --label "status-in-progress"

# List all high-priority items
gh issue list --label "priority-high"

# View specific issue
gh issue view FEAT-001

# Close issue
gh issue close FEAT-001
```

## Help

- **Script help**: Run any script without arguments
- **GitHub CLI**: `gh help` or https://cli.github.com/manual/
- **Full docs**: See README.md and DEPLOYMENT_GUIDE.md

---

**You're all set!** Start creating issues and tracking your work. 🚀
