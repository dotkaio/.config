#export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
#export PATH="$PATH:$JAVA_HOME/bin"

export CHROME_EXECUTABLE="/Applications/Chromium.app/Contents/MacOS/Chromium"
export HOMEBREW_NO_ENV_HINTS=1          # Disable Homebrew's "please do not report this issue to Homebrew/cask/*" message
export HOMEBREW_CASK_OPTS=--require-sha # Require SHA checksums for Casks
export HOMEBREW_NO_ANALYTICS=1          # Disable Homebrew's analytics
export HOMEBREW_NO_AUTO_UPDATE=0        # Disable Homebrew's automatic update
export HOMEBREW_NO_INSECURE_REDIRECT=1  # Disable Homebrew's insecure redirect warning
export HOMEBREW_NO_INSTALL_CLEANUP=0    # Disable Homebrew's cleanup of outdated versions
export HOMEBREW_NO_INSTzALL_UPGRADE=0   # Disable Homebrew's upgrade of already installed formulae

export PATH=$GEM_HOME/bin:$PATH
export NVM_DIR="$HOME/.nvm"