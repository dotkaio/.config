export CONFIG="$HOME/.config"

export TERMINAL="$CONFIG/terminal"

export HISTFILE="$CONFIG/histfile"
export HISTSIZE=10000

source $TERMINAL/alias.zsh
source $TERMINAL/suggestion.zsh
source $TERMINAL/setopt.zsh
source $TERMINAL/functions.zsh
source $TERMINAL/paths.zsh
source $TERMINAL/export.zsh
source $TERMINAL/bindkey.zsh
source $TERMINAL/compdef.zsh
source $TERMINAL/autoload.zsh
source $TERMINAL/zstyle.zsh
source $TERMINAL/highlight/init.zsh

FPATH=$TERMINAL/completions:$FPATH

# prompt='%F{cyan}%h %F{redz}% k∆iØ %F{green}%B%~%F{red}%b $(branch_name)%f
# >_ '

prompt='%F{cyan}%h %F{green}%B%~%F{red}%b $(branch_name)%f
→ '

GITHUB_USER="dotkaio"

conda init "$(basename "${SHELL}")"