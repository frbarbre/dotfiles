#!/usr/bin/env bash
# Restore Raycast settings from Bitwarden.
# Expects an item named "Raycast Settings" with the .rayconfig export attached
# and the export password in its password field.
set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"
. "$DOT/lib/bw.sh"
ITEM="Raycast Settings"

bw_unlock

# Find the item by exact name and pull out what we need
read -r id file pw_ok < <(bw list items --search "$ITEM" | ITEM="$ITEM" python3 -c '
import json, os, sys
items = json.load(sys.stdin)
want = os.environ["ITEM"]
match = [i for i in items if i["name"].strip() == want]
if not match:
    names = ", ".join(repr(i["name"]) for i in items) or "none"
    sys.exit(f"No item named {want!r} (similar: {names})")
i = match[0]
att = i.get("attachments") or []
if not att:
    sys.exit("The item has no attachment (attachments need Bitwarden Premium)")
pw = bool((i.get("login") or {}).get("password"))
print(i["id"], att[0]["fileName"].replace(" ", "%20"), int(pw))
')
file="${file//%20/ }"

out="$(mktemp -d)/$file"
bw get attachment "$file" --itemid "$id" --output "$out" >/dev/null

if [ "$pw_ok" = 1 ]; then
  bw get password "$id" | pbcopy
  echo "Export password copied to clipboard; paste it when Raycast asks."
else
  echo "No password on the item; type the export password when Raycast asks."
fi
open -a Raycast "$out"
bw_done
