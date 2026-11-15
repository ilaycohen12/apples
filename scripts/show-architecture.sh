#!/usr/bin/env bash
# Show the LIVE architecture: reads the running containers from Docker
# and draws them with their networks, IPs and ports. Nothing is hardcoded.
set -euo pipefail
cd "$(dirname "$0")/.."
export COMPOSE_PROFILES=monitoring   # include monitoring containers if running

# Stop if nothing is running
if [ -z "$(docker compose ps -q)" ]; then
  echo "Nothing is running. Run ./scripts/provision.sh first."; exit 1
fi

# Compose project name (prefix of network names, e.g. "apples")
FIRST=$(docker compose ps -q | head -1)
PROJECT=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$FIRST")

# Helpers
name() { docker inspect -f '{{.Name}}' "$1" | sed 's#^/##'; }                 # container name
ip()   { docker inspect -f "{{(index .NetworkSettings.Networks \"${PROJECT}_$2\").IPAddress}}" "$1"; }
state(){ docker inspect -f '{{.State.Health.Status}}' "$1"; }                # healthy/unhealthy

NGINX=$(docker compose ps -q nginx)
MONGO=$(docker compose ps -q mongo)
PORT=$(docker compose port nginx 80 | sed 's/.*://')

echo "==> 1. Containers (live)"
docker compose ps --format 'table {{.Name}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

echo
echo "==> 2. Networks (live)"
for NET in frontend backend monitoring; do
  FULL="${PROJECT}_${NET}"
  docker network inspect "$FULL" >/dev/null 2>&1 || continue   # skip if not created
  INTERNAL=$(docker network inspect -f '{{.Internal}}' "$FULL")
  echo "  $FULL  (internal=$INTERNAL)"
  docker network inspect -f '{{range .Containers}}    - {{.Name}}  {{.IPv4Address}}{{"\n"}}{{end}}' "$FULL"
done

echo "==> 3. Topology diagram (live)"
echo
echo "        [ Browser ]"
echo "             |  http://localhost:$PORT"
echo "             v"
echo "   [ $(name "$NGINX") ]  $(state "$NGINX")"
echo "     frontend: $(ip "$NGINX" frontend)"
echo "             |"
echo "  ======== network: frontend ========"
echo "             |   (round-robin load balancing)"
for APP in $(docker compose ps -q app); do
  echo "   [ $(name "$APP") ]  $(state "$APP")"
  echo "     frontend: $(ip "$APP" frontend)   backend: $(ip "$APP" backend)"
done
echo "             |"
echo "  ======== network: backend (internal, no internet) ========"
echo "             |"
echo "   [ $(name "$MONGO") ]  $(state "$MONGO")"
echo "     backend: $(ip "$MONGO" backend)   (no open ports)"
PROM=$(docker compose ps -q prometheus)
if [ -n "$PROM" ]; then
  GRAF=$(docker compose ps -q grafana)
  echo
  echo "  ======== network: monitoring ========"
  echo "   [ $(name "$PROM") ]  $(state "$PROM")   scrapes app /metrics every 5s"
  echo "     monitoring: $(ip "$PROM" monitoring)   http://localhost:${PROMETHEUS_PORT:-9090}"
  echo "   [ $(name "$GRAF") ]  $(state "$GRAF")   dashboards"
  echo "     monitoring: $(ip "$GRAF" monitoring)   http://localhost:${GRAFANA_PORT:-3001}"
fi
echo
