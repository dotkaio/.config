CONFIG="$HOME/.config"
TERMINAL="$CONFIG/terminal"

HISTFILE="$HOME/.histfile"
HISTSIZE=10000
SAVEHIST=$HISTSIZE

GITHUB_USER="dotkaio"

source $TERMINAL/alias.zsh
source $TERMINAL/suggestion.zsh
source $TERMINAL/setopt.zsh
source $TERMINAL/functions.zsh
source $TERMINAL/paths.zsh
source $TERMINAL/export.zsh
source $TERMINAL/bindkey.zsh
source $TERMINAL/compdef.zsh
source $TERMINAL/autoload.zsh
source $TERMINAL/highlight/init.zsh
source $TERMINAL/zstyle.zsh

FPATH=$CONFIG/terminal/completions:$FPATH
autoload -Uz compinit
compinit

# prompt='%F{cyan}%h %F{redz}% k∆iØ %F{green}%B%~%F{red}%b $(branch_name)%f
# >_ '

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

prompt='%F{cyan}%h %F{green}%B%~%F{red}%b $(branch_name)%f
→ '
