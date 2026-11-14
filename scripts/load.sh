#!/usr/bin/env bash
# Send some traffic to the site so the Grafana graphs have data.
# Usage: ./scripts/load.sh [requests]   (default 300, ~10 per second)
set -euo pipefail
URL="http://localhost:${HTTP_PORT:-80}"
N="${1:-300}"

echo "==> Sending $N requests to $URL (~10/sec)"
for i in $(seq 1 "$N"); do
  curl -s -o /dev/null "$URL"
  sleep 0.1
  [ $((i % 50)) -eq 0 ] && echo "   $i/$N"
done
echo "✅ Done. Check the dashboard: http://localhost:3001"
