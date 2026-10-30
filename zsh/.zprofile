eval "$(/opt/homebrew/bin/brew shellenv)"

# Use Bitwarden's SSH agent (enable it in Bitwarden > Settings > SSH agent)
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
