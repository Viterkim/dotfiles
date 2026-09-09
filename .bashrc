# shellcheck shell=bash

# Environment shared by interactive shells and SSH commands.
export EDITOR=nvim
export SUDO_EDITOR=nvim
export XDG_STATE_HOME="$HOME/.xdg"
export AUTH_WRAPPER_QUIET=true
export SHELL=/usr/bin/bash

if [[ -n ${XDG_RUNTIME_DIR:-} && -S $XDG_RUNTIME_DIR/gcr/ssh ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
fi

path_prepend() {
  local target=$1 path_entry new_path=
  local -a path_entries

  IFS=: read -r -a path_entries <<< "$PATH"
  for path_entry in "${path_entries[@]}"; do
    [[ $path_entry == "$target" ]] && continue
    new_path+="${new_path:+:}$path_entry"
  done

  PATH="$target${new_path:+:$new_path}"
}

# Entries are listed from lowest to highest priority because each is prepended.
for path_entry in \
  "$HOME/.dotnet/tools" \
  "$HOME/.local/bin" \
  "$HOME/.cargo/bin" \
  "$HOME/hva/scripts" \
  "$HOME/own_bin_cc/wrappers" \
  "$HOME/own_bin_cc" \
  "$HOME/dotfiles/own_bin" \
  "$HOME/dotfiles/own_bin/wrappers"
do
  path_prepend "$path_entry"
done
unset path_entry
unset -f path_prepend
export PATH

if [[ -r $HOME/.config/bash/secrets.bash ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.config/bash/secrets.bash"
fi

[[ $- == *i* ]] || return

alias sut='sudo'
alias ls='ls --color=auto'
alias lsa='ls -lha'
alias grep='grep --color=auto'
alias lg='lazygit'
alias nano='nvim'
alias vi='nvim'
alias vim='nvim'
alias n='nvim'
alias snvim='sudo -E nvim'
alias r='y'

ranger() {
  printf '%s\n' 'use yazi instead'
}

# Run Yazi and follow its final working directory when it exits.
y() {
  local cwd_file cwd yazi_status
  cwd_file=$(mktemp -t yazi-cwd.XXXXXX) || return

  command yazi "$@" --cwd-file="$cwd_file"
  yazi_status=$?
  IFS= read -r -d '' cwd < "$cwd_file" || true
  rm -f -- "$cwd_file"

  if [[ -n $cwd && $cwd != "$PWD" && -d $cwd ]]; then
    builtin cd -- "$cwd" || return
  fi

  return "$yazi_status"
}

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend checkwinsize

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  # shellcheck disable=SC1091
  source /usr/share/bash-completion/bash_completion
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell bash)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi
