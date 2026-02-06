# Project Chimera: Multi-Stage Dockerfile
# Optimized for reproducibility and minimal image size
FROM python:3.11-slim AS base

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package management
RUN pip install --no-cache-dir uv

# Copy dependency files
COPY pyproject.toml ./

# Install Python dependencies
RUN uv pip install --system -r pyproject.toml || \
    (echo "If pyproject.toml doesn't have requirements, create requirements.txt" && \
     uv pip install --system -r requirements.txt || true)

# Development stage (for local development)
FROM base AS development
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Copy project files
COPY . .

# Create directories for agent temporary files
RUN mkdir -p /tmp/chimera

# Expose port (if API server is added)
EXPOSE 8000

# Default command for development
CMD ["python", "-m", "pytest", "tests/", "-v"]

# Production stage (minimal image)
FROM base AS production
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Copy only necessary files (exclude tests, docs, etc.)
COPY specs/ ./specs/
COPY skills/ ./skills/
COPY .mcp/ ./.mcp/
COPY .cursor/ ./.cursor/

# Create directories
RUN mkdir -p /tmp/chimera

# Production command (to be defined when API server is implemented)
CMD ["python", "-m", "chimera.main"]

# Test stage (for CI/CD)
FROM base AS test
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Copy all files including tests
COPY . .

# Run tests
CMD ["python", "-m", "pytest", "tests/", "-v", "--cov=.", "--cov-report=xml"]
