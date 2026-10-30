export LC_CTYPE=en_US.UTF-8
export LAUNCH_EDITOR="orca-open"
export PATH="$HOME/.local/bin:$PATH"

# Runtimes (node, python, ...) managed by mise; see ~/.config/mise/config.toml
eval "$(mise activate zsh)"

alias dot='cd ~/.dotfiles'
alias brewup='brew update && brew bundle --file=~/.dotfiles/Brewfile && brew upgrade'
alias cd="z"
alias p="pnpm"
alias c="claude"
alias mr="mise run"
alias tsgo="pnpm tsgo --build"

# Merge the branch's remembered base (default main) into the current branch.
# `gmm <base>` sets and remembers the base.
gmm() {
  local branch base
  branch=$(git symbolic-ref --quiet --short HEAD) || { echo "not on a branch"; return 1; }
  if [ -n "$1" ]; then
    base="$1"
    git config "branch.$branch.base" "$base"
  else
    base=$(git config "branch.$branch.base" 2>/dev/null || echo main)
  fi
  git fetch && git merge "origin/$base"
}

# Build + preview the flowbase frontend. The moon build task is cache-aware, so it
# only rebuilds when sources changed; preview runs under fnox for PREVIEW_PORT etc.
fb-preview() {
  mise run frontend-build && mise exec -- fnox exec -- pnpm --filter frontend preview --strictPort false
}

killport() {
  local pids=$(lsof -ti:"$1")
  if [[ -z $pids ]]; then
    echo "nothing listening on port $1"
    return 1
  fi
  echo $pids | xargs kill -9
  echo "killed $(echo $pids | tr '\n' ' ')on port $1"
}

eval "$(starship init zsh)"

# zoxide must be initialised last so no later hook overrides its chpwd handling
eval "$(zoxide init zsh)"
