#!/usr/bin/env bash
# One-shot setup for a fresh Mac:
#   curl -fsSL https://raw.githubusercontent.com/frbarbre/dotfiles/main/install.sh | bash
set -euo pipefail
REPO="https://github.com/frbarbre/dotfiles.git"
DOT="$HOME/.dotfiles"

# Ask for sudo once up front and keep it alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Sign in to the App Store first so `mas` apps install
open -a "App Store"

# Xcode Command Line Tools (provides git)
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# Repo
if [ -d "$DOT/.git" ]; then
  git -C "$DOT" pull --ff-only
else
  git clone "$REPO" "$DOT"
fi

# Homebrew only loads formulae from third-party taps you trust
brew tap hashicorp/tap && brew trust hashicorp/tap
brew tap frbarbre/orca https://github.com/frbarbre/orca && brew trust frbarbre/orca
brew tap mutagen-io/mutagen && brew trust mutagen-io/mutagen
brew tap frbarbre/dockanchor https://github.com/frbarbre/dockanchor && brew trust frbarbre/dockanchor

# Keep going if one app fails (e.g. App Store not signed in yet); re-run to retry
brew bundle --file="$DOT/Brewfile" || echo "!! Some Brewfile entries failed, see above"
"$DOT/extras.sh" || echo "!! Some extra apps failed, see above"
"$DOT/link.sh"
eval "$(/opt/homebrew/bin/brew shellenv)"
mise install --yes
"$DOT/macos.sh"

# Claude Code's native installer, not the Homebrew cask: it updates itself, the cask lags a week
[ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
# rbackend's file syncs resume after a reboot only if the daemon starts at login
mutagen daemon register || true

for m in warpdotdev/claude-code-warp DietrichGebert/ponytail bradautomates/claude-video; do
  claude plugin marketplace add "$m" || true
done
for p in warp@claude-code-warp watch@claude-video mattpocock-skills@claude-plugins-official; do
  claude plugin install "$p" || true
done

# Tailscale (runs as a system daemon)
sudo brew services start tailscale

echo
echo "Sign in to Bitwarden once to restore GitHub, Linear, Tailscale, Raycast and Orca."
"$DOT/secrets.sh" restore || echo "!! Some restores failed; re-run ~/.dotfiles/secrets.sh restore"

echo
echo "Done. Remaining manual steps:"
echo "  1. Bitwarden app: sign in and enable its SSH agent"
echo "  2. Dia: sign in and turn on profile sync (brings back extensions, incl. Bitwarden)"
echo "  3. Sign in to your other apps (Slack, Linear, Beeper, Claude, ChatGPT, Figma, Spotify, Raycast, ...)"
echo "  4. Grant accessibility/input permissions (OpenLogi, Wispr Flow, Raycast, Hyperkey, DockAnchor)"
echo "  5. Sharing settings (already open): turn on Screen Sharing for vnc://<this Mac> over Tailscale"
