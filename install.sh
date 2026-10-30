#!/usr/bin/env bash
# One-shot setup for a fresh Mac:
#   curl -fsSL https://raw.githubusercontent.com/frbarbre/dotfiles/main/install.sh | bash
set -euo pipefail
REPO="https://github.com/frbarbre/dotfiles.git"
DOT="$HOME/.dotfiles"

# Ask for sudo once up front and keep it alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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

brew bundle --file="$DOT/Brewfile"
"$DOT/link.sh"
"$DOT/macos.sh"

# Tailscale (runs as a system daemon)
sudo brew services start tailscale
echo
echo "Done. Remaining manual steps:"
echo "  1. sudo tailscale up --ssh"
echo "  2. Sign in to Bitwarden and enable its SSH agent"
echo "  3. Sign in to Dia, Warp, Wispr Flow, Claude Code"
echo "  4. Grant OpenLogi and Wispr Flow their accessibility/input permissions"
