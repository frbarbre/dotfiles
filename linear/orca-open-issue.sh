#!/bin/bash
set -uo pipefail

ORCA="${ORCA_BIN:-/Applications/Orca.app/Contents/Resources/bin/orca}"
# Kept out of the dotfiles repo; one line with the main checkout's path.
DEFAULT_REPO_PATH="$(cat "$HOME/.linear/default-repo" 2>/dev/null)"
LOG="$HOME/.linear/orca-open-issue.log"

exec >>"$LOG" 2>&1
echo "--- $(date -Iseconds) issue=${LINEAR_ISSUE_IDENTIFIER:-} branch=${LINEAR_ISSUE_BRANCH_NAME:-} workDir=${LINEAR_WORK_DIR:-}"

# Linear hands us whatever directory was picked; Orca's `path:` selector only matches a
# registered repo root, so walk up to the main checkout (a linked worktree resolves to it too).
repo_path="${LINEAR_WORK_DIR:-}"
if [ -d "$repo_path" ]; then
  common_dir="$(cd "$repo_path" && /usr/bin/git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  if [ -n "$common_dir" ]; then
    repo_path="$(dirname "$common_dir")"
  fi
fi
[ -d "$repo_path" ] || repo_path="$DEFAULT_REPO_PATH"
if [ ! -d "$repo_path" ]; then
  echo "no repo: Linear gave no work dir and ~/.linear/default-repo is missing or wrong"
  exit 1
fi

# The name becomes the worktree slug, and Orca serves each worktree's dev server at
# <slug>.localhost — a DNS label, so it must stay under 63 chars. A Linear branch name blows
# past that on a long title and the dev URL stops resolving; the identifier never does.
name="$(printf '%s' "${LINEAR_ISSUE_IDENTIFIER:-${LINEAR_ISSUE_BRANCH_NAME:-linear-task}}" | tr '[:upper:]' '[:lower:]')"
prompt="${LINEAR_PROMPT:-Work on ${LINEAR_ISSUE_IDENTIFIER:-this issue}.}"

# Put the prompt on the clipboard rather than typing it into the agent: Orca's chat
# composer does not render PTY-delivered text, so cmd+V is the reliable hand-off.
printf '%s' "$prompt" | /usr/bin/pbcopy
echo "prompt copied to clipboard (${#prompt} chars)"

"$ORCA" open --json >/dev/null

# Best effort: a failed assignment is logged, but must not stop the workspace from opening.
if [ -n "${LINEAR_ISSUE_IDENTIFIER:-}" ]; then
  if "$ORCA" linear assignee set --id "$LINEAR_ISSUE_IDENTIFIER" --me --json >/dev/null; then
    echo "assigned $LINEAR_ISSUE_IDENTIFIER to me"
  else
    echo "could not assign $LINEAR_ISSUE_IDENTIFIER"
  fi
fi

# No --agent: Orca's `agentDefaultArgs.claude` appends --dangerously-skip-permissions, which
# outranks settings.json's defaultMode. Ticket work starts in plan mode, so this spawns claude
# itself below; every other Orca worktree keeps the bypass default.
# No --prompt: the agent starts empty and the prompt waits on the clipboard.
args=(
  worktree create
  --repo "path:$repo_path"
  --name "$name"
  --no-parent
  --activate
  --json
)
if [ -n "${LINEAR_ISSUE_IDENTIFIER:-}" ]; then
  args+=(--linear-issue "$LINEAR_ISSUE_IDENTIFIER")
fi

created="$("$ORCA" "${args[@]}" 2>&1)"
rc=$?
echo "$created"
[ $rc -eq 0 ] || exit $rc

worktree_path="$(printf '%s' "$created" | /usr/bin/python3 -c \
  'import json,sys; print(json.load(sys.stdin)["result"]["worktree"]["path"])' 2>/dev/null)"
if [ -z "$worktree_path" ]; then
  echo "could not read result.worktree.path; no agent started"
  exit 1
fi

echo "starting claude in plan mode at $worktree_path"
"$ORCA" terminal create \
  --worktree "path:$worktree_path" \
  --command "claude --permission-mode plan" \
  --focus \
  --json
