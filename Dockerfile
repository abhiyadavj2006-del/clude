# clude (Claude Code Proxy) — Render deployment
# Render's native Python runtimes top out below 3.14, so this deploys
# from a Dockerfile. Base image is Python 3.14 because the project
# requires >=3.14 (see pyproject.toml) and uses uv for everything.
FROM python:3.14

# Install uv from the official Astral image (no curl needed).
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Faster, quieter uv runs; do not let uv re-resolve the lockfile.
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_SYNC=0 \
    PYTHONUNBUFFERED=1

# Install dependencies first (cached layer) — needs the lockfile.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

# Then the application code.
COPY . .
RUN uv sync --frozen --no-dev

# Render injects $PORT at runtime; 8082 is only the local fallback
# (the app's own default port, see config/settings.py).
ENV PORT=8082
EXPOSE 8082

# Shell form so $PORT expands at container start. Mirrors the README
# command `uv run uvicorn server:app --host 0.0.0.0 --port 8082`,
# with Render's $PORT in place of the fixed 8082.
CMD ["sh", "-c", "uv run uvicorn server:app --host 0.0.0.0 --port $PORT --timeout-graceful-shutdown 5"]
