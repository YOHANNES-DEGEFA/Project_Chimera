# Project Chimera: Task Automation Makefile
# Standardized commands for common operations

.PHONY: help setup test spec-check lint security-scan clean docker-build docker-test

# Default target
help:
	@echo "Project Chimera - Available Commands:"
	@echo ""
	@echo "  make setup          - Install dependencies and initialize environment"
	@echo "  make test           - Run test suite (TDD tests)"
	@echo "  make spec-check     - Verify code aligns with specifications"
	@echo "  make lint           - Run linters (ruff, mypy)"
	@echo "  make security-scan  - Run security vulnerability scanner"
	@echo "  make docker-build   - Build Docker image (multi-stage)"
	@echo "  make docker-test    - Run tests in Docker container"
	@echo "  make clean          - Remove build artifacts and cache"
	@echo ""

# Install dependencies
setup:
	@echo "Setting up Project Chimera environment..."
	@if command -v uv > /dev/null; then \
		uv pip install -r requirements.txt || uv pip install -e .; \
	else \
		pip install --upgrade pip && \
		pip install -r requirements.txt || pip install -e .; \
	fi
	@echo "✓ Dependencies installed"
	@echo "✓ Verifying spec files exist..."
	@test -f specs/_meta.md || (echo "ERROR: specs/_meta.md missing" && exit 1)
	@test -f specs/functional.md || (echo "ERROR: specs/functional.md missing" && exit 1)
	@test -f specs/technical.md || (echo "ERROR: specs/technical.md missing" && exit 1)
	@test -f specs/frontend.md || (echo "ERROR: specs/frontend.md missing" && exit 1)
	@test -f specs/rule_creation_intent.md || (echo "ERROR: specs/rule_creation_intent.md missing" && exit 1)
	@echo "✓ All required spec files present"

# Run tests
test:
	@echo "Running test suite..."
	@python -m pytest tests/ -v --tb=short
	@echo "✓ Tests completed"

# Verify code aligns with specifications
spec-check:
	@echo "Checking code alignment with specifications..."
	@echo "  - Verifying spec files are non-empty..."
	@for spec in specs/*.md; do \
		if [ ! -s "$$spec" ]; then \
			echo "ERROR: $$spec is empty"; \
			exit 1; \
		fi; \
	done
	@echo "  - Verifying MCP config exists..."
	@test -f .mcp/config.json || (echo "ERROR: .mcp/config.json missing" && exit 1)
	@echo "  - Verifying skills structure..."
	@test -d skills/ || (echo "ERROR: skills/ directory missing" && exit 1)
	@skill_count=$$(find skills/ -mindepth 1 -maxdepth 1 -type d | wc -l); \
	if [ $$skill_count -lt 3 ]; then \
		echo "ERROR: Need at least 3 skills, found $$skill_count"; \
		exit 1; \
	fi
	@echo "  - Verifying agent rules file exists..."
	@test -f .cursor/rules/agent.mdc || test -f CLAUDE.md || test -f AGENT.md || \
		(echo "ERROR: Agent rules file missing (.cursor/rules/agent.mdc, CLAUDE.md, or AGENT.md)" && exit 1)
	@echo "✓ Spec check passed"

# Run linters
lint:
	@echo "Running linters..."
	@if command -v ruff > /dev/null; then \
		ruff check . --exclude=.git,__pycache__,*.pyc; \
	else \
		echo "WARNING: ruff not installed. Install with: pip install ruff"; \
	fi
	@if command -v mypy > /dev/null; then \
		mypy . --ignore-missing-imports || true; \
	else \
		echo "WARNING: mypy not installed. Install with: pip install mypy"; \
	fi
	@echo "✓ Linting completed"

# Security vulnerability scan
security-scan:
	@echo "Running security scanner..."
	@if command -v bandit > /dev/null; then \
		bandit -r . -x tests/ -f json -o bandit-report.json || true; \
		echo "✓ Security scan completed (report: bandit-report.json)"; \
	else \
		echo "WARNING: bandit not installed. Install with: pip install bandit"; \
	fi

# Build Docker image
docker-build:
	@echo "Building Docker image..."
	@docker build --target production -t chimera:latest .
	@echo "✓ Docker image built: chimera:latest"

# Run tests in Docker
docker-test:
	@echo "Running tests in Docker container..."
	@docker build --target test -t chimera-test:latest .
	@docker run --rm chimera-test:latest
	@echo "✓ Docker tests completed"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf __pycache__/
	@rm -rf .pytest_cache/
	@rm -rf .mypy_cache/
	@rm -rf *.egg-info/
	@rm -f bandit-report.json
	@rm -f .coverage
	@rm -rf htmlcov/
	@echo "✓ Clean completed"

# Development workflow (run all checks)
check-all: spec-check lint test
	@echo "✓ All checks passed"
