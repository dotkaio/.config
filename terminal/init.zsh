export CONFIG="$HOME/.config"
export TERMINAL="$CONFIG/terminal"
export HISTFILE="$CONFIG/histfile"
export HISTSIZE=10000
#PATH="$PATH:$JAVA_HOME/bin"
export CHROME_EXECUTABLE=/Applications/Chromium.app/Contents/MacOS/Chromium
export HOMEBREW_NO_ENV_HINTS=           # Disable Homebrew's "please do not report this issue to Homebrew/cask/*" message
export HOMEBREW_CASK_OPTS=--require-sha # Require SHA checksums for Casks
export HOMEBREW_NO_ANALYTICS=           # Disable Homebrew's analytics
export HOMEBREW_NO_AUTO_UPDATE=         # Disable Homebrew's automatic update
export HOMEBREW_NO_INSECURE_REDIRECT=   # Disable Homebrew's insecure redirect warning
export HOMEBREW_NO_INSTALL_CLEANUP=     # Disable Homebrew's cleanup of outdated versions
export PATH=$GEM_HOME/bin:$PATH
export PATH=$GEM_HOME/gems/bin:$PATH

for file in $TERMINAL/*.zsh; do
	source $file
done

rm $HOME/.zcompdump*
autoload -Uz compinit
compinit

FPATH=$TERMINAL/completions:$FPATH

# prompt='%F{cyan}%h %F{redz}% k∆iØ %F{green}%B%~%F{red}%b $(branch_name)%f
# >_ '

GITHUB_USER="dotkaio"

prompt='%F{cyan}%h %F{green}%B%~%F{red}%b $(branch_name)%f
→ '
