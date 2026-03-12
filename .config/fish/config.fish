function fish_greeting
    fastfetch
end

alias sut='sudo'
alias lsa='ls -lha'
alias lg='lazygit'
alias nano="nvim"
alias vi="nvim"
alias vim="nvim"
alias snvim="sudo -E nvim"
alias docker="sudo docker"
alias lazydocker="sudo lazydocker"

set -gx EDITOR "nvim"
set -gx XDG_STATE_HOME "$HOME/.xdg"
set -gx AUTH_WRAPPER_QUIET "true"
set -gx SUDO_EDITOR nvim

if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

# Path
fish_add_path $HOME/dotfiles/own_bin
fish_add_path $HOME/own_bin_cc
fish_add_path $HOME/.cargo/bin

# Ranger fix
function ranger --wraps ranger --description 'Run ranger and cd on exit'
    set -l tempfile "$HOME/.rangerdir"

    # Run ranger and dump the directory to the tempfile
    command ranger --choosedir=$tempfile $argv

    # Upon exit, read the file and cd
    if test -f $tempfile
        set -l ranger_dir (cat $tempfile)
        cd $ranger_dir
        rm $tempfile
    end
end

# Node
fnm env --use-on-cd | source
starship init fish | source
