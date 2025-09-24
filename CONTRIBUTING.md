# Contributing to devbox

Thank you for your interest in contributing to devbox! This document provides guidelines for contributing to the project.

## Development Workflow

### 1. Fork and Clone
```bash
git clone https://github.com/your-username/mac-devbox.git
cd mac-devbox
```

### 2. Create a Feature Branch
Use descriptive branch names that indicate the type of change:

```bash
# For new features (minor version bump)
git checkout -b feature/add-new-command

# For bug fixes (patch version bump)
git checkout -b fix/doctor-command-error

# For breaking changes (major version bump)
git checkout -b breaking/change-config-format
```

### 3. Branch Naming Convention

The branch name determines the semantic version bump when merged:

- **`feature/description`** → Minor version bump (1.0.0 → 1.1.0)
- **`fix/description`** → Patch version bump (1.0.0 → 1.0.1)
- **`breaking/description`** → Major version bump (1.0.0 → 2.0.0)
- **`chore/description`** → Patch version bump (1.0.0 → 1.0.1)
- **`docs/description`** → Patch version bump (1.0.0 → 1.0.1)

### 4. PR Labels (Recommended)

To ensure proper changelog categorization, add appropriate labels to your PRs:

- **`bug`**, **`bugfix`**, **`fix`** → Bug Fixes section
- **`feature`**, **`enhancement`** → New Features section
- **`docs`**, **`documentation`**, **`doc`** → Documentation Updates section
- **`improvements`**, **`refactor`**, **`chore`** → Code Improvements section
- **`security`** → Security Updates section
- **`performance`** → Performance Improvements section

Unlabeled PRs will appear in the "Other Changes" section.

### 5. Development Setup
```bash
make dev-setup  # Install bats and shellcheck
```

### 6. Make Changes
- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass: `make check`

### 7. Test Your Changes
```bash
make lint       # Run ShellCheck
make test       # Run all tests
make check      # Run both linting and tests
```

### 8. Commit Changes
Use conventional commit messages:
```bash
git add .
git commit -m "feat: add new export command"
git commit -m "fix: resolve doctor command error"
git commit -m "docs: update installation instructions"
```

### 9. Push and Create PR
```bash
git push origin feature/your-branch-name
```

Then create a Pull Request on GitHub.

## Automated Release Process

When your PR is merged to the main branch, GitHub Actions will automatically:

1. **Generate a new semantic version** based on your branch name
2. **Update the version** in `lib/common.sh`
3. **Create a git tag** with the new version
4. **Create a GitHub release** with changelog
5. **Upload release assets**

## Code Style Guidelines

### Bash Scripts
- Use `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail` for error handling
- Use descriptive variable names in `snake_case`
- Quote all variables: `"$var"`
- Add comments for complex logic
- Follow existing patterns in the codebase

### Testing
- Add unit tests for new functions in `tests/unit/`
- Add integration tests for new workflows in `tests/integration/`
- Use descriptive test names: `@test "function_name does specific thing"`
- Mock external dependencies when possible

### Documentation
- Update README.md for user-facing changes
- Update CHANGELOG.md for significant changes
- Add inline comments for complex logic
- Update completion scripts when adding new commands

## Pull Request Guidelines

### Before Submitting
- [ ] All tests pass (`make check`)
- [ ] Code follows style guidelines
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated (if applicable)
- [ ] Completion scripts are updated (if adding commands)

### PR Description
Include:
- Description of changes
- Type of change (feature/fix/breaking)
- Testing performed
- Any breaking changes

### Review Process
- Maintainers will review your PR
- Address any feedback promptly
- Keep PRs focused and reasonably sized
- Respond to review comments

## Release Process

Releases are automated based on branch naming:

- **Feature branches** → Minor version bump
- **Fix branches** → Patch version bump  
- **Breaking branches** → Major version bump

The [bump-version](https://github.com/phoenixTW/bump-version) action handles version generation automatically.

## Getting Help

- Open an issue for bugs or feature requests
- Use discussions for questions
- Check existing issues before creating new ones

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
