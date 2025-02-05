#!/usr/bin/env zsh

# Environment variables
export CONFIG="$HOME/.config"
export TERMINAL="$CONFIG/terminal"

# Prepend a directory to PATH if it exists
path() {
	[[ -d "$1" ]] && export PATH="$1:$PATH"
}

# Add essential paths
for p in /bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin /opt/homebrew/bin "$HOME/.lmstudio/bin"; do
	path "$p"
done

# Functions
to_number() {
	tr 'Aa' '4' | tr 'Ee' '3' | tr 'Ii' '1' | tr 'Oo' '0' | tr 'Ss' '5' | tr 'Tt' '7'
}

dmg2iso() {
	hdiutil convert "$1" -format UDTO -o "$2" && mv "$2.cdr" "$2.iso"
}

zshrc() {
	if command -v code >/dev/null; then
		[[ -n "$1" ]] && code "$TERMINAL/$1" || code "$HOME/.config"
	else
		[[ -n "$1" ]] && open -a TextEdit "$HOME/.config/terminal/$1" || echo "missing argument"
	fi
}

xcode() {
	[[ -e "$1" ]] && open -a Xcode "$1" || open -a Xcode
}

replace() {
	if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
		echo "Usage: replace <file> <old_string> <new_string>"
		return 1
	fi
	sed -i '' "s/$2/$3/g" "$1"
}

push() {
	git add .
	git commit -m "$*"
	git push
}

t() {
	if command -v tree >/dev/null; then
		tree --sort=name -L laC 1 "$1"
	else
		l "$1"
	fi
}

l() {
	if command -v tree >/dev/null; then
		tree --dirsfirst --sort=name -L laC 1 "$1"
	else
		ls -Glap "$1"
	fi
}

block() {
	sudo santactl rule --silent-block --path "$@"
}

unblock() {
	sudo santactl rule --remove --path "$@"
}

unblockall() {
	for app in "Messages.app" "FaceTime.app" "Mail.app" "System Settings.app" "Chromium.app"; do
		if [[ "$app" == "Chromium.app" ]]; then
			sudo santactl rule --remove --path "/Applications/$app"
		else
			sudo santactl rule --remove --path "/System/Applications/$app"
		fi
	done
}

proxy() {
	local current_dir
	current_dir=$(pwd)
	for url in \
		"https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/socks5.txt" \
		"https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/socks4.txt" \
		"https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/http.txt"; do
		curl -O "$url"
	done
	mv socks5.txt socks4.txt http.txt "$CONFIG/proxy"
	cd "$current_dir" || return
}

install() {
	if [[ "$1" == "brew" ]]; then
		if [[ "$2" == "local" ]]; then
			cd "$CONFIG" || return
			mkdir -p homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
			cd "$HOME" || return
		else
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi
	else
		brew install "$@"
	fi
}

reinstall() {
	brew reinstall "$@"
}

wifi() {
	if [[ "$1" == "down" || "$1" == "off" ]]; then
		sudo ifconfig en0 down
	elif [[ "$1" == "up" || "$1" == "on" ]]; then
		sudo ifconfig en0 up
	elif [[ "$1" == "name" ]]; then
		networksetup -getairportnetwork en0 | awk '{print $4}'
	else
		echo "You haven't included any valid argument"
	fi
}

finder() {
	/usr/bin/mdfind "$@" 2> >(grep --invert-match ' \[UserQueryParser\] ' >&2) | grep -i "$@" --color=auto
}

plist() {
	get_plist() {
		for path in $(mdfind -name LaunchDaemons) $(mdfind -name LaunchAgents); do
			[[ -d "$path" ]] && for file in "$path"/*; do
				echo "$file"
			done
		done
	}
	get_shasum() {
		get_plist | while read -r file; do
			shasum -a 256 "$file"
		done
	}
	if [[ "$1" == "get" ]]; then
		[[ -f "$CONFIG/plist_shasum.txt" ]] && rm "$CONFIG/plist_shasum.txt"
		get_shasum >"$CONFIG/plist_shasum.txt"
	elif [[ "$1" == "verify" ]]; then
		colordiff <(get_shasum) <(cat "$CONFIG/plist_shasum.txt")
	else
		get_shasum
	fi
}

remove() {
	if [[ "$1" == "brew" ]]; then
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

generate_ip() {
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

dmg() {
	if [[ "$1" == "crypt" ]]; then
		hdiutil create "$2.dmg" -encryption -size "$3" -volname "$2" -fs JHFS+
	else
		hdiutil create "$1.dmg" -size "$2" -volname "$1" -fs JHFS+
	fi
}

update() {
	brew update && brew upgrade && brew cleanup && brew autoremove
}

info() {
	brew info "$@"
}

list() {
	brew list
}

search() {
	if [[ "$1" == "web" ]]; then
		open -a Safari "https://google.com/search?q=$2" &
		open -a Chrome "https://google.com/search?q=$2" &
	else
		brew search "$@"
	fi
}

icloud() {
	cd ~/Library/Mobile\ Documents/com\~apple\~CloudDocs || return
}

clone() {
	mkdir -p "$HOME/Developer"
	cd "$HOME/Developer" || return
	if [[ "$1" =~ ^https?:// ]]; then
		git clone "$1"
		local repo_name
		repo_name=$(echo "$1" | cut -d '/' -f 5)
		echo "$repo_name" | pbcopy
		cd "$repo_name" || return
		echo "done!"
	else
		git clone "https://github.com/$@"
		local repo_name
		repo_name=$(echo "$@" | cut -d '/' -f 2)
		echo "$repo_name" | pbcopy
	fi
}

intel() {
	exec arch -x86_64 "$SHELL"
}

arm64() {
	exec arch -arm64 "$SHELL"
}

grep_line() {
	grep -n "$1" "$2"
}

get_ip() {
	dig +short "$1"
}

dump() {
	local now
	now=$(date +%s)
	case "$1" in
	"arp")
		sudo tcpdump "$NETWORK" -w "arp-$now.pcap" "ether proto 0x0806"
		;;
	"icmp")
		sudo tcpdump -ni "$NETWORK" -w "icmp-$now.pcap" "icmp"
		;;
	"pflog")
		sudo tcpdump -ni pflog0 -w "pflog-$now.pcap" "not icmp6 and not host ff02::16 and not host ff02::d"
		;;
	"syn")
		sudo tcpdump -ni "$NETWORK" -w "syn-$now.pcap" "tcp[13] & 2 != 0"
		;;
	"upd")
		sudo tcpdump -ni "$NETWORK" -w "udp-$now.pcap" "udp and not port 443"
		;;
	*)
		sudo tcpdump
		;;
	esac
}

ip() {
	curl -sq4 "https://icanhazip.com/"
}

history() {
	if [[ "$1" == "top" ]]; then
		history 1 | awk '{CMD[$2]++;count++} END { for (a in CMD) printf "%d %0.2f%% %s\n", CMD[a], CMD[a]/count*100, a }' | sort -nr | nl | head -n25
	elif [[ "$1" == "clear" || "$1" == "clean" ]]; then
		awk '!a[$0]++' "$HISTFILE" >"$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"
	fi
}

rand() {
	newUser() {
		local username
		username=$(openssl rand -base64 64 | tr -d "=+/1-9" | cut -c-20 | tr '[:upper:]' '[:lower:]')
		echo "$username" | pbcopy
		echo "$username"
	}
	newPass() {
		local password
		password=$(openssl rand -base64 300 | tr -d "=+/" | cut -c12-20 | tr '\n' '-' | cut -b -26)
		echo "$password" | pbcopy
		echo "$password"
	}
	changeId() {
		local computerName hostName localHostName
		computerName=$(newUser)
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
	"user") newUser ;;
	"pass") newPass ;;
	"mac") changeId ;;
	"line")
		awk 'BEGIN{srand();}{if (rand() <= 1.0/NR) {x=$0}}END{print x}' "$2" | pbcopy
		pbpaste
		;;
	esac
}

battery() {
	pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';'
}

pf() {
	case "$1" in
	"up") sudo pfctl -e -f "$CONFIG/firewall/pf.rules" ;;
	"down") sudo pfctl -d ;;
	"status") sudo pfctl -s info ;;
	"reload") sudo pfctl -f /etc/pf.conf ;;
	"log") sudo pfctl -s nat ;;
	"flush") sudo pfctl -F all -f /etc/pf.conf ;;
	"show") sudo pfctl -s rules ;;
	*) sudo pfctl ;;
	esac
}

branch_name() {
	git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/(\1) /p'
}

len() {
	echo -n "$1" | wc -c
}

rmip() {
	sed -E 's/\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/[REDACTED]/g' "$1" >"$2"
	echo "done!"
}

chunk() {
	local file="$1"
	local custom_chunk_size="$2"
	if [[ ! -f "$file" ]]; then
		echo "File not found: $file"
		return 1
	fi
	local total_lines chunk_size dir base
	total_lines=$(wc -l <"$file")
	if [[ -z "$custom_chunk_size" ]]; then
		chunk_size=$(echo "scale=0; sqrt($total_lines)+0.5" | bc | awk '{print int($1)}')
	else
		chunk_size="$custom_chunk_size"
	fi
	dir=$(dirname "$file")
	base=$(basename "$file")
	split -l "$chunk_size" "$file" "$dir/${base}_"
	echo "File has been split into chunks of approx $chunk_size lines each."
}

tts() {
	curl --request POST --url https://api.fish.audio/model \
		--header 'Authorization: Bearer aca83cec37dc437c8d37a761c098c80a' \
		--header 'Content-Type: multipart/form-data' \
		--form visibility=private --form type=tts --form title=bsdiufhsiduhf --form description=hjasdbfksjgndhm \
		--form "train_mode=fast" --form voices=voice1.mp3,voice2.mp3 \
		--form 'texts="lorem ipsum dolor amet"' --form 'tags="asdfsgdf"' \
		--form enhance_audio_quality=false
}

extract() {
	case "$1" in
	"zip") unzip "$2" ;;
	"tar") tar -xvf "$2" ;;
	"tar.gz") tar -xzvf "$2" ;;
	"tar.bz2") tar -xjvf "$2" ;;
	"tar.xz") tar -xJvf "$2" ;;
	"rar") unrar x "$2" ;;
	"7z") 7z x "$2" ;;
	*) echo "You haven't included any valid arguments" ;;
	esac
}

yt() {
	local current_dir
	current_dir=$(pwd)
	cd /tmp || return
	yt-dlp --restrict-filenames --no-overwrites --no-call-home --force-ipv4 --no-part "$1"
	mv *.mp4 "$HOME/Movies/TV/Movies/Action"
	echo "done"
	cd "$current_dir" || return
}

td() {
	mkdir -p "$(date +%m-%d%Y)"
}

# Aliases
alias ....="cd ../../.."
alias ...="cd ../.."
alias ..="cd .."
alias .="open ."
alias copy="pbcopy"
alias diff="colordiff"
alias doctor="brew doctor"
alias fl="flutter"
alias flp="flutter pub"
alias flpg="flutter pub get"
alias flpgb="flutter pub get && flutter packages pub run build_runner build --delete-conflicting-outputs"
alias flr="flutter run"
alias ga="git add ."
alias gm="git commit -m"
alias grep="grep --text --color"
alias hide='chflags hidden'
alias json="jq -r '.choices[0].message.content'"
alias lines="wc -l"
alias ll="ls -lhAGF1"
alias lower="tr '[:upper:]' '[:lower:]'"
alias md="mkdir -p"
alias osa="osascript -e"
alias paste="pbpaste"
alias pbc="pbcopy"
alias pbp="pbpaste"
alias pc="pbcopy"
alias pp="pbpaste"
alias rm="rm -drf"
alias santa="santactl"
alias sha256="shasum -a 256"
alias speed="unwrap && networkQuality && wrap"
alias status="git status"
alias time="date -u +%T"
alias today="date +%m-%d-%Y | pbcopy"
alias unwrap="tput rmam"
alias upper="tr '[:lower:]' '[:upper:]'"
alias words="wc -w"
alias wrap="tput smam"
alias z="source ~/.zshrc"
alias halt="sudo halt"

# Set options
setopt AUTOCD NOBEEP CORRECT ALWAYSTOEND PROMPT_SUBST COMPLETEINWORD

autoload -U colors find-command history-search-end promptinit vcs_info zargs zcalc zmv compinit

compinit -d "$TERMINAL/completions"
promptinit
vcs_info

# Completion definitions
compdef '_brew uninstall' remove
compdef '_brew install' install
compdef '_brew search' search
compdef '_brew update' update
compdef '_santactl' santa
compdef '_tcpdump' dump
compdef '_brew list' list
compdef '_tree' t
compdef '_mdfind' finder
compdef '_youtube-dl' yt
compdef '_flutter' fl
compdef '_conda activate' activate
compdef '_git clone' clone
compdef '_git push' push

# Source extras
source "$TERMINAL/suggestion.zsh"
source "$TERMINAL/highlight/init.zsh"
FPATH="$TERMINAL/completions:$FPATH"

# Prompt configuration
prompt='%F{cyan}%h %F{green}%B%~%F{red}%b $(branch_name)%f
→ '
