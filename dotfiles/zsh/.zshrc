# Ask whether to start tmux if not already inside one
if [ -z "$TMUX" ]; then
  read -q "REPLY?Start tmux session? [y/N]: "
  echo ""
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    tmux attach || exec tmux new-session
    exit
  fi
fi

# Path setup
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
export EDITOR="nvim"

ZSH_THEME="rose-pine"
plugins=(
  git
  fzf
  tmux
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-vi-mode
  alias-tips
  cd-ls
  zsh-git-fzf
  fzf-alias
  aliases
  command-not-found
  copyfile
  copypath
  cp
  extract
  fancy-ctrl-z
  history
  last-working-dir
  nmap
  per-directory-history
  perms
  python
  rsync
  safe-paste
  sudo
  tldr
  urltools
  web-search
  zsh-interactive-cd
  zsh-navigation-tools
)

source "$ZSH/oh-my-zsh.sh"
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

[[ -f "${HOME}/.aliases" ]] && source "${HOME}/.aliases"
[[ -f "${HOME}/.ctf.aliases" ]] && source "${HOME}/.ctf.aliases"

if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/rose-pine.sh" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/rose-pine.sh"
fi

for f in /usr/share/fzf/key-bindings.zsh /usr/share/fzf/completion.zsh "$HOME/.fzf-extras/fzf-extras.zsh"; do
  [[ -e $f ]] && source $f
done

export MANPAGER="sh -c 'col -bx | bat -l man -p'"
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi
