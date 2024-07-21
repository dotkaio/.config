CONFIG="$HOME/.config"

HISTFILE="$CONFIG/.histfile"
HISTSIZE=10000
SAVEHIST=$HISTSIZE
GITHUB_USER="dotkaio"

TERMINAL="$CONFIG/terminal"

source $TERMINAL/alias.zsh
source $TERMINAL/suggestion.zsh
source $TERMINAL/setopt.zsh
source $TERMINAL/functions.zsh
source $TERMINAL/paths.zsh
source $TERMINAL/export.zsh
source $TERMINAL/bindkey.zsh
source $TERMINAL/compdef.zsh
source $TERMINAL/autoload.zsh
source $TERMINAL/highlight/init
source $TERMINAL/zstyle.zsh
# source /usr/local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

FPATH=$TERMINAL/completions:$FPATH

eval "$(/opt/homebrew/bin/brew shellenv)"

prompt='%F{cyan}%h %F{green}%B%/%F{red}%b $(branch_name)%f
>_ '
