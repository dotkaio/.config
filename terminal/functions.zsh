function to_number {
    tr 'Aa' '4' | tr 'Ee' '3' | tr 'Ii' '1' | tr 'Oo' '0' | tr 'Ss' '5' | tr 'Tt' '7'
}

function dmg2iso {
    hdiutil convert $1 -format UDTO -o $2
    mv $2.cdr $2.iso
}

function fibonacci_index {
    if (($1 < 2)); then
        echo "$1"
    else
        echo $(($(fibonacci $(($1 - 1))) + $(fibonacci $(($1 - 2)))))
    fi
}

function zshrc {
    if command -v code >/dev/null; then
        if [[ -n $1 ]]; then
            code $TERMINAL/$1
        else
            code $HOME/.config
        fi
    else
        if [[ -n $1 ]]; then
            open -a TextEdit $HOME/.config/terminal/$1
        else
            echo "missing argument"
        fi
    fi
}

function xcode {
    if [[ -e $1 ]]; then
        /Applications/Xcode.app $1
    else
        /Applications/Xcode.app
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
    facetime = "/System/Applications/FaceTime.app"
    messages = "/System/Applications/Messages.app"
    mail = "/System/Applications/Mail.app"
    system = "/System/Applications/System\ Settings.app"
    chromium = "/Applications/Chromium.app"
    if [[ $@ == $facetime ]]; then
        sudo santactl rule --silent-block --path $facetime
    elif [[ $@ == $messages ]]; then
        sudo santactl rule --silent-block --path $messages
    elif [[ $@ == $mail ]]; then
        sudo santactl rule --silent-block --path $mail
    elif [[ $@ == $system ]]; then
        sudo santactl rule --silent-block --path $system
    elif [[ $@ == $chromium ]]; then
        sudo santactl rule --silent-block --path $chromium
    else
        sudo santactl rule --silent-block --path $@
    fi
}

function unblock {
    sudo santactl rule --remove --path $@
}

function blockall {

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
        rm -rf $CONFIG/proxy_*
    fi
    curl -sSf "https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt" \
        >$CONFIG/proxy_list
}

function install {
    if [[ $1 == 'brew' ]]; then
        if [[ $2 == 'local' ]]; then
            cd $CONFIG
            mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C Homebrew
            # Homebrew/bin/brew update && Homebrew/bin/brew upgrade
            cd $HOME
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # brew -v update && brew -v upgrade
        fi
    else
        brew install $@
    fi
}

function reinstall {
    brew reinstall $@
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
			brew cleanup
			rm -rf $CONFIG/homebrew
		elif [[ -d /opt/homebrew" ]]; then
            brew cleanup
            rm -rf /opt/homebrew
        fi
    else
        brew uninstall $@
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
    if [ -d "$HOME/Developer" ]; then
        cd $HOME/Developer
        if [[ $1 =~ ^https?:// ]]; then
            git clone $1
            echo "$@" | cut -d '/' -f 5 | pbc
        else
            git clone https://github.com/$@
            echo "$@" | cut -d '/' -f 2 | pbc
        fi
    else
        mkdir -p $HOME/Developer
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
    newUser() {
        openssl rand -base64 64 | tr -d "=+/1-9" | cut -c-16 | head -1 | pbcopy
        echo $(pbpaste)
    }
    newPass() {
        openssl rand -base64 300 | tr -d "=+/" | cut -c12-20 | tr '\n' '-' | cut -b -26 | pbcopy
        echo $(pbpaste)
    }

    changeId() {
        #get new variables for names
        computerName="$(newUser)"
        hostName="$(newUser).local"
        localHostName="$(newUser)_machine"

        #
        sudo scutil --set ComputerName "$computerName"
        sudo scutil --set HostName "$hostName"
        sudo scutil --set LocalHostName "$localHostName"

        sudo dscacheutil -flushcache

        sudo macchanger -r en0

        networksetup -setairportnetwork en2 DG_link_5GHz Dg_Serrano2016
    }
    case "$1" in
    "user")
        newUser
        ;;
    "pass")
        newPass
        ;;
    "mac")
        changeId
        ;;
    "line")
        awk 'BEGIN{srand();}{if (rand() <= 1.0/NR) {x=$0}}END{print x}' $2 | pbcopy
        echo "$(pbpaste)"
        ;;
    esac

}

function battery() {
    pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';'
}

function pf {
    if [[ $1 == "up" ]]; then
        sudo pfctl -e -f $CONFIG/firewall/pf.rules
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

function path {
    if [[ -d $1 ]]; then
        export PATH="$1 :$PATH"
    fi
}
