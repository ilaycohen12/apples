#!/usr/bin/env bash
# Remove EVERYTHING this project created: containers, networks, DB volume, app image.
# Usage: ./scripts/destroy.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Stopping and removing containers, networks and the DB volume"
docker compose --profile monitoring down --volumes --remove-orphans

echo "==> Removing the app image we built (official mongo/nginx images are kept)"
docker image rm apples-app:latest 2>/dev/null || echo "   (app image already removed)"

echo
echo "✅ Everything removed. Run ./scripts/provision.sh to build again from scratch."
