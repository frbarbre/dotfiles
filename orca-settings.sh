#!/usr/bin/env bash
# Back up or restore Orca settings via Bitwarden.
#   ./orca-settings.sh backup    export from Orca and store in Bitwarden
#   ./orca-settings.sh restore   download from Bitwarden and import into Orca
# Stored as the attachment of a secure note named "Orca Settings".
set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"
. "$DOT/lib/bw.sh"
ITEM="Orca Settings"
FILE="orca-settings.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bw_unlock
id="$(bw_item_id "$ITEM")"

case "${1:-}" in
  backup)
    orca settings export --output "$TMP/$FILE" 2>/dev/null
    if [ -z "$id" ]; then
      id="$(printf '{"type":2,"secureNote":{"type":0},"name":"%s","notes":"Restore with ~/.dotfiles/orca-settings.sh restore"}' "$ITEM" \
        | bw encode | bw create item | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
    else
      # Replace the previous export
      for att in $(bw get item "$id" | python3 -c 'import json,sys; [print(a["id"]) for a in json.load(sys.stdin).get("attachments") or []]'); do
        bw delete attachment "$att" --itemid "$id" >/dev/null
      done
    fi
    bw create attachment --file "$TMP/$FILE" --itemid "$id" >/dev/null
    echo "Saved Orca settings to Bitwarden item \"$ITEM\"."
    ;;
  restore)
    [ -n "$id" ] || { echo "No Bitwarden item named \"$ITEM\"" >&2; exit 1; }
    bw get attachment "$FILE" --itemid "$id" --output "$TMP/$FILE" >/dev/null
    pgrep -x Orca >/dev/null || { open -a Orca; sleep 8; }
    orca settings import --file "$TMP/$FILE" 2>/dev/null
    ;;
  *)
    echo "usage: $0 backup|restore" >&2; exit 1
    ;;
esac
bw lock >/dev/null
