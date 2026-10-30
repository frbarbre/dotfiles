#!/usr/bin/env bash
# Symlink config files from the repo into place. Safe to re-run.
set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$DOT/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.backup.$(date +%s)"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst"
}

link zsh/.zprofile          "$HOME/.zprofile"
link zsh/.zshrc             "$HOME/.zshrc"
link warp/settings.toml     "$HOME/.warp/settings.toml"
link openlogi/config.toml   "$HOME/.config/openlogi/config.toml"
link claude/settings.json   "$HOME/.claude/settings.json"
link git/.gitconfig          "$HOME/.gitconfig"
