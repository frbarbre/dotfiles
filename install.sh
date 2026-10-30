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

# Keep going if one app fails (e.g. App Store not signed in yet); re-run to retry
brew bundle --file="$DOT/Brewfile" || echo "!! Some Brewfile entries failed, see above"
"$DOT/extras.sh" || echo "!! Some extra apps failed, see above"
"$DOT/link.sh"
eval "$(/opt/homebrew/bin/brew shellenv)"
mise install --yes
"$DOT/macos.sh"

# Tailscale (runs as a system daemon)
sudo brew services start tailscale
echo
echo "Done. Remaining manual steps:"
echo "  1. sudo tailscale up --ssh"
echo "  2. Sign in to Bitwarden and enable its SSH agent"
echo "  3. Sign in to your apps (Dia, Slack, Linear, Beeper, Claude, ChatGPT, Figma, Spotify, Raycast, ...)"
echo "  4. Grant accessibility/input permissions (OpenLogi, Wispr Flow, Raycast, Rectangle, Hyperkey)"
echo "  5. Raycast: import your .rayconfig export (Settings > Advanced > Import)"
