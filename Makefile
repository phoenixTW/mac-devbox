# Devbox CLI - Development Makefile

.PHONY: help test lint install clean release

# Default target
help:
	@echo "Available targets:"
	@echo "  test     - Run all tests"
	@echo "  lint     - Run ShellCheck on all scripts"
	@echo "  install  - Install devbox locally for testing"
	@echo "  clean    - Clean up temporary files"
	@echo "  release  - Create a new release (requires VERSION=x.y.z)"

# Run tests
test:
	@echo "Running tests..."
	bats tests/

# Run linting
lint:
	@echo "Running ShellCheck..."
	shellcheck bin/devbox lib/*.sh install.sh

# Install locally for testing
install:
	@echo "Installing devbox locally..."
	./install.sh

# Clean up temporary files
clean:
	@echo "Cleaning up..."
	find . -name "*.tmp" -delete
	find . -name ".DS_Store" -delete

# Create a new release (automated via GitHub Actions)
release:
	@echo "Releases are now automated via GitHub Actions!"
	@echo "To trigger a release:"
	@echo "  1. Create a PR with your changes"
	@echo "  2. Use branch naming convention:"
	@echo "     - 'feature/description' for minor version bump"
	@echo "     - 'fix/description' for patch version bump"
	@echo "     - 'breaking/description' for major version bump"
	@echo "  3. Merge the PR to main branch"
	@echo "  4. GitHub Actions will automatically create a tag and release"
	@echo ""
	@echo "For manual release (if needed):"
	@echo "  git tag -a \"v1.0.0\" -m \"Release v1.0.0\""
	@echo "  git push origin \"v1.0.0\""

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "Installing bats..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install bats-core; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y bats; \
		else \
			echo "Please install bats manually: https://github.com/bats-core/bats-core"; \
		fi; \
	fi
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "Installing shellcheck..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install shellcheck; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y shellcheck; \
		else \
			echo "Please install shellcheck manually: https://github.com/koalaman/shellcheck"; \
		fi; \
	fi
	@echo "Development environment ready!"

# Run all checks
check: lint test
	@echo "All checks passed!"
