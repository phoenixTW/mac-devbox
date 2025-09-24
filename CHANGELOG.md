# ## 0.0.3


#### Other Changes

* [#5](https://github.com/phoenixTW/mac-devbox/pull/5): patch: Fixed test installation.
* [#6](https://github.com/phoenixTW/mac-devbox/pull/6): patch: Fixed main branch test install.


# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Basic security validation for config directories and files
- Version command to display current version
- Comprehensive testing framework with bats
- Unit tests for core functions
- Integration tests for doctor command
- GitHub Actions workflow for automated testing
- Automated release workflow with semantic versioning
- Integration with [bump-version](https://github.com/phoenixTW/bump-version) action
- Integration with [changelog-ci](https://github.com/marketplace/actions/changelog-ci) for automated changelog generation
- CONTRIBUTING.md with development guidelines
- CHANGELOG.md for tracking changes

### Changed
- Fixed installer REPO placeholder to use correct repository
- Enhanced error handling with better validation
- Updated completions to include version command
- Release process now automated via GitHub Actions
- Version bumping based on PR branch naming convention
- Changelog generation now automated using [changelog-ci](https://github.com/marketplace/actions/changelog-ci)
- Release notes now include categorized changelog sections

### Fixed
- Installer now uses correct repository URL
- Better error messages for invalid configurations

## [1.0.0] - 2024-01-XX

### Added
- Initial release of devbox CLI
- Bootstrap command for full macOS setup
- Brew package management (formulae and casks)
- asdf tool management with version persistence
- Shell configuration (zsh, oh-my-zsh, agnoster theme)
- Doctor command for health checking
- Tab completion for zsh and bash
- Config management in ~/.devbox
- Idempotent operations for safe re-runs
- User-scoped installs (no sudo required)
- CI/CD with ShellCheck and smoke tests
