$env.EDITOR = "nvim"
$env.SUDO_EDITOR = "nvim"
$env.XDG_STATE_HOME = ($env.HOME | path join ".xdg")
$env.AUTH_WRAPPER_QUIET = "true"
$env.SHELL = $nu.current-exe

$env.config.show_banner = false
$env.config.buffer_editor = "nvim"

# paths 
use std/util "path add"
path add ...[
    ($env.HOME | path join "dotfiles/own_bin/wrappers")
    ($env.HOME | path join "dotfiles/own_bin")
    ($env.HOME | path join "own_bin_cc")
    ($env.HOME | path join "own_bin_cc/wrappers")
    ($env.HOME | path join "hva/scripts")
    ($env.HOME | path join ".cargo/bin")
    ($env.HOME | path join ".local/bin")
    ($env.HOME | path join ".dotnet/tools")
]

# alias
alias sut = sudo
alias lsa = ls -la
alias lg = lazygit
alias nano = nvim
alias vi = nvim
alias vim = nvim
alias n = nvim
alias r = y
alias snvim = sudo -E nvim

def ranger [] {
    print "use yazi instead"
}

# yazi cd exit on q thingy 
def --env --wrapped y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    ^yazi ...$args --cwd-file $tmp

    let cwd = (open $tmp)
    if $cwd != $env.PWD and ($cwd | path exists) {
        cd $cwd
    }

    rm -fp $tmp
}

# local secrets
const secrets_path = ($nu.default-config-dir | path join "secrets.nu")
const secrets_file = if ($secrets_path | path exists) {
    $secrets_path
} else {
    null
}
source-env $secrets_file

# node js land
if (which fnm | is-not-empty) {
    load-env (^fnm env --json --use-on-cd | from json)
    $env.PATH = ($env.PATH | prepend ($env.FNM_MULTISHELL_PATH | path join "bin"))

    $env.config.hooks.env_change.PWD = (
        $env.config.hooks.env_change.PWD?
        | default []
        | append {|before, after|
            if ([.nvmrc .node-version package.json] | any {|file| $file | path exists }) {
                ^fnm use --silent-if-unchanged
            }
        }
    )
}

# startup init
mkdir ($nu.data-dir | path join "vendor/autoload")
^starship init nu | save --force ($nu.data-dir | path join "vendor/autoload/starship.nu")
if $nu.is-interactive {
    fastfetch
}
