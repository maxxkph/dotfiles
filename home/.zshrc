# Managed by ~/dotfiles — stowed to ~/.zshrc by `dot link`.

# ~/.local/bin for user-installed scripts. Kept ahead of the Homebrew paths so
# something dropped in here wins.
export PATH="$HOME/.local/bin:$PATH"

alias ca="cursor-agent"

# Prompt — starship is in packages/Brewfile.
command -v starship >/dev/null && eval "$(starship init zsh)"
