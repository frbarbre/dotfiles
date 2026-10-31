# Shared Bitwarden helpers. Source this file, don't run it.

# Log in or unlock once and export BW_SESSION for the rest of the script.
bw_unlock() {
  if [ -z "${BW_SESSION:-}" ]; then
    if bw login --check >/dev/null 2>&1; then
      BW_SESSION="$(bw unlock --raw)"
    else
      BW_SESSION="$(bw login --raw)"
    fi
    export BW_SESSION
  fi
  bw sync >/dev/null
}

# Print the id of the item with exactly this name, or nothing.
bw_item_id() {
  bw list items --search "$1" | NAME="$1" python3 -c '
import json, os, sys
for i in json.load(sys.stdin):
    if i["name"].strip() == os.environ["NAME"]:
        print(i["id"]); break
'
}
