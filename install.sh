#!/bin/bash
# GitHub Integration Protocol - Installer
# Deploys the integration system to any repository
# Version 1.0.0

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BOLD}${BLUE}========================================${NC}"
    echo -e "${BOLD}${BLUE}  GitHub Integration Protocol Installer${NC}"
    echo -e "${BOLD}${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${BLUE}▶${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

prompt_user() {
    local prompt="$1"
    local default="$2"
    local response

    if [ -n "$default" ]; then
        read -p "$(echo -e ${BLUE}?${NC}) $prompt [$default]: " response
        response="${response:-$default}"
    else
        read -p "$(echo -e ${BLUE}?${NC}) $prompt: " response
    fi

    echo "$response"
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

check_prerequisites() {
    print_step "Checking prerequisites..."

    local missing=()

    # Check for git
    if ! command -v git &> /dev/null; then
        missing+=("git")
    else
        print_success "Git installed"
    fi

    # Check for GitHub CLI
    if ! command -v gh &> /dev/null; then
        missing+=("gh (GitHub CLI)")
    else
        print_success "GitHub CLI installed"
    fi

    # Check for bash version
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        print_warning "Bash 4.0+ recommended (current: ${BASH_VERSION})"
    else
        print_success "Bash version: ${BASH_VERSION}"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing[*]}"
        echo ""
        echo "Install missing tools:"
        echo "  - Git: https://git-scm.com/downloads"
        echo "  - GitHub CLI: https://cli.github.com/"
        exit 1
    fi

    # Check GitHub authentication
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI not authenticated"
        echo ""
        echo "Run: gh auth login"
        exit 1
    else
        print_success "GitHub CLI authenticated"
    fi

    # Check if in git repository
    if ! git rev-parse --git-dir &> /dev/null; then
        print_error "Not in a git repository"
        echo ""
        echo "Initialize git first: git init"
        exit 1
    else
        print_success "Git repository detected"
    fi
}

# ============================================================================
# Configuration Collection
# ============================================================================

collect_configuration() {
    print_step "Collecting project configuration..."
    echo ""

    # Detect repository info from git remote
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    local detected_owner=""
    local detected_repo=""

    if [[ "$remote_url" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
        detected_owner="${BASH_REMATCH[1]}"
        detected_repo="${BASH_REMATCH[2]}"
        print_info "Detected from git remote: ${detected_owner}/${detected_repo}"
        echo ""
    fi

    # Collect repository owner
    REPO_OWNER=$(prompt_user "GitHub repository owner (username or org)" "$detected_owner")

    # Collect repository name
    REPO_NAME=$(prompt_user "Repository name" "$detected_repo")

    # Collect project number
    echo ""
    print_info "Find your project number in the GitHub Projects URL:"
    print_info "https://github.com/users/${REPO_OWNER}/projects/NUMBER"
    PROJECT_NUMBER=$(prompt_user "GitHub Project number" "1")

    # Ask about customization
    echo ""
    CUSTOMIZE=$(prompt_user "Customize issue prefixes and phases? (y/n)" "n")

    if [[ "$CUSTOMIZE" =~ ^[Yy] ]]; then
        FEATURE_PREFIX=$(prompt_user "Feature prefix" "FEAT")
        ENHANCEMENT_PREFIX=$(prompt_user "Enhancement prefix" "ENH")
        BUG_PREFIX=$(prompt_user "Bug prefix" "BUG")

        echo ""
        print_info "Define phases (comma-separated)"
        print_info "Example: Phase 1, Phase 2, Phase 3"
        PHASES_INPUT=$(prompt_user "Phases" "Phase 1, Phase 2, Phase 3, Phase 4, Phase 5")
    else
        FEATURE_PREFIX="FEAT"
        ENHANCEMENT_PREFIX="ENH"
        BUG_PREFIX="BUG"
        PHASES_INPUT="Phase 1, Phase 2, Phase 3, Phase 4, Phase 5"
    fi

    echo ""
    print_success "Configuration collected"
}

# ============================================================================
# Installation Steps
# ============================================================================

create_directory_structure() {
    print_step "Creating directory structure..."

    mkdir -p "${TARGET_DIR}/.github/workflows"
    mkdir -p "${TARGET_DIR}/.github/ISSUE_TEMPLATE"
    mkdir -p "${TARGET_DIR}/.github-integration/templates"
    mkdir -p "${TARGET_DIR}/scripts"
    mkdir -p "${TARGET_DIR}/docs"
    mkdir -p "${TARGET_DIR}/.aicontext"

    print_success "Directories created"
}

install_config_file() {
    print_step "Installing configuration file..."

    # Copy template and replace values
    cp "${KIT_DIR}/templates/config.sh" "${TARGET_DIR}/.github-integration/config.sh"

    # Replace placeholders
    sed -i.bak "s/REPLACE_WITH_OWNER/${REPO_OWNER}/g" "${TARGET_DIR}/.github-integration/config.sh"
    sed -i.bak "s/REPLACE_WITH_REPO/${REPO_NAME}/g" "${TARGET_DIR}/.github-integration/config.sh"
    sed -i.bak "s/PROJECT_NUMBER=\"1\"/PROJECT_NUMBER=\"${PROJECT_NUMBER}\"/g" "${TARGET_DIR}/.github-integration/config.sh"

    # Update prefixes if customized
    if [[ "$CUSTOMIZE" =~ ^[Yy] ]]; then
        sed -i.bak "s/FEATURE_PREFIX=\"FEAT\"/FEATURE_PREFIX=\"${FEATURE_PREFIX}\"/g" "${TARGET_DIR}/.github-integration/config.sh"
        sed -i.bak "s/ENHANCEMENT_PREFIX=\"ENH\"/ENHANCEMENT_PREFIX=\"${ENHANCEMENT_PREFIX}\"/g" "${TARGET_DIR}/.github-integration/config.sh"
        sed -i.bak "s/BUG_PREFIX=\"BUG\"/BUG_PREFIX=\"${BUG_PREFIX}\"/g" "${TARGET_DIR}/.github-integration/config.sh"

        # Update phases array
        IFS=',' read -ra PHASE_ARRAY <<< "$PHASES_INPUT"
        local phases_string="PHASES=(\n"
        for phase in "${PHASE_ARRAY[@]}"; do
            phase=$(echo "$phase" | xargs)  # Trim whitespace
            phases_string+="  \"${phase}\"\n"
        done
        phases_string+=")"

        # This is complex for sed, so we'll use a marker approach
        echo "# Phases configured during installation" >> "${TARGET_DIR}/.github-integration/config.sh"
    fi

    rm "${TARGET_DIR}/.github-integration/config.sh.bak"

    print_success "Configuration file installed"
}

install_scripts() {
    print_step "Installing scripts..."

    # Copy all script templates and update them to source config
    for script in "${KIT_DIR}/script-templates"/*.sh; do
        if [ -f "$script" ]; then
            local script_name=$(basename "$script")
            cp "$script" "${TARGET_DIR}/scripts/${script_name}"
            chmod +x "${TARGET_DIR}/scripts/${script_name}"
        fi
    done

    print_success "Scripts installed"
}

install_github_workflows() {
    print_step "Installing GitHub Actions workflows..."

    # Copy auto-label workflow
    cp "${KIT_DIR}/templates/auto-label.yml" "${TARGET_DIR}/.github/workflows/auto-label.yml"

    # Update issue prefixes in workflow if customized
    if [[ "$CUSTOMIZE" =~ ^[Yy] ]]; then
        sed -i.bak "s/\\[FEAT-/\\[${FEATURE_PREFIX}-/g" "${TARGET_DIR}/.github/workflows/auto-label.yml"
        sed -i.bak "s/\\[ENH-/\\[${ENHANCEMENT_PREFIX}-/g" "${TARGET_DIR}/.github/workflows/auto-label.yml"
        sed -i.bak "s/\\[BUG-/\\[${BUG_PREFIX}-/g" "${TARGET_DIR}/.github/workflows/auto-label.yml"
        rm "${TARGET_DIR}/.github/workflows/auto-label.yml.bak"
    fi

    print_success "GitHub Actions installed"
}

install_issue_templates() {
    print_step "Installing issue templates..."

    # Copy all issue templates
    cp "${KIT_DIR}/templates/issue-templates"/* "${TARGET_DIR}/.github/ISSUE_TEMPLATE/" 2>/dev/null || true

    # Update prefixes in templates if customized
    if [[ "$CUSTOMIZE" =~ ^[Yy] ]]; then
        for template in "${TARGET_DIR}/.github/ISSUE_TEMPLATE"/*.yml; do
            if [ -f "$template" ]; then
                sed -i.bak "s/FEAT-/${FEATURE_PREFIX}-/g" "$template"
                sed -i.bak "s/ENH-/${ENHANCEMENT_PREFIX}-/g" "$template"
                sed -i.bak "s/BUG-/${BUG_PREFIX}-/g" "$template"
                rm "${template}.bak"
            fi
        done
    fi

    print_success "Issue templates installed"
}

install_documentation() {
    print_step "Installing documentation..."

    # Copy documentation templates
    cp "${KIT_DIR}/templates/GITHUB_INTEGRATION.md" "${TARGET_DIR}/docs/GITHUB_INTEGRATION.md" 2>/dev/null || true

    # Update documentation with project-specific info
    if [ -f "${TARGET_DIR}/docs/GITHUB_INTEGRATION.md" ]; then
        sed -i.bak "s/REPO_OWNER_PLACEHOLDER/${REPO_OWNER}/g" "${TARGET_DIR}/docs/GITHUB_INTEGRATION.md"
        sed -i.bak "s/REPO_NAME_PLACEHOLDER/${REPO_NAME}/g" "${TARGET_DIR}/docs/GITHUB_INTEGRATION.md"
        rm "${TARGET_DIR}/docs/GITHUB_INTEGRATION.md.bak"
    fi

    print_success "Documentation installed"
}

create_gitignore_entry() {
    print_step "Updating .gitignore..."

    if [ -f "${TARGET_DIR}/.gitignore" ]; then
        if ! grep -q ".github-integration/config.sh" "${TARGET_DIR}/.gitignore"; then
            echo "" >> "${TARGET_DIR}/.gitignore"
            echo "# GitHub Integration (keep config in version control)" >> "${TARGET_DIR}/.gitignore"
            echo "# .github-integration/config.sh" >> "${TARGET_DIR}/.gitignore"
        fi
        print_success ".gitignore updated"
    else
        print_warning ".gitignore not found, skipping"
    fi
}

# ============================================================================
# Post-Installation
# ============================================================================

setup_labels() {
    print_step "Setting up GitHub labels..."
    echo ""

    read -p "$(echo -e ${BLUE}?${NC}) Run label setup now? (y/n) [y]: " run_setup
    run_setup="${run_setup:-y}"

    if [[ "$run_setup" =~ ^[Yy] ]]; then
        if [ -f "${TARGET_DIR}/scripts/setup-github-labels.sh" ]; then
            bash "${TARGET_DIR}/scripts/setup-github-labels.sh"
        else
            print_warning "Label setup script not found"
        fi
    else
        print_info "Run later: ./scripts/setup-github-labels.sh"
    fi
}

print_next_steps() {
    echo ""
    echo -e "${BOLD}${GREEN}========================================${NC}"
    echo -e "${BOLD}${GREEN}  Installation Complete!${NC}"
    echo -e "${BOLD}${GREEN}========================================${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo ""
    echo "1. Review configuration:"
    echo -e "   ${BLUE}cat .github-integration/config.sh${NC}"
    echo ""
    echo "2. Setup GitHub labels (if not done):"
    echo -e "   ${BLUE}./scripts/setup-github-labels.sh${NC}"
    echo ""
    echo "3. Validate installation:"
    echo -e "   ${BLUE}./scripts/validate-workflow.sh${NC}"
    echo ""
    echo "4. Create your first issue:"
    echo -e "   ${BLUE}./scripts/create-feature-issue.sh \"My Feature\" \"Description\"${NC}"
    echo ""
    echo -e "${BOLD}Documentation:${NC}"
    echo "  - Quick start: docs/GITHUB_INTEGRATION.md"
    echo "  - Full guide: .github-integration/templates/README.md"
    echo ""
    echo -e "${BOLD}Configuration:${NC}"
    echo "  - Repository: ${REPO_OWNER}/${REPO_NAME}"
    echo "  - Project: #${PROJECT_NUMBER}"
    echo "  - Prefixes: ${FEATURE_PREFIX}, ${ENHANCEMENT_PREFIX}, ${BUG_PREFIX}"
    echo ""
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    print_header

    # Pre-flight checks
    check_prerequisites
    echo ""

    # Collect configuration
    collect_configuration
    echo ""

    # Confirm installation
    echo -e "${BOLD}Ready to install to:${NC} ${TARGET_DIR}"
    read -p "$(echo -e ${BLUE}?${NC}) Continue with installation? (y/n) [y]: " confirm
    confirm="${confirm:-y}"

    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        print_error "Installation cancelled"
        exit 0
    fi

    echo ""

    # Run installation
    create_directory_structure
    install_config_file
    install_scripts
    install_github_workflows
    install_issue_templates
    install_documentation
    create_gitignore_entry

    echo ""

    # Post-installation
    setup_labels
    print_next_steps
}

# Run installer
main "$@"
