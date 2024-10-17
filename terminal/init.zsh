export CONFIG="$HOME/.config"

export TERMINAL="$CONFIG/terminal"

export HISTFILE="$CONFIG/.histfile"
export SAVEHIST=$HISTSIZE

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

# CONDA
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup

rm $HOME/.zcompdump* 2>/dev/null
compinit
