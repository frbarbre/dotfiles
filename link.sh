#!/usr/bin/env bash
# Symlink config files from the repo into place. Safe to re-run.
set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"
# Outside the linked folders: a backup inside ~/.claude/skills gets loaded as a second skill.
BACKUP="$HOME/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$DOT/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BACKUP/$(dirname "${dst#$HOME/}")"
    mv "$dst" "$BACKUP/${dst#$HOME/}"
    echo "backed up $dst to $BACKUP"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst"
}

link zsh/.zprofile          "$HOME/.zprofile"
link zsh/.zshrc             "$HOME/.zshrc"
link git/.gitconfig         "$HOME/.gitconfig"
link git/ignore             "$HOME/.config/git/ignore"
link starship/starship.toml "$HOME/.config/starship.toml"
link ghostty/config         "$HOME/.config/ghostty/config"
link mise/config.toml       "$HOME/.config/mise/config.toml"
link warp/settings.toml     "$HOME/.warp/settings.toml"
link openlogi/config.toml   "$HOME/.config/openlogi/config.toml"
link claude/settings.json   "$HOME/.claude/settings.json"
link claude/CLAUDE.md       "$HOME/.claude/CLAUDE.md"
link claude/keybindings.json "$HOME/.claude/keybindings.json"
link claude/rules           "$HOME/.claude/rules"
link linear/orca-open-issue.sh "$HOME/.linear/orca-open-issue.sh"
link linear/coding-tools.json  "$HOME/.linear/coding-tools.json"
# Per skill, since Orca and claude.ai sync also write into ~/.claude/skills
for skill in "$DOT"/claude/skills/*/; do
  link "claude/skills/$(basename "$skill")" "$HOME/.claude/skills/$(basename "$skill")"
done
