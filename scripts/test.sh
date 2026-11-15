#!/usr/bin/env bash
# Test the running architecture. Run after ./scripts/provision.sh
# Exit code 0 = all tests passed, 1 = something failed.
set -uo pipefail    # no "-e": run ALL tests even if one fails

cd "$(dirname "$0")/.."
URL="http://localhost:${HTTP_PORT:-80}"
PASS=0; FAIL=0

# Include monitoring containers in all checks if they are running
export COMPOSE_PROFILES=monitoring
MONITORING=$(docker compose ps -q prometheus)
EXPECTED=4; [ -n "$MONITORING" ] && EXPECTED=6

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL+1)); }

# Helper: list the networks a container is connected to (e.g. "frontend backend")
nets() {
  docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$1" \
    | sed 's/[^ ]*_\([a-z]*\)/\1/g'   # strip project prefix: "apples_frontend" -> "frontend"
}

# ---------------------------------------------------------------
echo "==> Test 1: all containers are running and healthy"
HEALTHY=$(docker compose ps --format '{{.Health}}' | grep -c '^healthy$' || true)
[ "$HEALTHY" -eq "$EXPECTED" ] && pass "$EXPECTED/$EXPECTED containers healthy" \
  || fail "only $HEALTHY/$EXPECTED containers healthy"

# ---------------------------------------------------------------
echo "==> Test 2: html page shows the number of apples from the DB"
DB_APPLES=$(docker compose exec -T mongo mongosh store --quiet \
  --eval 'db.fruits.findOne({name:"apples"}).qty')
PAGE_APPLES=$(curl -s "$URL" | sed -n 's/.*<span id="apples">\([0-9]*\)<\/span>.*/\1/p')
echo "     DB says: $DB_APPLES | page shows: $PAGE_APPLES"
[ -n "$PAGE_APPLES" ] && [ "$PAGE_APPLES" = "$DB_APPLES" ] \
  && pass "page shows $PAGE_APPLES apples (matches DB)" \
  || fail "page ($PAGE_APPLES) does not match DB ($DB_APPLES)"
[ "$PAGE_APPLES" = "5" ] && pass "apples = 5 as in required data" || fail "expected 5 apples"

# ---------------------------------------------------------------
echo "==> Test 3: load balancer spreads requests across app containers"
HOSTS=$(for i in $(seq 1 10); do
  curl -s "$URL" | sed -n 's/.*Served by container: \([a-z0-9]*\).*/\1/p'
done | sort -u | wc -l)
[ "$HOSTS" -ge 2 ] && pass "requests served by $HOSTS different app containers" \
  || fail "only $HOSTS app container answered"

# ---------------------------------------------------------------
echo "==> Test 4: network topology is correct"
NGINX=$(docker compose ps -q nginx)
MONGO=$(docker compose ps -q mongo)

[ "$(nets "$NGINX")" = "frontend " ] && pass "nginx is only on frontend" \
  || fail "nginx networks: $(nets "$NGINX")"
[ "$(nets "$MONGO")" = "backend " ] && pass "mongo is only on backend" \
  || fail "mongo networks: $(nets "$MONGO")"
for APP in $(docker compose ps -q app); do
  N=$(nets "$APP")
  [[ "$N" == *frontend* && "$N" == *backend* ]] && pass "app $APP is on frontend + backend" \
    || fail "app $APP networks: $N"
done

# ---------------------------------------------------------------
echo "==> Test 5: only nginx is exposed to the outside"
for SVC in mongo app; do
  for C in $(docker compose ps -q $SVC); do
    [ -z "$(docker port "$C")" ] && pass "$SVC ($C) has no open port" \
      || fail "$SVC ($C) exposes: $(docker port "$C")"
  done
done

# ---------------------------------------------------------------
echo "==> Test 6: nginx cannot reach the database (isolation)"
if docker compose exec -T nginx wget -q -T 2 -O /dev/null http://mongo:27017 2>/dev/null; then
  fail "nginx CAN reach mongo (should be isolated)"
else
  pass "nginx cannot reach mongo"
fi

# ---------------------------------------------------------------
echo "==> Test 7: monitoring (Prometheus + Grafana)"
if [ -z "$MONITORING" ]; then
  echo "     (skipped: monitoring not running, use ./scripts/provision.sh --monitoring)"
else
  UP=$(curl -s -G "http://localhost:${PROMETHEUS_PORT:-9090}/api/v1/query" \
        --data-urlencode 'query=sum(up{job="apples-app"})' | sed -n 's/.*"value":\[[^,]*,"\([0-9]*\)"\].*/\1/p')
  [ "$UP" = "2" ] && pass "Prometheus scrapes 2 app containers" || fail "Prometheus sees '$UP' app containers"

  CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${GRAFANA_PORT:-3001}/api/dashboards/uid/apples")
  [ "$CODE" = "200" ] && pass "Grafana dashboard 'Apples' is provisioned" || fail "Grafana dashboard HTTP $CODE"

  if docker compose exec -T prometheus wget -q -T 2 -O /dev/null http://mongo:27017 2>/dev/null; then
    fail "Prometheus CAN reach mongo (should be isolated)"
  else
    pass "Prometheus cannot reach mongo (isolated)"
  fi
fi

echo
echo "==> Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
