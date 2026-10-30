#!/usr/bin/env bash
# Restore Raycast settings from Bitwarden.
# Expects an item named "Raycast Settings" with the .rayconfig export attached
# and the export password in its password field.
set -euo pipefail
ITEM="Raycast Settings"

bw login --check >/dev/null 2>&1 || bw login
export BW_SESSION="${BW_SESSION:-$(bw unlock --raw)}"
bw sync >/dev/null

id="$(bw get item "$ITEM" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
file="$(bw get item "$ITEM" | python3 -c 'import json,sys; print(json.load(sys.stdin)["attachments"][0]["fileName"])')"
out="$(mktemp -d)/$file"

bw get attachment "$file" --itemid "$id" --output "$out" >/dev/null
bw get password "$ITEM" | pbcopy
echo "Export password copied to clipboard; paste it when Raycast asks."
open -a Raycast "$out"
