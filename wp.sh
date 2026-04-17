#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_PATH="$SITE_DIR/app/public"
LOCAL_SITES_JSON="$HOME/.config/Local/sites.json"
WPCLI_PHAR="/opt/Local/resources/extraResources/bin/wp-cli/wp-cli.phar"

if [[ ! -f "$WPCLI_PHAR" ]]; then
  echo "Eroare: nu gasesc WP-CLI phar la: $WPCLI_PHAR" >&2
  exit 1
fi

if [[ ! -f "$LOCAL_SITES_JSON" ]]; then
  echo "Eroare: nu gasesc Local sites.json la: $LOCAL_SITES_JSON" >&2
  exit 1
fi

SITE_ID="$(python3 -c 'import json, os, sys
sites_json = sys.argv[1]
site_dir = os.path.realpath(sys.argv[2])
home = os.path.expanduser("~")
with open(sites_json, "r", encoding="utf-8") as f:
    data = json.load(f)
for sid, cfg in data.items():
    raw = (cfg or {}).get("path", "")
    expanded = (raw.replace("~", home, 1) if raw.startswith("~") else raw)
    if os.path.realpath(expanded) == site_dir:
        print(sid)
        break' "$LOCAL_SITES_JSON" "$SITE_DIR" || true)"

if [[ -z "${SITE_ID:-}" ]]; then
  echo "Eroare: nu am gasit site-ul in Local sites.json pentru: $SITE_DIR" >&2
  exit 1
fi

MYSQL_SOCKET="$HOME/.config/Local/run/$SITE_ID/mysql/mysqld.sock"
if [[ ! -S "$MYSQL_SOCKET" ]]; then
  echo "Eroare: socket MySQL inexistent: $MYSQL_SOCKET" >&2
  echo "Asigura-te ca site-ul este pornit in Local." >&2
  exit 1
fi

exec php \
  -d "mysqli.default_socket=$MYSQL_SOCKET" \
  -d "mysql.default_socket=$MYSQL_SOCKET" \
  "$WPCLI_PHAR" \
  --path="$WP_PATH" \
  "$@"
