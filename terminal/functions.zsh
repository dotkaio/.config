function to_number {
    tr 'AaEeIiOoSsTt' '443300551177'
}

function dmg2iso {
    if [[ -z $1 || -z $2 ]]; then
        echo "Usage: dmg2iso <input.dmg> <output.iso>"
        return 1
    fi
    hdiutil convert "$1" -format UDTO -o "$2"
    mv "$2.cdr" "$2.iso"
}

function zshrc {
    if command -v code >/dev/null; then
        if [[ -n $1 ]]; then
            code "$TERMINAL/$1"
        else
            code "$HOME/.config"
        fi
    else
        if [[ -n $1 ]]; then
            open -a TextEdit "$HOME/.config/terminal/$1"
        else
            echo "missing argument"
        fi
    fi
}

function xcode {
    if [[ -e $1 ]]; then
        open -a Xcode "$1"
    else
        open -a Xcode
    fi
}

function replace {
    if [[ -z $1 || -z $2 || -z $3 ]]; then
        echo "Usage: replace <file> <old_string> <new_string>"
        return 1
    fi
    sed -i '' "s/$2/$3/g" "$1"
}

function push {
    git add .
    # add a comment to the commit based on the command line arguments

    if [[ -n $1 ]]; then
        git commit -m "$*"
    else
        git commit -m "update"
    fi

    git push
}

function t {
    if command -v tree >/dev/null; then
        tree --sort=name -LlaC 1 "$1"
    else
        l "$1"
    fi
}

function l {
    if command -v tree >/dev/null; then
        tree --dirsfirst --sort=name -LlaC 1 "$1"
    else
        ls -Glap "$1"
    fi
}

function block {
    sudo santactl rule --silent-block --path "$@"
}

function unblock {
    sudo santactl rule --remove --path "$@"
}

function unblockall {
    sudo santactl rule --remove --path /System/Applications/Messages.app
    sudo santactl rule --remove --path /System/Applications/FaceTime.app
    sudo santactl rule --remove --path /System/Applications/Mail.app
    sudo santactl rule --remove --path /System/Applications/System\ Settings.app
    sudo santactl rule --remove --path /Applications/Chromium.app
}

function proxy {
    WHERE=$(pwd)
    echo "https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/socks5.txt \
    https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/socks4.txt \
    https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/http.txt" | xargs -n 1 -P 5 curl -O
    mv socks5.txt socks4.txt http.txt "$CONFIG/proxy"
    cd "$WHERE"
}

function install {
    if [[ $1 == 'brew' ]]; then
        if [[ $2 == 'local' ]]; then
            cd "$CONFIG"
            mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
            cd "$HOME"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    else
        brew install "$@"
    fi
}

function reinstall {
    brew reinstall "$@"
}

function wifi {
    case "$1" in
    down | off) sudo ifconfig en0 down ;;
    up | on) sudo ifconfig en0 up ;;
    name) networksetup -getairportnetwork en0 | awk '{print $4}' ;;
    *) echo "Usage: wifi <down|off|up|on|name>" ;;
    esac
}

function finder {
    /usr/bin/mdfind "$@" 2> >(grep --invert-match ' \[UserQueryParser\] ' >&2) | grep -i "$@" --color=auto
}

function plist {
    function get_plist {
        for the_path in $(mdfind -name LaunchDaemons -name LaunchAgents); do
            for the_file in $(ls -1 "$the_path"); do
                echo "$the_path/$the_file"
            done
        done
    }

    function get_shasum {
        for i in $(get_plist); do
            shasum -a 256 "$i"
        done
    }

    case "$1" in
    get)
        [[ -f $CONFIG/plist_shasum.txt ]] && rm "$CONFIG/plist_shasum.txt"
        get_shasum >"$CONFIG/plist_shasum.txt"
        ;;
    verify)
        colordiff <(get_shasum) <(cat "$CONFIG/plist_shasum.txt")
        ;;
    *)
        get_shasum
        ;;
    esac
}

function remove {
    if [[ $1 == 'brew' ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        if [[ -d "$CONFIG/homebrew" ]]; then
            brew cleanup
            rm -rf "$CONFIG/homebrew"
        elif [[ -d "/opt/homebrew" ]]; then
            brew cleanup
            rm -rf /opt/homebrew
        fi
    else
        brew uninstall "$@"
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
        hdiutil create "$2.dmg" -encryption -size "$3" -volname "$2" -fs JHFS+
    else
        hdiutil create "$1.dmg" -size "$2" -volname "$1" -fs JHFS+
    fi
}

function update {
    brew update &&
        brew upgrade &&
        brew cleanup &&
        brew autoremove
}

function info {
    brew info "$@"
}

function list {
    brew list
}

function search {
    if [[ $1 == "web" ]]; then
        open -a Safari "https://google.com/search?q=$2" &
        open -a Chrome "https://google.com/search?q=$2" &
    else
        brew search "$@"
    fi
}

function icloud {
    cd ~/Library/Mobile\ Documents/com\~apple\~CloudDocs
}

function clone {
    if [[ ! -d "$HOME/Developer" ]]; then
        mkdir -p "$HOME/Developer"
    fi
    cd "$HOME/Developer"
    if [[ $1 =~ ^https?:// ]]; then
        git clone "$1"
        echo "$@" | cut -d '/' -f 5 | pbcopy
        cd "$(pbpaste)"
        echo "done!"
    else
        git clone "https://github.com/$@"
        echo "$@" | cut -d '/' -f 2 | pbcopy
    fi
}

function intel {
    exec arch -x86_64 "$SHELL"
}

function arm64 {
    exec arch -arm64 "$SHELL"
}

function grep_line {
    grep -n "$1" "$2"
}

function get_ip {
    dig +short "$1"
}

function dump {
    case "$1" in
    arp) sudo tcpdump $NETWORK -w arp-$NOW.pcap "ether proto 0x0806" ;;
    icmp) sudo tcpdump -ni $NETWORK -w icmp-$NOW.pcap "icmp" ;;
    pflog) sudo tcpdump -ni pflog0 -w pflog-$NOW.pcap "not icmp6 and not host ff02::16 and not host ff02::d" ;;
    syn) sudo tcpdump -ni $NETWORK -w syn-$NOW.pcap "tcp[13] & 2 != 0" ;;
    udp) sudo tcpdump -ni $NETWORK -w udp-$NOW.pcap "udp and not port 443" ;;
    *) sudo tcpdump ;;
    esac
}

function ip {
    curl -sq4 "https://icanhazip.com/"
}

function history {
    case "$1" in
    top)
        history 1 | awk '{CMD[$2]++;count++;}END {
                for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | column -c3 -s " " -t | sort -nr |
            nl | head -n25
        ;;
    clear | clean)
        awk '!a[$0]++' "$HISTFILE" >"$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"
        ;;
    esac
}

function rand {
    function newUser {
        openssl rand -base64 64 | tr -d "=+/1-9" | cut -c-20 | head -1 | lower | pbcopy
        echo "$(pbpaste)"
    }
    function newPass {
        openssl rand -base64 300 | tr -d "=+/" | cut -c12-20 | tr '\n' '-' | cut -b -26 | pbcopy
        echo "$(pbpaste)"
    }
    function changeId {
        computerName="$(newUser)"
        hostName="$(newUser).local"
        localHostName="$(newUser)_machine"

        sudo scutil --set ComputerName "$computerName"
        sudo scutil --set HostName "$hostName"
        sudo scutil --set LocalHostName "$localHostName"
        sudo dscacheutil -flushcache
        sudo macchanger -r en0
        networksetup -setairportnetwork en2 DG_link_5GHz Dg_Serrano2016
    }
    case "$1" in
    user) newUser ;;
    pass) newPass ;;
    mac) changeId ;;
    line)
        awk 'BEGIN{srand();}{if (rand() <= 1.0/NR) {x=$0}}END{print x}' "$2" | pbcopy
        echo "$(pbpaste)"
        ;;
    esac
}

function battery {
    pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';'
}

function pf {
    case "$1" in
    up) sudo pfctl -e -f "$CONFIG/firewall/pf.rules" ;;
    down) sudo pfctl -d ;;
    status) sudo pfctl -s info ;;
    reload) sudo pfctl -f /etc/pf.conf ;;
    log) sudo pfctl -s nat ;;
    flush) sudo pfctl -F all -f /etc/pf.conf ;;
    show) sudo pfctl -s rules ;;
    *) sudo pfctl ;;
    esac
}

function branch_name {
    git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/(\1) /p'
}

function len {
    echo -n "$1" | wc -c
}

function path {
    if [[ -d $1 ]]; then
        export PATH="$1:$PATH"
    fi
}

function venv {
    conda create -n "$1" python=3.10
    conda activate "$1"
}

function tts {
    curl --request POST --url https://api.fish.audio/model \
        --header 'Authorization: Bearer aca83cec37dc437c8d37a761c098c80a' \
        --header 'Content-Type: multipart/form-data' \
        --form visibility=private \
        --form type=tts \
        --form title=bsdiufhsiduhf \
        --form description=hjasdbfksjgndhm \
        --form "train_mode=fast" \
        --form voices=voice1.mp3,voice2.mp3 \
        --form 'texts="lorem ipsum dolor amet"' \
        --form 'tags="asdfsgdf"' \
        --form enhance_audio_quality=false
}

function extract {
    case "$1" in
    zip) unzip "$2" ;;
    tar) tar -xvf "$2" ;;
    tar.gz) tar -xzvf "$2" ;;
    tar.bz2) tar -xjvf "$2" ;;
    tar.xz) tar -xJvf "$2" ;;
    rar) unrar x "$2" ;;
    7z) 7z x "$2" ;;
    *) echo "Usage: extract <zip|tar|tar.gz|tar.bz2|tar.xz|rar|7z> <file>" ;;
    esac
}

function yt {
    WHERE=$(pwd)
    cd /tmp &&
        yt-dlp --restrict-filenames --no-overwrites --no-call-home --force-ipv4 --no-part "$1" &&
        mv *.mp4 "$HOME/Movies/TV/Movies/Action"
    echo "done"
    cd "$WHERE"
}

function td {
    mkdir -p "$(date +%m-%d%Y)"
}

function chunk {
    local file="$1"
    local custom_chunk_size="$2"

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    local total_lines=$(wc -l <"$file")
    local chunk_size=${custom_chunk_size:-$(echo "scale=0; sqrt($total_lines) + 0.5" | bc | awk '{print int($1)}')}
    local dir=$(dirname "$file")
    local base=$(basename "$file")

    split -l "$chunk_size" "$file" "$dir/${base}_"

    echo "File has been split into chunks of approximately $chunk_size lines each, named as ${base}_1, ${base}_2, etc., in the same directory."
}

function rmip {
    local INPUT_FILE="$1"
    local OUTPUT_FILE="$2"

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Error: Input file does not exist."
        return 1
    fi

    sed -E 's/\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/[REDACTED]/g' "$INPUT_FILE" >"$OUTPUT_FILE"
    echo "done!"
}

function conda {
    if command -v conda >/dev/null; then
        if [[ $1 == "init" ]]; then
            __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
            if [[ $? -eq 0 ]]; then
                eval "$__conda_setup"
            else
                if [[ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]]; then
                    . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
                else
                    export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
                fi
            fi
            unset __conda_setup
        else
            conda "$@"
        fi
    fi
}
