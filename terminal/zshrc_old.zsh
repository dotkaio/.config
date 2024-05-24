#!/bin/zsh

#https://github.com/dotkaio/.config/blob/main/zshrc.sh
#umask 077

autoload -U colors && colors    # Enable colors in prompt
autoload -Uz compinit           # Load the completion system (compsys)
autoload -Uz vcs_info           # Load version control information
autoload -Uz promptinit         # Load the prompt theme system
autoload -Uz history-search-end # Load history search
autoload -Uz zmv                # Load zmv
autoload -Uz zcalc              # Load zcalc
autoload -Uz zargs              # Load zargs
autoload -Uz zmv                # Load zmv
autoload -Uz zcalc              # command line calculator
autoload -Uz zargs              # zargs command line argument parser
autoload -Uz find-command

#completions
zstyle ':completion:*' menu select
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s #
zstyle ":completion:*" ignore-parents parent pwd
zstyle ":completion:*" auto-description "specify %d"
zstyle ":completion:*" file-sort modification reverse
zstyle ":completion:*" format "completing %d"
zstyle ":completion:*" group-name ""
zstyle ":completion:*" list-colors "=(#b) #([0-9]#)*=36=31"
zstyle ":completion:*" menu select=long-list select=1
zstyle ":completion:*" verbose yes
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' completer _complete _ignored _approximate
zstyle ':completion:*' expand 'yes'
# zstyle vsc info is the same as git info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr "!"
zstyle ':vcs_info:*' unstagedstr "?"
zstyle ':vcs_info:*' formats "%F{green}%b%f %F{cyan}%m%f %F{red}%u%f %F{yellow}%c%f"

compinit
compdef '_tcpdump' dump
compdef '_brew uninstall' uninstall
compdef '_brew install' install
compdef '_brew search' search
compdef '_brew update' update
compdef '_brew list' list
compdef '_youtube-dl' yt
compdef '_flutter' fl
compdef '_tree' t
compdef '_mdfind' finder

#SETOPT
setopt AUTOCD
setopt NOBEEP
setopt CORRECT
setopt ALWAYSTOEND
setopt PROMPT_SUBST
setopt COMPLETEINWORD
# setopt NOCLOBBER        # don't overwrite existing files with >, >>, etc.
# setopt NULLGLOB       # If a glob matches no files, don't treat it as a literal string
# setopt HIST_EXPIRE_DUPS_FIRST # delete duplicates first when HISTSIZE is exceeded
# setopt HISTREDUCEBLANKS   # remove superfluous blanks before recording entry
# setopt HIST_IGNORE_DUPS # ignore duplication command history list
# setopt HIST_IGNORE_ALL_DUPS # ignore duplicate commands history list
# setopt HIST_FIND_NO_DUPS  # do not display a line previously found
# setopt hist_ignore_space  # ignore commands that start with spaces
# setopt extendedglob       # enable extended globbing
# setopt extendedhistory    # save timestamp of command in history
# setopt histignorealldups  # ignore all duplicates when saving history
# setopt histignorespace    # ignore commands that start with spaces
# setopt autopushd          # pushd when changing directory
# setopt pushdignoredups    # ignore duplicates when pushing directories onto the directory stack
# setopt pushdsilent        # don't print the directory stack after pushd or popd
# setopt pushdtohome        # pushd and popd will use $HOME instead of $PWD
# setopt pushdminus         # pushd and popd will swap the top two entries on the directory stack
# setopt pushdignoredups    # ignore duplicates when pushing directories onto the directory stack
# setopt pushdminus

#VARIABLES
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTFILE="$CONFIG/.histfile"
GITHUB_USER="dotkaio"
TODAY="$(date +%m-%d-%Y)"
NOW="$(date +%F-%H:%M:%S)"
REACT_DIR="$HOME/Developer/React"
PYTHON_DIR="$HOME/Developer/Python"
# ZDOTDIR="$HOME/.config"

#ALIAS
alias lines="wc -l"
alias pub="flutter pub"
alias md="mkdir -p"
alias diff="colordiff"
alias flpg="flutter pub get"
alias flpgb="flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs"
alias python="python3"
alias unwrap="tput rmam"
alias wrap="tput smam"
alias json="json_pp"
alias today="date +%m-%d-%Y|pbcopy"
alias time="date -u +%T"
alias fl="flutter"
#alias yt="youtube-dl --restrict-filenames --no-overwrites --write-info-json --write-thumbnail --no-call-home --force-ipv4 --format 'best[height<=720]'"
#alias yt_max="youtube-dl --restrict-filenames --no-overwrites --write-info-json --write-thumbnail --no-call-home --force-ipv4"
# alias push="git push"
alias pull="git pull"
alias status="git status"
alias commit="git commit -m"
alias add="git add"
alias c="clear"
alias z="source $HOME/.zshrc"
alias ll="ls -lhAGF1"
alias rm="rm -drf"
alias grep="grep --text --color"
alias td="mkdir $TODAY ; cd $TODAY"
alias sha="shasum -a 256"
alias hide="chflags hidden $@"
alias md="mkdir -p"
alias pbc="pbcopy"
alias pbp="pbpaste"
alias pc="pbcopy"
alias pp="pbpaste"
alias copy="pbcopy"
alias paste="pbpaste"
alias santa="santactl"
alias 700="chmod 700"
alias 000="chmod 000"
alias 755="chmod 755"
alias doctor="brew doctor"
alias web="open -a Safari"
alias speed="unwrap && networkQuality && wrap"
alias pyvenv="pyenv"

alias .="open ."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

function clear {
    if [ -d "lib" && -d "ios" && -d "android" ]; then
        echo "directory \"lib\" exists"
    fi

}

function to_number {
    echo "$1" | tr 'Aa' '4' | tr 'Ee' '3' | tr 'Ii' '1' | tr 'Oo' '0' | tr 'Ss' '5' | tr 'Tt' '7'
}

function dmg2iso {
    hdiutil convert $1 -format UDTO -o $2
    mv $2.cdr $2.iso
}

function zshrc {
    if command -v code >/dev/null; then
        code $HOME/.config/zshrc
    else
        open -a TextEdit $HOME/.config/zshrc
    fi
}

function xcode {
    if [[ -e $1 ]]; then
        open -a Xcode $1
    else
        open -a Xcode
    fi
}

function replace {
    if [[ -z $1 || -z $2 || -z $3 ]]; then
        echo "Usage: replace <file> <old_string> <new_string>"
        return 1
    fi
    sed -i '' "s/$2/$3/g" $1
}

function push {
    git add .
    git commit -m $@
    git push
}

function t {
    if command -v tree >/dev/null; then
        # if command -v brew >/dev/null; then
        #     install brew
        # fi
        tree --sort=name -LlaC 1 $1
        # tree --dirsfirst --sort=name -LlaC 1 $1
    else
        l $1
    fi
}

function l {
    if command -v tree >/dev/null; then
        tree --dirsfirst --sort=name -LlaC 1 $1
    else
        ls -Glap $1
    fi
}

function block {
    sudo santactl rule --silent-block --path $@
}

function unblock {
    sudo santactl rule --remove --path $@
}

function blockall {
    sudo santactl rule --silent-block --path /System/Applications/Messages.app
    sudo santactl rule --silent-block --path /System/Applications/FaceTime.app
    sudo santactl rule --silent-block --path /System/Applications/Mail.app
    sudo santactl rule --silent-block --path /System/Applications/System\ Settings.app
    sudo santactl rule --silent-block --path /Applications/Chromium.app
}

function unblockall {
    sudo santactl rule --remove --path /System/Applications/Messages.app
    sudo santactl rule --remove --path /System/Applications/FaceTime.app
    sudo santactl rule --remove --path /System/Applications/Mail.app
    sudo santactl rule --remove --path /System/Applications/System\ Settings.app
    sudo santactl rule --remove --path /Applications/Chromium.app
}

function proxy {
    if [[ -e $CONFIG/proxy_list.txt ]]; then
        rm -rf $CONFIG/proxy_list.txt
    fi
    curl -sSf "https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt" \
        >$CONFIG/proxy_list.txt
}

function install {
    if [[ $1 == 'brew' ]]; then
        if [[ $2 == 'local' ]]; then
            cd $CONFIG
            mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C Homebrew
            Homebrew/bin/brew update && Homebrew/bin/brew upgrade
            cd $HOME
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew -v update && brew -v upgrade
        fi
    else
        brew -v install $@
    fi
}

function reinstall {
    brew -v reinstall $@
}

function wifi {
    if [[ $1 == "down" || "off" ]]; then
        sudo ifconfig en0 down
    elif [[ $1 == "up" || "on" ]]; then
        sudo ifconfig en0 up
    elif [[ $1 == "name" ]]; then
        networksetup -getairportnetwork en0 | awk '{print $4}'
    else
        echo "You haven't included any arguments"
    fi
}

function finder {
    /usr/bin/mdfind $@ 2> >(grep --invert-match ' \[UserQueryParser\] ' >&2) | grep $@ --color=auto
}

function plist {
    # CONFIG = $HOME/.config
    function get_plist {
        for the_path in $(
            mdfind -name LaunchDaemons
            mdfind -name LaunchAgents
        ); do
            for the_file in $(ls -1 $the_path); do
                echo $the_path/$the_file
            done
        done
    }

    function get_shasum {
        for i in $(get_plist); do
            shasum -a 256 $i
        done
    }

    if [[ $1 == "get" ]]; then
        if [[ -f $CONFIG/plist_shasum.txt ]]; then
            rm $CONFIG/plist_shasum.txt
        fi
        get_shasum >$CONFIG/plist_shasum.txt
    elif [[ $1 == "verify" ]]; then
        colordiff <(get_shasum) <(cat $CONFIG/plist_shasum.txt)
    else
        get_shasum
    fi
}

function remove {
    if [[ $1 == 'brew' ]]; then
        /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        if [[ -d $CONFIG/homebrew" ]]; then
			brew -v cleanup
			rm -rf $CONFIG/homebrew
		elif [[ -d /opt/homebrew" ]]; then
            brew -v cleanup
            rm -rf /opt/homebrew
        fi
    else
        brew -v uninstall $@
    fi
}

function generate_ip {
    for a in {1..254}; do
        echo "$a.1.1.1"
        for b in {1..254}; do
            echo "$a.$b.1.1"
            for c in {1..254}; do
                echo "$a.$b.$c.1"
                for d in {1..254}; do
                    echo "$a.$b.$c.$d"
                done
            done
        done
    done
}

function dmg {
    if [[ $1 == "crypt" ]]; then
        hdiutil create $2.dmg -encryption -size $3 -volname $2 -fs JHFS+
    else
        hdiutil create $1.dmg -size $2 -volname $1 -fs JHFS+
    fi
}

function update {
    brew update
    brew upgrade
    brew cleanup
    brew autoremove

}

function info {
    brew info $@
}

function list {
    brew list
}

function search {
    brew search $@
}

function pyenv {
    # if [[ -d $HOME ]]; then
    # 	cd $
    # fi
    python3 -m venv $1
    cd $1
    source bin/activate
    pip install --upgrade pip
    # if [[ -f "requirements.txt" ]]; then
    # pip install -r requirements.txt
    # fi
}

function cloud {
    cd ~/Library/Mobile\ Documents/com\~apple\~CloudDocs
}

function clone {
    if [[ $1 =~ ^https?:// ]]; then
        git clone $1
        echo "$@" | cut -d '/' -f 5 | pbc
        cd $(pbp)
        t
    else
        git clone https://github.com/$@
        echo "$@" | cut -d '/' -f 2 | pbc
        cd $(pbp)
        t
    fi

}

function intel {
    exec arch -x86_64 $SHELL
}

function arm64 {
    exec arch -arm64 $SHELL
}

function grep_line {
    grep -n $1 $2
}

function get_ip {
    dig +short $1
}

function dump {
    if [[ $1 == "arp" ]]; then
        sudo tcpdump $NETWORK -w arp-$NOW.pcap "ether proto 0x0806"
    elif [[ $1 == "icmp" ]]; then
        sudo tcpdump -ni $NETWORK -w icmp-$NOW.pcap "icmp"
    elif [[ $1 == "pflog" ]]; then
        sudo tcpdump -ni pflog0 -w pflog-$NOW.pcap "not icmp6 and not host ff02::16 and not host ff02::d"
    elif [[ $1 == "syn" ]]; then
        sudo tcpdump -ni $NETWORK -w syn-$NOW.pcap "tcp[13] & 2 != 0"
    elif [[ $1 == "upd" ]]; then
        sudo tcpdump -ni $NETWORK -w udp-$NOW.pcap "udp and not port 443"
    else
        sudo tcpdump
    fi
}

function ip {
    curl -sq4 "https://icanhazip.com/"
}

function history {
    if [[ $1 == "top" ]]; then
        history 1 | awk '{CMD[$2]++;count++;}END {
		for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | column -c3 -s " " -t | sort -nr |
            nl | head -n25
    elif [[ $1 == "clear" || "clean" ]]; then
        awk '!a[$0]++' $HOME/.histfile >$HOME/.histfile.tmp && mv $HOME/.histfile.tmp $HOME/.histfile
    fi
}

function rand {
    if [[ $1 == "user" ]]; then
        openssl rand -base64 64 | tr -d "=+/1-9" | cut -c-16 | head -1 | pc
        pp
    elif [[ $1 == "pass" ]]; then
        openssl rand -base64 300 | tr -d "=+/" | cut -c12-20 | tr '\n' '-' | cut -b -26 | pbc
        pp
    elif [[ $1 == "line" ]]; then
        awk 'BEGIN{srand();}{if (rand() <= 1.0/NR) {x=$0}}END{print x}' $2
    elif [[ $1 == "mac" ]]; then
        macchanger -r en0
    elif [[ $1 == "id" ]]; then
        computerName="Nexus5"
        hostName="Android"
        localHostName="MobileAndroid"
        sudo scutil --set ComputerName "$computerName"
        sudo scutil --set HostName "$hostName"
        sudo scutil --set LocalHostName "$localHostName"
        sudo dscacheutil -flushcache
    else
        echo "user: $(openssl rand -base64 64 | tr -d "=+/1-9" | cut -c-16 | head -1 | lower)"
        echo "pswd: $(openssl rand -base64 300 | tr -d "=+/" | cut -c12-20 | tr '\n' '-' | cut -b -26)"

    fi
}
c
function bat {
    pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';'
}

function pf {
    if [[ $1 == "up" ]]; then
        sudo pfctl -e -f $CONFIG/pf/pf.conf
    elif [[ $1 == "down" ]]; then
        sudo pfctl -d
    elif [[ $1 == "status" ]]; then
        sudo pfctl -s info
    elif [[ $1 == "reload" ]]; then
        sudo pfctl -f /etc/pf.conf
    elif [[ $1 == "log" ]]; then
        sudo pfctl -s nat
    elif [[ $1 == "flush" ]]; then
        sudo pfctl -F all -f /etc/pf.conf
    elif [[ $1 == "show" ]]; then
        sudo pfctl -s rules
    else
        sudo pfctl
    fi
}

function branch_name {
    git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/(\1) /p'
}

function len {
    echo -n $1 | wc -c
}

#PATHS
function path {
    if [[ -d $1 ]]; then
        export PATH="$1 :$PATH"
    fi
}

path /bin
path /sbin
path /usr/bin
path /usr/sbin
path /usr/local/bin
path /usr/local/sbin
# path /opt/homebrew/bin

export CHROME_EXECUTABLE="/Applications/Chromium.app/Contents/MacOS/Chromium"

export PATH=$GEM_HOME/bin:$PATH
export PATH="/usr/local/opt/ruby/bin:$PATH"
#export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
#export PATH="$PATH:$JAVA_HOME/bin"

export HOMEBREW_NO_ENV_HINTS=1          # Disable Homebrew's "please do not report this issue to Homebrew/cask/*" message
export HOMEBREW_CASK_OPTS=--require-sha # Require SHA checksums for Casks
export HOMEBREW_NO_ANALYTICS=1          # Disable Homebrew's analytics
export HOMEBREW_NO_AUTO_UPDATE=0        # Disable Homebrew's automatic update
export HOMEBREW_NO_INSECURE_REDIRECT=1  # Disable Homebrew's insecure redirect warning
export HOMEBREW_NO_INSTALL_CLEANUP=0    # Disable Homebrew's cleanup of outdated versions
export HOMEBREW_NO_INSTzALL_UPGRADE=0   # Disable Homebrew's upgrade of already installed formulae

export NVM_DIR="$HOME/.nvm"

# FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
FPATH=$CONFIG/terminal/completions:$FPATH

source $CONFIG/terminal/autosuggestion/init
source $CONFIG/terminal/highlight/init
# PROMPT
prompt='%F{cyan}%h %F{green}%B%/%F{red}%b $(branch_name)%f
>_ '
