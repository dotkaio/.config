#!/usr/bin/env zsh

# if [ -f "$HOME/.zshrc" ]; then
# 	source $HOME/.zshrc
# else
# 	echo 'source $HOME/.config/terminal/zshrc.zsh' > $HOME/.zshrc
#     touch .hushlogin && source $HOME/.zshrc
# fi

#environment variables
export CONFIG="$HOME/.config"
export TERMINAL="$CONFIG/terminal"
#export CHROME_EXECUTABLE="/Applications/Chromium.app/Contents/MacOS/Chromium"

export HOMEBREW_NO_AUTO_UPDATE
export HOMEBREW_NO_ANALYTICS
export HOMEBREW_NO_GITHUB_API
export HOMEBREW_NO_EMOJI
export HOMEBREW_NO_INSECURE_REDIRECT
export HOMEBREW_NO_ENV_HINTS
export HOMEBREW_NO_INSTALL_CLEANUP
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_NO_ANALYTICS
export HOMEBREW_NO_AUTO_UPDATE
export HOMEBREW_NO_INSECURE_REDIRECT
# export PATH=$GEM_HOME/bin:$PATH
# export PATH=$GEM_HOME/gems/bin:$PATH

#prepend a directory to path if it exists
function path {
	[[ -d "$1" ]] && export PATH="$1:$PATH"
}

#add essential paths
for p in /bin \
	/sbin \
	/usr/bin \
	/usr/sbin \
	/usr/local/bin \
	/usr/local/sbin \
	/opt/homebrew/bin \
	/Library/Developer/CommandLineTools/usr/bin \
	/Library/Developer/CommandLineTools/usr/lib; do
	path "$p"
done

# functions
function yt {
	local foo = $(PWD)
	cd $HOME/Movies/TV/Media.localized/.Media
	yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 "$1"
	cd $foo

}

function activate {
	if [[ -z "$1" ]]; then
		echo "Usage: activate <environment>"
		return 1
	fi
	conda activate "$1"
}

function wrap {
	tput smam
}

function unwrap {
	tput rmam
}

function ip_from_url {
	if [ -n "$1" ]; then
		data=$(cat "$1")
	else
		if command -v pbpaste >/dev/null; then
			data=$(pbpaste)
		elif command -v xclip >/dev/null; then
			data=$(xclip -o)
		else
			echo "No clipboard tool available."
			exit 1
		fi
	fi

	touch blocked

	while IFS= read -r host; do
		[ -z "$host" ] && continue
		ip=$(dig +short "$host" | head -n1)
		# include just the ip address separeated by comma and newline
		echo "$ip," >>blocked
	done <<<"$data"
}

function convert_nextjs {
	/opt/homebrew/Caskroom/miniconda/base/bin/python /Users/sysadm/.config/scripts/python/convert_to_nextjs.py
}

function to_number {
	tr 'Aa' '4' | tr 'Ee' '3' | tr 'Ii' '1' | tr 'Oo' '0' | tr 'Ss' '5' | tr 'Tt' '7'
}

function dmg2iso {
	hdiutil convert "$1" -format UDTO -o "$2" && mv "$2.cdr" "$2.iso"
}

function zshrc {
	if command -v code >/dev/null; then
		[[ -n "$1" ]] && code "$TERMINAL/$1" || code "$HOME/.config"
	else
		[[ -n "$1" ]] && open -a TextEdit "$HOME/.config/terminal/$1" || echo "missing argument"
	fi
}

function xcode {
	[[ -e "$1" ]] && open -a Xcode "$1" || open -a Xcode
}

function replace {
	if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
		echo "Usage: replace <file> <old_string> <new_string>"
		return 1
	fi
	sed -i '' "s/$2/$3/g" "$1"
}

function push {
	git add .
	git commit -m "duh"
	git push
}

function t {
	if command -v tree >/dev/null; then
		tree --sort=name -LlaC 1 --dirsfirst "$@"
	else
		ls -Glap1 "$@"
	fi
}

# ensure to call this when santactl is installed
function block {
	if command -v santactl >/dev/null; then
		sudo santactl rule --silent-block --path "$@"
	else
		echo "Santa not installed"
	fi
}

function unblock {
	sudo santactl rule --remove --path "$@"
}

function unblockall {
	for app in "Messages.app" "FaceTime.app" "Mail.app" "System Settings.app" "Chromium.app"; do
		if [[ "$app" == "Chromium.app" ]]; then
			sudo santactl rule --remove --path "/Applications/$app"
		else
			sudo santactl rule --remove --path "/System/Applications/$app"
		fi
	done
}

function proxy {
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

function install {
	if [[ $1 == 'brew' ]]; then
		if [[ $2 == 'local' ]]; then
			cd $CONFIG
			mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C Homebrew
			cd $HOME
		else
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi
	elif [[ $1 == 'node' ]]; then
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
		nvm install node
	elif [[ $1 == 'flutter' ]]; then
		#
	else
		brew install "$@"
	fi
}

function reinstall {
	brew reinstall "$@"
}

function wifi {
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

function finder {
	/usr/bin/mdfind "$@" 2> >(grep --invert-match ' \[UserQueryParser\] ' >&2) | grep -i "$@" --color=auto
}

function plist {
	function get_plist {
		for the_path in $(mdfind -name LaunchDaemons) $(mdfind -name LaunchAgents); do
			[[ -d "$the_path" ]] && for file in "$the_path"/*; do
				echo "$file"
			done
		done
	}
	function get_shasum {
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

function remove {
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
	if [[ "$1" == "crypt" ]]; then
		hdiutil create "$2.dmg" -encryption -size "$3" -volname "$2" -fs JHFS+
	else
		hdiutil create "$1.dmg" -size "$2" -volname "$1" -fs JHFS+
	fi
}

function update {
	brew update && brew upgrade && brew cleanup && brew autoremove
}

function info {
	brew info "$@"
}

function list {
	brew list
}

function search {
	if [[ "$1" == "web" ]]; then
		if [[ -e /Applications/Chromium.app ]]; then
			open -a Chromium "https://google.com/search?q=$2" || return
		else
			open -a Safari "https://google.com/search?q=$2" || return
		fi
	else
		brew search "$@"
	fi
}

function icloud {
	cd ~/Library/Mobile\ Documents/com\~apple\~CloudDocs || return
}

function clone {
	#check if folder inside documents/dev exists
	[[ ! -d "$HOME/Developer" ]] && mkdir -p "$HOME/Developer"
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

function shwip {
	curl -sq4 "https://icanhazip.com/"
}

function shwhistory {
	if [[ "$1" == "top" ]]; then
		history 1 | awk '{CMD[$2]++;count++} END { for (a in CMD) printf "%d %0.2f%% %s\n", CMD[a], CMD[a]/count*100, a }' | sort -nr | nl | head -n25
	elif [[ "$1" == "clear" || "$1" == "clean" ]]; then
		awk '!a[$0]++' "$HISTFILE" >"$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"
	fi
}

function rand {
	function newUser {
		local username
		username=$(openssl rand -base64 64 | tr -d "=+/1-9" | cut -c-20 | tr '[:upper:]' '[:lower:]')
		echo "$username" | pbcopy
	}
	function newPass {
		local password
		password=$(openssl rand -base64 300 | tr -d "=+/" | cut -c12-20 | tr '\n' '-' | cut -b -26)
		echo "$password" | pbcopy
	}
	function changeId {
		local computerName hostName localHostName
		computerName=$(newUser)
		hostName="$(newUser).local"
		localHostName="$(newUser)_machine"

		sudo scutil --set ComputerName "$computerName"
		sudo scutil --set HostName "$hostName"
		sudo scutil --set LocalHostName "$localHostName"
		sudo dscacheutil -flushcache

		networksetup -setairportnetwork en2 DG_link_5GHz Dg_Serrano2016
	}
	case "$1" in
	"user") newUser ;;
	"-u") newUser ;;
	"pass") newPass ;;
	"mac") changeId ;;
	"line")
		awk 'BEGIN{srand();}{if (rand() <= 1.0/NR) {x=$0}}END{print x}' "$2" | pbcopy
		pbpaste
		;;
	esac
}

function battery {
	pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';'
}

function ftchw {
	if [ "$(command -v wget)" ]; then
		wget --mirror --convert-links \
			--adjust-extension --page-requisites \
			--no-parent --span-hosts \
			--exclude-domains=google.com, \
			--user-agent="Mozilla/5.0 (Android 2.2; Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.19.4 (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4" \
			--https-only \
			--domains=$1 $1
	fi
}

function pf {
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

function branch_name {
	git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/(\1) /p'
}

function len {
	echo -n "$1" | wc -c
}

function rmip {
	sed -E 's/\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/[REDACTED]/g' "$1" >"$2"
	echo "done!"
}

function chunk {
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

#openai voice api
function tts {
	if [[ -z "$1" ]]; then
		echo "Usage: tts <text>"
		return 1
	fi
	curl https://api.openai.com/v1/audio/speech \
		-H "Authorization: Bearer $OPENAI_API_KEY" \
		-H "Content-Type: application/json" \
		-d "{
	\"model\": \"tts-1\",
	\"input\": \"$1\",
	\"voice\": \"ash\"
  }" \
		--output speech.mp3
	afplay speech.mp3
	rm speech.mp3
}

function extract {
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

function td {
	mkdir -p "$(date +%m-%d%Y)"
}

function halt {
	sudo halt
}

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'                          # case-insensitive completion
zstyle ':completion:*' menu select=2                                               # select completion with arrow keys
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s # completion prompt
zstyle ':completion:*' list-colors ' =*=0=*=32'                                    # color completion
zstyle ':completion:*' list-colors ' =*=>1=*=32'                                   # color completion
zstyle ':completion:*' list-colors ' =*<=1=*=32'                                   # color completion
zstyle ':completion:*' list-colors ' =*[^=]*=0=*=32'                               # color completion
zstyle ':completion:*' list-colors ' =*[^=]*=1=*=32'                               # color completion
zstyle ':completion:*' list-colors ' =*[^=]*=2=*=32'                               # color completion
zstyle ':completion:*' list-colors ' =*[^=]*=3=*=32'                               # color completion

#alias
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
#alias halt="sudo halt"
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
alias yt='yt-dlp'
alias z="source ~/.zshrc"

#set options
setopt \
	AUTOCD \
	NOBEEP \
	CORRECT \
	ALWAYSTOEND \
	PROMPT_SUBST \
	APPEND_HISTORY \SHARE_HISTORY \
	COMPLETE_IN_WORD \
	HIST_IGNORE_ALL_DUPS \
	HIST_IGNORE_SPACE \
	HIST_REDUCE_BLANKS \
	HIST_VERIFY \
	HIST_EXPIRE_DUPS_FIRST \
	HIST_FIND_NO_DUPS \
	HIST_SAVE_NO_DUPS \
	HIST_IGNORE_DUPS

autoload -U colors find-command history-search-end promptinit vcs_info zargs zcalc zmv compinit
rm $HOME/.zcompdump 2>/dev/null
compinit

promptinit
vcs_info

#completion definitions
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

#source extras
source "$TERMINAL/suggestion.zsh"
source "$TERMINAL/highlight/init.zsh"
FPATH="$TERMINAL/completions:$FPATH"

#set history file and options
HISTFILE="$HOME/.history"
HISTSIZE=10000
SAVEHIST=10000

#prompt configuration
prompt='%F{cyan}%h %F{green}%B%~%F{red}%b $(branch_name)%f
→ '

#development configuration
export PATH="$HOME/.lmstudio/bin:$PATH"

#pnpm
if [ -d "/Users/sysadm/.pnpm" ]; then
	export PATH="/Users/sysadm/.pnpm:$PATH"
	case ":$PATH:" in
	*":$PNPM_HOME:"*) ;;
	*) export PATH="$PNPM_HOME:$PATH" ;;
	esac
fi

#conda
if [ -d "/opt/homebrew/Caskroom/miniconda/base" ]; then
	__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
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
fi

#load nvm
if [ -d "$HOME/.nvm" ]; then
	export NVM_DIR="$HOME/.nvm"
	[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
	[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
fi

#lmstudio
if [ -d "/Users/sysadm/.lmstudio" ]; then
	export PATH="$PATH:/Users/sysadm/.lmstudio/bin"
fi

# if file .zshrc_history exists run mdfindn -name zshrc and delete the file
if [ -f "$HOME/.zshrc_history" ]; then
	mdfind -name zshrc | xargs rm
fi

if [ "$(command -v bun)" ]; then
	# bun completions
	[ -s "/Users/sysadm/.bun/_bun" ] && source "/Users/sysadm/.bun/_bun"

	# bun
	export BUN_INSTALL="$HOME/.bun"
	export PATH="$BUN_INSTALL/bin:$PATH"

fi
