# GitHub Actions & Templates

This directory contains the GitHub Actions workflows and issue templates for the Point & Click Engine repository.

## Workflows

### Core CI/CD Workflows

- **`ci.yml`** - Main continuous integration pipeline
  - Runs on multiple OS (Ubuntu, macOS) and Crystal versions
  - Installs system dependencies (Raylib)
  - Runs tests and checks formatting
  - Builds project to verify compilation

- **`release.yml`** - Automated release process
  - Triggers on version tags (v*)
  - Creates GitHub releases with changelog
  - Builds example binaries for different platforms
  - Uploads release artifacts

### Code Quality Workflows

- **`lint.yml`** - Code quality checks
  - Crystal formatting verification
  - Ameba linting (static analysis)
  - Enforces code style guidelines

- **`coverage.yml`** - Test coverage reporting
  - Generates coverage reports (placeholder for future Crystal tools)
  - Comments coverage results on pull requests

### Documentation Workflows

- **`docs.yml`** - Documentation generation
  - Generates Crystal API documentation
  - Deploys to GitHub Pages automatically
  - Updates on main branch changes

### Security Workflows

- **`security.yml`** - Security scanning
  - Dependency vulnerability checking
  - Secret scanning with TruffleHog
  - File permission validation

### Maintenance Workflows

- **`stale.yml`** - Issue and PR maintenance
  - Automatically marks stale issues/PRs
  - Closes inactive items after grace period
  - Respects important labels and assignments

- **`labeler.yml`** - Automatic labeling
  - Auto-labels PRs based on file changes
  - Uses `.github/labeler.yml` configuration

- **`examples.yml`** - Example validation
  - Builds all example projects
  - Validates example structure and usage
  - Uploads example artifacts

## Issue Templates

### Bug Reports (`ISSUE_TEMPLATE/bug_report.yml`)
- Structured bug reporting with required fields
- Environment information collection
- Reproduction steps and code samples

### Feature Requests (`ISSUE_TEMPLATE/feature_request.yml`)
- Feature proposal with priority and complexity
- Module selection and usage examples
- Contribution willingness tracking

### Documentation (`ISSUE_TEMPLATE/documentation.yml`)
- Documentation improvement requests
- Target audience and location specification
- Documentation type categorization

## Configuration Files

- **`dependabot.yml`** - Dependency updates
  - Automated GitHub Actions updates
  - Placeholder for future Crystal dependency support

- **`CODEOWNERS`** - Code ownership
  - Defines review requirements for different areas
  - Team-based ownership assignments

- **`labeler.yml`** - Auto-labeling configuration
  - Maps file paths to labels
  - Organizes PRs by affected modules

## Templates

- **`pull_request_template.md`** - PR template
  - Comprehensive checklist for contributors
  - Module tracking and testing requirements
  - Breaking change documentation

- **`CONTRIBUTING.md`** - Contribution guidelines
  - Development setup instructions
  - Code style and commit message guidelines
  - Review process and requirements

- **`SECURITY.md`** - Security policy
  - Vulnerability reporting process
  - Supported versions and timelines
  - Security best practices

## Usage

These workflows automatically trigger based on:

- **Push to main/master**: ci.yml, docs.yml, security.yml
- **Pull requests**: ci.yml, lint.yml, coverage.yml, labeler.yml
- **Version tags**: release.yml
- **Schedule**: security.yml (weekly), stale.yml (daily)

## Customization

To customize for your fork:

1. Update team names in `CODEOWNERS`
2. Modify notification emails in `SECURITY.md`
3. Adjust stale timeouts in `stale.yml`
4. Add/remove labels in `labeler.yml`

## Required Secrets

No additional secrets are required - all workflows use `GITHUB_TOKEN` which is automatically provided.

## Badge Examples

Add these to your README.md:

```markdown
[![CI](https://github.com/point-click-engine/engine/workflows/CI/badge.svg)](https://github.com/point-click-engine/engine/actions/workflows/ci.yml)
[![Documentation](https://github.com/point-click-engine/engine/workflows/Documentation/badge.svg)](https://github.com/point-click-engine/engine/actions/workflows/docs.yml)
[![Security](https://github.com/point-click-engine/engine/workflows/Security/badge.svg)](https://github.com/point-click-engine/engine/actions/workflows/security.yml)
```