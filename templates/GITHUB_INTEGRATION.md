  # GitHub Integration - Usage Guide

This document provides comprehensive instructions for using the GitHub Issues integration in this project.

## Overview

This project uses **GitHub Issues as a database** - the single source of truth for all features, enhancements, and bugs. All project state is tracked through issue labels, making it easy to manage work across multiple AI agents and human developers.

## Quick Reference

### Create Issues

```bash
# Feature
./scripts/create-feature-issue.sh "Feature Title" "Description" "Phase 1" "high"

# Enhancement
./scripts/create-enhancement-issue.sh "Enhancement Title" "Description" "Phase 2" "medium"

# Bug
./scripts/create-bug-issue.sh "Bug Title" "Description" "Phase 1" "high"
```

### Update Status

```bash
# Via CLI
./scripts/update-issue-status.sh "FEAT-001" "in-progress"
./scripts/update-issue-status.sh "123" "complete"

# Via GitHub comment
# In any issue, comment: /status in-progress
# Or: /priority high
```

### List Issues

```bash
# All issues
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER

# By status
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER --label "status-in-progress"

# By phase
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER --label "Phase 1"

# By priority
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER --label "priority-high"
```

## Label System

### Status Labels
- `status-todo` - Not started yet
- `status-in-progress` - Currently being worked on
- `status-complete` - Work completed

### Priority Labels
- `priority-high` - High priority
- `priority-medium` - Medium priority
- `priority-low` - Low priority

### Phase Labels
Phases are customized for this project. Check `.github-integration/config.sh` for the current phase configuration.

### Type Labels
- `enhancement` - New features and improvements
- `bug` - Bug fixes

## Workflows

### Starting Work on an Issue

1. Find the issue in GitHub or via CLI
2. Update status to in-progress:
   ```bash
   ./scripts/update-issue-status.sh "FEAT-001" "in-progress"
   ```
3. Create a feature branch (optional):
   ```bash
   git checkout -b feat/FEAT-001-description
   ```
4. Implement the feature
5. Update status when complete:
   ```bash
   ./scripts/update-issue-status.sh "FEAT-001" "complete"
   ```

### Creating a New Feature

1. Create the issue:
   ```bash
   ./scripts/create-feature-issue.sh \
     "User authentication" \
     "Implement OAuth login with Google and GitHub" \
     "Phase 1" \
     "high"
   ```
2. The script will output the issue URL and ID
3. Start work using the workflow above

### Fixing a Bug

1. Create the bug issue:
   ```bash
   ./scripts/create-bug-issue.sh \
     "Login button not working" \
     "Login button does not respond to clicks on mobile devices" \
     "Phase 1" \
     "high"
   ```
2. Follow the standard workflow to fix and close

## Comment Commands

In any issue, you can use these commands in comments:

### Status Updates
- `/status todo` - Reset to todo
- `/status in-progress` - Mark as in-progress
- `/status wip` - Same as in-progress
- `/status complete` - Mark as complete
- `/status done` - Same as complete

### Priority Updates
- `/priority high` - Set to high priority
- `/priority medium` - Set to medium priority
- `/priority low` - Set to low priority

The GitHub Actions bot will automatically update labels and add a reaction to confirm.

## Advanced Usage

### Batch Operations

List all todo features:
```bash
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER \
  --label "enhancement" \
  --label "status-todo"
```

Close multiple issues:
```bash
for id in FEAT-001 FEAT-002 FEAT-003; do
  ./scripts/update-issue-status.sh "$id" "complete"
  gh issue close --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER "$id"
done
```

### Custom Queries

Find all high-priority bugs:
```bash
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER \
  --label "bug" \
  --label "priority-high" \
  --state open
```

Find all Phase 1 work:
```bash
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER \
  --label "Phase 1" \
  --state open
```

### Integration with GitHub Projects

Issues automatically appear in your GitHub Project board. You can:

1. View by status columns
2. Filter by phase
3. Sort by priority
4. Track progress visually

Access your project board:
```
https://github.com/users/REPO_OWNER_PLACEHOLDER/projects/PROJECT_NUMBER
```

## Troubleshooting

### Scripts Failing

Run validation:
```bash
./scripts/validate-workflow.sh
```

Check authentication:
```bash
gh auth status
```

Re-authenticate:
```bash
gh auth login
```

### Labels Missing

Re-run label setup:
```bash
./scripts/setup-github-labels.sh
```

### Can't Find Issue by ID

List all issues to find the number:
```bash
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER --limit 100 --state all
```

Search by title:
```bash
gh issue list --repo REPO_OWNER_PLACEHOLDER/REPO_NAME_PLACEHOLDER --search "FEAT-001"
```

## Best Practices

1. **Always create an issue before starting work**
   - Issues serve as documentation and tracking
   - Makes work visible to team and AI agents

2. **Update status promptly**
   - Move to in-progress when starting
   - Move to complete when done
   - Don't batch status updates

3. **Use descriptive titles**
   - Good: "Add OAuth login for Google and GitHub"
   - Bad: "Fix auth"

4. **Include acceptance criteria**
   - Makes completion criteria clear
   - Helps with testing and validation

5. **Link related issues**
   - Use "Relates to #123" in issue body
   - Use "Closes #123" in PR descriptions

6. **Use comment commands for quick updates**
   - Faster than CLI for simple status changes
   - Visible in issue history

## Configuration

All configuration is in `.github-integration/config.sh`:

```bash
# View configuration
cat .github-integration/config.sh

# Edit configuration
nano .github-integration/config.sh
```

After changing configuration, you may need to:
1. Re-run label setup if you changed phases
2. Update scripts if you changed prefixes
3. Update GitHub Actions workflow if you changed label names

## Additional Resources

- GitHub CLI Docs: https://cli.github.com/manual/
- GitHub Issues Guide: https://guides.github.com/features/issues/
- GitHub Projects: https://docs.github.com/en/issues/planning-and-tracking-with-projects

## Support

For issues with the integration itself:
1. Check `.github-integration/config.sh` for correct settings
2. Run `./scripts/validate-workflow.sh`
3. Check GitHub Actions logs in the Actions tab
4. Review installation: `./github-integration-kit/README.md`
