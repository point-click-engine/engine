# Contributing to Point & Click Engine

Thank you for your interest in contributing to the Point & Click Engine! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Documentation](#documentation)
- [Release Process](#release-process)

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please report unacceptable behavior to the maintainers.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. **Create** a new branch for your feature or bugfix
4. **Make** your changes
5. **Test** your changes thoroughly
6. **Submit** a pull request

## Development Setup

### Prerequisites

- Crystal 1.15.0 or later
- Raylib 5.0 or later
- Git

### Installation

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/engine.git
cd engine

# Install dependencies
shards install

# Run tests to verify setup
crystal spec
```

### macOS Setup

```bash
# Install Raylib via Homebrew
brew install raylib

# Install Crystal
brew install crystal
```

### Ubuntu/Linux Setup

```bash
# Install system dependencies
sudo apt-get update
sudo apt-get install -y \
  libasound2-dev \
  mesa-common-dev \
  libx11-dev \
  libxrandr-dev \
  libxi-dev \
  xorg-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  build-essential

# Install Crystal (follow official Crystal installation guide)
```

## Project Structure

The project follows a modular architecture:

```
src/
├── point_click_engine.cr      # Main entry point
├── core/                      # Core engine functionality
├── graphics/                  # Rendering and display
├── characters/                # Character system
├── scenes/                    # Scene management
├── inventory/                 # Inventory system
├── ui/                       # User interface
└── utils/                    # Utilities and helpers

spec/                         # Test files
├── spec_helper.cr            # Test setup
├── point_click_engine_spec.cr # Main tests
├── characters_spec.cr        # Character tests
├── graphics_spec.cr          # Graphics tests
└── scenes_spec.cr           # Scene tests

example/                      # Usage examples
.github/                      # GitHub workflows and templates
```

## Contributing Guidelines

### Code Style

- Follow Crystal's official style guide
- Use `crystal tool format` to format your code
- Write clear, descriptive variable and method names
- Add comments for complex logic
- Keep methods focused and small

### Commit Messages

Follow the conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(characters): add AI behavior system
fix(graphics): resolve display scaling issue
docs(readme): update installation instructions
```

### Branching Strategy

- `main`/`master`: Stable release branch
- `develop`: Development branch (if used)
- `feature/description`: New features
- `fix/description`: Bug fixes
- `docs/description`: Documentation updates

### Module Guidelines

When contributing to specific modules:

#### Core Module
- Changes to the main engine should be backward compatible
- Consider performance implications
- Update version number if needed

#### Graphics Module
- Test on multiple screen resolutions
- Ensure proper resource cleanup
- Consider mobile/low-end hardware

#### Characters Module
- Maintain clear separation between Player and NPC
- Ensure AI behaviors are modular and reusable
- Test animation state transitions

#### Scenes Module
- Validate hotspot interactions
- Test scene transitions
- Ensure proper memory management

## Pull Request Process

1. **Create a branch** from `main` for your changes
2. **Make your changes** following the guidelines above
3. **Add tests** for new functionality
4. **Update documentation** as needed
5. **Run the full test suite** and ensure all tests pass
6. **Run `crystal tool format`** to format your code
7. **Submit a pull request** with a clear description

### PR Requirements

- [ ] All tests pass
- [ ] Code is properly formatted
- [ ] Documentation is updated
- [ ] Breaking changes are documented
- [ ] Changelog is updated (for significant changes)

### Review Process

1. Automated checks must pass (CI/CD)
2. At least one maintainer review required
3. Address review feedback promptly
4. Maintainer will merge when approved

## Testing

### Running Tests

```bash
# Run all tests
crystal spec

# Run specific test file
crystal spec spec/characters_spec.cr

# Run with verbose output
crystal spec --verbose
```

### Writing Tests

- Use descriptive test names
- Follow the existing test structure
- Test both success and failure cases
- Mock external dependencies when possible
- Aim for good test coverage

Example test structure:
```crystal
describe PointClickEngine::Characters::Player do
  it "initializes with default values" do
    player = PointClickEngine::Characters::Player.new("Hero", vec2(0, 0), vec2(32, 48))
    player.name.should eq("Hero")
    player.movement_enabled.should be_true
  end
end
```

### Integration Tests

- Test module interactions
- Verify backward compatibility
- Test example applications
- Performance testing for critical paths

## Documentation

### API Documentation

- Use Crystal's documentation comments
- Include usage examples
- Document parameters and return values
- Note any side effects or special considerations

```crystal
# Creates a new character with the specified properties.
#
# ```
# character = Character.new("Hero", vec2(100, 200), vec2(32, 48))
# character.add_animation("walk", 0, 4, 0.15, true)
# ```
#
# NOTE: The character starts in idle state by default.
def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
```

### Guides and Tutorials

- Keep examples up to date
- Test all code examples
- Include common use cases
- Provide troubleshooting information

### README Updates

- Update feature lists
- Keep installation instructions current
- Update compatibility information
- Include new examples

## Release Process

### Version Numbering

We follow Semantic Versioning (SemVer):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes (backward compatible)

### Release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version number is bumped
- [ ] Examples are tested
- [ ] Backward compatibility is verified

### Creating a Release

1. Update version in `shard.yml`
2. Update `CHANGELOG.md`
3. Create and push git tag: `git tag v1.0.0`
4. GitHub Actions will automatically create the release

## Getting Help

- **Issues**: Use GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub discussions for questions
- **Discord**: Join our community Discord (if available)
- **Email**: Contact maintainers directly for sensitive issues

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for significant contributions
- README.md contributors section
- Release notes for major features

Thank you for contributing to the Point & Click Engine!