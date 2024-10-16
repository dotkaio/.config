export CONFIG="$HOME/.config"
export HISTFILE="$CONFIG/.histfile"
export SAVEHIST=$HISTSIZE

source $CONFIG/terminal/alias.zsh
source $CONFIG/terminal/suggestion.zsh
source $CONFIG/terminal/setopt.zsh
source $CONFIG/terminal/functions.zsh
source $CONFIG/terminal/paths.zsh
source $CONFIG/terminal/export.zsh
source $CONFIG/terminal/bindkey.zsh
source $CONFIG/terminal/compdef.zsh
source $CONFIG/terminal/autoload.zsh
source $CONFIG/terminal/zstyle.zsh

FPATH=$CONFIG/terminal/completions:$FPATH

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
