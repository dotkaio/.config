#/bin/zsh
export CONFIG="$HOME/.config"
export HISTFILE="$CONFIG/.histfile"
export SAVEHIST=$HISTSIZE
export GITHUB_USER="dotkaio"
export CHROME_EXECUTABLE=~/Applications/Chromium.app/Contents/MacOS/Chromium

export HOMEBREW_NO_ENV_HINTS=0
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_NO_ANALYTICS=0
export HOMEBREW_NO_AUTO_UPDATE=0
export HOMEBREW_NO_INSECURE_REDIRECT=0
export HOMEBREW_NO_INSTALL_CLEANUP=0
export HOMEBREW_NO_INSTZALL_UPGRADE=1

source $CONFIG/terminal/alias.zsh
source $CONFIG/terminal/suggestion.zsh
source $CONFIG/terminal/setopt.zsh
source $CONFIG/terminal/functions.zsh
source $CONFIG/terminal/paths.zsh
source $CONFIG/terminal/compdef.zsh
source $CONFIG/terminal/autoload.zsh
source $CONFIG/terminal/highlight/init.zsh
source $CONFIG/terminal/zstyle.zsh

FPATH=$CONFIG/terminal/completions:$FPATH

# prompt='%F{cyan}%h %F{redz}% k∆iØ %F{green}%B%~%F{red}%b $(branch_name)%f
# >_ '

prompt='%F{cyan}%h %F{green}%B%~%F{red}%b $(branch_name)%f
→ '

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
