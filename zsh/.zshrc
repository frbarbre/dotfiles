export LC_CTYPE=en_US.UTF-8
export LAUNCH_EDITOR="orca-open"

# Older toolchains still installed on some Macs; guarded so a fresh Mac skips them.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
fi
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
[ -d /Library/Frameworks/Python.framework/Versions/3.14/bin ] && export PATH="/Library/Frameworks/Python.framework/Versions/3.14/bin:$PATH"
if [ -d "$HOME/.proto" ]; then
  export PROTO_HOME="$HOME/.proto"
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi

# After the toolchains above: nvm's global npm bin would otherwise shadow the native claude in ~/.local/bin.
export PATH="$HOME/.dotfiles/bin:$HOME/.local/bin:$PATH"

# Runtimes (node, python, ...) managed by mise; see ~/.config/mise/config.toml
eval "$(mise activate zsh)"

[ -S "$HOME/.orbstack/run/docker.sock" ] && export DOCKER_HOST="unix://$HOME/.orbstack/run/docker.sock"

alias dot='cd ~/.dotfiles'
alias brewup='brew update && brew bundle --file=~/.dotfiles/Brewfile && brew upgrade'
# Claude Code's shell snapshot keeps this alias but drops zoxide's chpwd hook, so z warns on every cd there
[[ -z $CLAUDECODE ]] && alias cd="z"
alias p="pnpm"
alias c="claude"
alias mr="mise run"
alias tsgo="pnpm tsgo --build"
alias open-artemis="open vnc://artemis"
alias sync-models="python3 ~/.config/scripts/update_opencode_models.py"

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

# Build + preview the frontend. The moon build task is cache-aware, so it
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

# Lets Warp warpify subshells (ssh, docker exec) that source this file
[[ "$-" == *i* ]] && printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Darwin" }}\x9c'

eval "$(starship init zsh)"

# zoxide must be initialised last so no later hook overrides its chpwd handling
eval "$(zoxide init zsh)"
