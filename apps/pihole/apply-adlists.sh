#!/usr/bin/env bash
# Apply apps/pihole/adlists.txt to the running Pi-hole via the v6 API.
#
#   ./apps/pihole/apply-adlists.sh              # add missing lists
#   ./apps/pihole/apply-adlists.sh --gravity    # ... and run gravity after
#   ./apps/pihole/apply-adlists.sh --dry-run    # just print the request body
#
# Password: $PIHOLE_PASSWORD, or read from the pihole-secrets Secret with kubectl.
# Duplicated lists are ignored by Pi-hole and reported in processed.errors.
set -euo pipefail

API=${PIHOLE_API:-http://100.104.129.86:8053/api}
HERE=$(cd "$(dirname "$0")" && pwd)
GRAVITY=false
DRY_RUN=false
for arg in "$@"; do
  case $arg in
    --gravity) GRAVITY=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

BODY=$(python3 - "$HERE/adlists.txt" <<'PY'
import json, sys
urls = [l.strip() for l in open(sys.argv[1])
        if l.strip() and not l.lstrip().startswith("#")]
print(json.dumps({"address": urls, "comment": "Firebog ticked (no Malicious)",
                  "groups": [0], "enabled": True}))
PY
)

if $DRY_RUN; then
  echo "$BODY"
  exit 0
fi

PW=${PIHOLE_PASSWORD:-$(kubectl get secret -n pihole pihole-secrets \
  -o jsonpath='{.data.FTLCONF_webserver_api_password}' | base64 -d)}
SID=$(curl -sf -X POST "$API/auth" -H 'Content-Type: application/json' \
  -d "$(python3 -c 'import json,sys; print(json.dumps({"password": sys.argv[1]}))' "$PW")" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["session"]["sid"])')

code=$(curl -s -o /tmp/apply-adlists.json -w '%{http_code}' -X POST "$API/lists?type=block" \
  -H "X-FTL-SID: $SID" -H 'Content-Type: application/json' -d "$BODY")
echo "POST /lists -> HTTP $code"
python3 - "$code" <<'PY'
import json, sys
code = sys.argv[1]
r = json.load(open("/tmp/apply-adlists.json"))
err = r.get("error", {})
if code == "400" and "already present" in str(err.get("hint", "")):
    print("all lists already present, nothing to do")
    sys.exit(0)
if code not in ("200", "201"):
    print("failed:", err.get("message"), "-", err.get("hint"))
    sys.exit(1)
p = r.get("processed", {})
print(f"added: {len(p.get('success', []))}, skipped: {len(p.get('errors', []))}")
for e in p.get("errors", []):
    print("  -", e)
PY

if $GRAVITY; then
  echo "Running gravity (this takes a while)..."
  curl -s -X POST "$API/action/gravity" -H "X-FTL-SID: $SID" | tail -8
fi
