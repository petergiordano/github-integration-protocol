# Testing Guide

Comprehensive testing documentation for the GitHub Integration Protocol.

## Quick Start

After installing the GitHub Integration Protocol in your project, run the test suite to verify everything works:

```bash
# Basic test (creates real test issues - recommended for first run)
./scripts/test-integration.sh

# Dry run mode (no issues created - safe mode)
./scripts/test-integration.sh --dry-run

# Test and auto-cleanup (creates and closes test issues)
./scripts/test-integration.sh --cleanup
```

## What Gets Tested

The test suite validates all critical functionality and bug fixes:

### 1. Environment & Prerequisites
- ✅ Bash version 3.2+ (macOS compatibility)
- ✅ GitHub CLI (gh) installation and authentication
- ✅ Git installation
- ✅ Repository access

### 2. Bug Fix Validations

**Bug 1: Bash 3.2 Compatibility**
- Tests lowercase conversion without `${variable,,}` syntax
- Validates `validate_priority()` with uppercase/mixed case input
- Ensures compatibility with macOS default Bash (3.2.57)

**Bug 2: Command Quoting**
- Tests multiline string preservation
- Validates special character handling
- Ensures `gh_with_retry()` doesn't use `eval`

**Bug 3: Issue Body Generation**
- Tests heredoc-based body generation
- Validates proper newline handling
- Ensures no literal `\n` characters in output

**Bug 4: Log Output to stderr**
- Tests that log functions output to stderr only
- Validates command substitution isn't contaminated
- Ensures clean issue titles without log messages

**Bug 5: Bash Version Check**
- Validates version check accepts Bash 3.2+
- Tests validation script compatibility

### 3. Core Functionality
- ✅ Validation functions (title, description, phase, priority)
- ✅ ID generation (sequential, zero-padded)
- ✅ Issue creation (end-to-end)
- ✅ Status updates (todo → in-progress → complete)
- ✅ Retry mechanism

## Test Modes

### Standard Mode (Default)

Creates real test issues in your repository:

```bash
./scripts/test-integration.sh
```

**Pros:**
- Most comprehensive testing
- Validates actual GitHub API integration
- Tests complete workflow

**Cons:**
- Creates issues in your repo (labeled with `test-run`)
- Requires manual cleanup if not using `--cleanup`

**Best for:** Initial setup validation, major changes

### Dry Run Mode

Runs all tests except actual issue creation:

```bash
./scripts/test-integration.sh --dry-run
```

**Pros:**
- Safe - doesn't create issues
- Fast execution
- Good for quick validation

**Cons:**
- Skips E2E and status update tests
- Doesn't test GitHub API integration

**Best for:** Development, quick checks, CI/CD

### Auto-Cleanup Mode

Creates issues and automatically closes them after testing:

```bash
./scripts/test-integration.sh --cleanup
```

**Pros:**
- Full testing including E2E
- Automatic cleanup
- Leaves repo clean

**Cons:**
- Closed issues still visible in issue history
- Requires write permissions

**Best for:** Regular testing, validation before releases

## Understanding Test Output

### Success Example

```
╔════════════════════════════════════════════════════════════╗
║        GitHub Integration Protocol Test Suite             ║
╚════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST: Environment & Prerequisites
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ PASS: Bash version 4.0 is >= 3.2 (macOS compatible)
✓ PASS: GitHub CLI (gh) is installed
  GitHub CLI version: 2.40.0
✓ PASS: Git is installed
✓ PASS: GitHub CLI is authenticated
✓ PASS: Repository is accessible

...

╔════════════════════════════════════════════════════════════╗
║                      Test Summary                          ║
╚════════════════════════════════════════════════════════════╝

  Total Tests:   10
  Passed:        45
  Failed:        0

✓ All tests passed!
```

### Failure Example

```
✗ FAIL: Bash version 3.1 is < 3.2
```

When tests fail, review the error messages and fix the underlying issues before proceeding.

## Manual Cleanup

If you ran tests without `--cleanup`, you can manually clean up test issues:

```bash
# List all test issues
gh issue list --repo <owner>/<repo> --label test-run

# Close a specific test issue
gh issue close <issue-number> --repo <owner>/<repo>

# Close all test issues (requires jq)
gh issue list --repo <owner>/<repo> --label test-run --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --repo <owner>/<repo> --comment "Cleaning up test issue"
```

## Continuous Improvement

### Adding New Tests

The test script is designed to be extended. To add new tests:

1. **Create a test function** following the naming pattern `test_*`:

```bash
test_my_new_feature() {
    test_start "My New Feature"

    # Your test logic here
    assert_equals "expected" "actual" "Description of what's being tested"
    assert_success "some_command" "Command should succeed"

    # Custom validation
    if [ condition ]; then
        test_pass "Custom test passed"
    else
        test_fail "Custom test failed"
    fi
}
```

2. **Add your test to main()** in the test runner section:

```bash
main() {
    # ...existing tests...
    test_my_new_feature  # Add your test here
    # ...rest of main...
}
```

3. **Use available assertions**:
   - `assert_equals <expected> <actual> <message>` - Test equality
   - `assert_contains <haystack> <needle> <message>` - Test substring
   - `assert_not_contains <haystack> <needle> <message>` - Test no substring
   - `assert_success <command> <message>` - Test command succeeds
   - `test_pass <message>` - Manual pass
   - `test_fail <message>` - Manual fail

### Example: Adding a Label Test

```bash
test_label_existence() {
    test_start "Required Labels Exist"

    local labels=("$STATUS_TODO" "$STATUS_IN_PROGRESS" "$STATUS_COMPLETE")

    for label in "${labels[@]}"; do
        if gh label list --repo "$REPO" | grep -q "$label"; then
            test_pass "Label exists: $label"
        else
            test_fail "Missing label: $label"
        fi
    done
}
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Test GitHub Integration Protocol

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup GitHub CLI
        run: |
          type -p gh > /dev/null || (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
          && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
          && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
          && sudo apt update \
          && sudo apt install gh -y)

      - name: Authenticate GitHub CLI
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: echo "$GH_TOKEN" | gh auth login --with-token

      - name: Run Tests (Dry Run)
        run: ./scripts/test-integration.sh --dry-run
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run tests before committing changes to scripts

if git diff --cached --name-only | grep -q "scripts/"; then
    echo "Running GitHub Integration Protocol tests..."
    ./scripts/test-integration.sh --dry-run

    if [ $? -ne 0 ]; then
        echo "Tests failed! Commit aborted."
        exit 1
    fi
fi
```

## Troubleshooting

### Common Issues

**"GitHub CLI not authenticated"**
```bash
# Solution: Login to GitHub CLI
gh auth login
```

**"Repository not accessible"**
```bash
# Solution: Verify repository configuration
cat .github-integration/config.sh | grep REPO
gh repo view <owner>/<repo>
```

**"Configuration file not found"**
```bash
# Solution: Run the installer first
./github-integration-kit/install.sh
```

**Tests hang during issue creation**
```bash
# Solution: Check GitHub API rate limits
gh api rate_limit

# Or use dry-run mode
./scripts/test-integration.sh --dry-run
```

## Best Practices

1. **Run tests after installation**
   ```bash
   ./scripts/test-integration.sh --cleanup
   ```

2. **Run dry-run tests during development**
   ```bash
   ./scripts/test-integration.sh --dry-run
   ```

3. **Use cleanup mode for regular testing**
   ```bash
   ./scripts/test-integration.sh --cleanup
   ```

4. **Add tests when fixing bugs**
   - Create a test that reproduces the bug
   - Fix the bug
   - Verify the test passes
   - Commit both the fix and the test

5. **Run tests before creating PRs**
   ```bash
   ./scripts/test-integration.sh --cleanup && echo "Ready to create PR!"
   ```

## Performance

Typical execution times:
- **Dry run mode**: ~5-10 seconds
- **Standard mode**: ~15-30 seconds (depends on GitHub API)
- **Cleanup mode**: ~20-40 seconds (includes issue closure)

## Contributing

When contributing improvements to the GitHub Integration Protocol:

1. Add tests for new features
2. Ensure all existing tests pass
3. Update this documentation
4. Run full test suite before submitting PR

```bash
# Full validation before PR
./scripts/test-integration.sh --cleanup
```

## Support

If you encounter issues with the test suite:

1. Check this documentation
2. Review test output for specific errors
3. Try dry-run mode to isolate issues
4. Check GitHub API status: https://www.githubstatus.com
5. Open an issue in the repository

## License

This test suite is part of the GitHub Integration Protocol and follows the same license as the main project.
