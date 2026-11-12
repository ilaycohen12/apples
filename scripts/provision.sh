#!/usr/bin/env bash
# Provision the whole architecture FROM SCRATCH with one command.
# Usage: ./scripts/provision.sh
set -euo pipefail   # stop on any error, undefined variable, or failed pipe

# Always run from the repo root (where docker-compose.yml is)
cd "$(dirname "$0")/.."

echo "==> Checking prerequisites"
command -v docker >/dev/null || { echo "ERROR: docker is not installed"; exit 1; }
docker compose version >/dev/null || { echo "ERROR: docker compose v2 is required"; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERROR: docker engine is not running"; exit 1; }

echo "==> Removing any previous deployment (containers, networks, DB volume)"
docker compose down --volumes --remove-orphans

echo "==> Building images and starting containers (waiting until all are healthy)"
docker compose up --detach --build --wait --wait-timeout 180

echo "==> Running containers"
docker compose ps

echo
echo "✅ Done! Open http://localhost:${HTTP_PORT:-80}"
