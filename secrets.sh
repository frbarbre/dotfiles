#!/usr/bin/env bash
# Everything on a new Mac that needs a secret, behind one Bitwarden unlock.
#   ./secrets.sh save      store this Mac's GitHub login and Linear repo path in Bitwarden
#   ./secrets.sh restore   log in to GitHub, write ~/.linear/default-repo, join Tailscale,
#                          restore Raycast and Orca
set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"
. "$DOT/lib/bw.sh"

GH_ITEM="GitHub CLI Token"
LINEAR_ITEM="Linear Default Repo"
TAILSCALE_ITEM="Tailscale Auth Key"

# Create or overwrite a login item's password, or a secure note's notes.
# The secret comes in on stdin so it never shows up in the process list.
bw_put() { # name field(password|notes)
  local name="$1" field="$2" id value
  value="$(cat)"
  id="$(bw_item_id "$name")"
  if [ -n "$id" ]; then
    bw get item "$id" | FIELD="$field" VALUE="$value" python3 -c '
import json, os, sys
i = json.load(sys.stdin)
if os.environ["FIELD"] == "password":
    i.setdefault("login", {})["password"] = os.environ["VALUE"]
else:
    i["notes"] = os.environ["VALUE"]
print(json.dumps(i))' | bw encode | bw edit item "$id" >/dev/null
  else
    NAME="$name" FIELD="$field" VALUE="$value" python3 -c '
import json, os
if os.environ["FIELD"] == "password":
    i = {"type": 1, "name": os.environ["NAME"], "login": {"password": os.environ["VALUE"]}}
else:
    i = {"type": 2, "name": os.environ["NAME"], "secureNote": {"type": 0}, "notes": os.environ["VALUE"]}
print(json.dumps(i))' | bw encode | bw create item >/dev/null
  fi
  echo "saved \"$name\""
}

save() {
  gh auth token | bw_put "$GH_ITEM" password
  if [ -s "$HOME/.linear/default-repo" ]; then
    bw_put "$LINEAR_ITEM" notes < "$HOME/.linear/default-repo"
  fi
}

restore() {
  local id tmp

  id="$(bw_item_id "$GH_ITEM")"
  if [ -n "$id" ]; then
    bw get password "$id" | gh auth login --with-token
    gh auth setup-git
    gh extension install github/gh-stack || true
  else
    echo "!! No \"$GH_ITEM\" in Bitwarden: run gh auth login, then ./secrets.sh save"
  fi

  id="$(bw_item_id "$LINEAR_ITEM")"
  if [ -n "$id" ]; then
    mkdir -p "$HOME/.linear"
    bw get notes "$id" > "$HOME/.linear/default-repo"
    echo "wrote ~/.linear/default-repo"
  else
    echo "!! No \"$LINEAR_ITEM\" in Bitwarden: put the work repo's path in ~/.linear/default-repo"
  fi

  id="$(bw_item_id "$TAILSCALE_ITEM")"
  if [ -n "$id" ]; then
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' RETURN
    bw get password "$id" > "$tmp"
    sudo tailscale up --ssh --auth-key="file:$tmp"
  else
    echo "!! No \"$TAILSCALE_ITEM\" in Bitwarden: run sudo tailscale up --ssh"
  fi

  "$DOT/raycast.sh" || echo "!! Raycast restore failed, see above"
  "$DOT/orca-settings.sh" restore || echo "!! Orca restore failed, see above"
}

bw_unlock
case "${1:-}" in
  save) save ;;
  restore) restore ;;
  *) echo "usage: $0 save|restore" >&2; exit 1 ;;
esac
bw_done
