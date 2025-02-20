# #!/bin/bash

# BACKUP_DIR="$HOME/Backup/macOS_prefs"
# mkdir -p "$BACKUP_DIR"

# backup() {
# 	echo "Backing up system preferences..."

# 	# Finder Preferences
# 	defaults read com.apple.finder >"$BACKUP_DIR/finder.plist"

# 	# Keyboard Shortcuts
# 	defaults read com.apple.symbolichotkeys >"$BACKUP_DIR/keyboard_shortcuts.plist"

# 	# Display Configurations
# 	sudo defaults read /Library/Preferences/com.apple.windowserver >"$BACKUP_DIR/display.plist"

# 	# iTerm Preferences
# 	defaults read com.googlecode.iterm2 >"$BACKUP_DIR/iterm.plist"

# 	# Chromium Preferences
# 	if defaults read org.chromium.Chromium &>/dev/null; then
# 		defaults read org.chromium.Chromium >"$BACKUP_DIR/chromium.plist"
# 	elif defaults read com.google.Chrome &>/dev/null; then
# 		defaults read com.google.Chrome >"$BACKUP_DIR/chrome.plist"
# 	fi

# 	# Copy fallback files
# 	cp "$HOME/Library/Preferences/com.apple.finder.plist" "$BACKUP_DIR/" 2>/dev/null
# 	cp "$HOME/Library/Preferences/com.googlecode.iterm2.plist" "$BACKUP_DIR/" 2>/dev/null
# 	cp -R "$HOME/Library/Saved Application State/com.apple.finder.savedState" "$BACKUP_DIR/" 2>/dev/null

# 	echo "Backup completed! Files stored in $BACKUP_DIR"
# }

# restore() {
# 	echo "Restoring system preferences..."

# 	# Finder Preferences
# 	defaults write com.apple.finder -dict "$(cat "$BACKUP_DIR/finder.plist")"

# 	# Keyboard Shortcuts
# 	defaults write com.apple.symbolichotkeys -dict "$(cat "$BACKUP_DIR/keyboard_shortcuts.plist")"

# 	# Display Configurations
# 	sudo defaults write /Library/Preferences/com.apple.windowserver -dict "$(cat "$BACKUP_DIR/display.plist")"

# 	# iTerm Preferences
# 	defaults write com.googlecode.iterm2 -dict "$(cat "$BACKUP_DIR/iterm.plist")"

# 	# Chromium Preferences
# 	if [ -f "$BACKUP_DIR/chromium.plist" ]; then
# 		defaults write org.chromium.Chromium -dict "$(cat "$BACKUP_DIR/chromium.plist")"
# 	elif [ -f "$BACKUP_DIR/chrome.plist" ]; then
# 		defaults write com.google.Chrome -dict "$(cat "$BACKUP_DIR/chrome.plist")"
# 	fi

# 	# Restore fallback files
# 	cp "$BACKUP_DIR/com.apple.finder.plist" "$HOME/Library/Preferences/" 2>/dev/null
# 	cp "$BACKUP_DIR/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/" 2>/dev/null
# 	cp -R "$BACKUP_DIR/com.apple.finder.savedState" "$HOME/Library/Saved Application State/" 2>/dev/null

# 	# Restart services
# 	killall Finder
# 	killall cfprefsd
# 	echo "Restore completed!"
# }

# case "$1" in
# -b) backup ;;
# -r) restore ;;
# *) echo "Usage: $0 {backup|restore}" ;;
# esac

#!/bin/bash

echo "Starting macOS preferences restoration..."
echo "You will be prompted before applying each category."

# # Create an Untitled Document at Launch
# defaults write com.apple.TextEdit NSShowAppCentricOpenPanelInsteadOfUntitledFile -bool false

# # Disable the sound effects on boot
# defaults write com.apple.systemsound com.apple.sound.beep.volume -int 0

# # clean dock
# defaults write com.apple.dock static-only -bool true && killall Dock

# # Show all file extensions
# defaults write -g AppleShowAllExtensions -bool true

# # show path in finder
# defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# # show ~/Library
# chflags nohidden ~/Library

# #  Hide the dock
# defaults write com.apple.dock autohide -bool true

# # show hidden files
# defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder

# # system preferences > dock > minimize windows into application icon
# defaults write com.apple.dock minimize-to-application -bool true

# # show path bar
# defaults write com.apple.finder ShowPathbar -bool true

# Function to apply settings with user confirmation
apply_settings() {
	local category="$1"
	shift
	local commands=("$@")

	echo -e "\nRestore settings for $category? (y/n)"
	read -r response
	if [[ "$response" =~ ^[Yy]$ ]]; then
		for cmd in "${commands[@]}"; do
			eval "$cmd"
		done
		echo "$category settings restored."
	else
		echo "Skipped $category settings."
	fi
}

# Finder settings
finder_settings=(
	'defaults write com.apple.finder AppleShowAllFiles -bool true'
	'defaults write com.apple.finder ShowPathbar -bool true'
	'defaults write com.apple.finder ShowStatusBar -bool true'
	'defaults write com.apple.finder _FXShowPosixPathInTitle -bool true'
	'chflags nohidden ~/Library'
)

# Dock settings
dock_settings=(
	'defaults write com.apple.dock autohide -bool true'
	'defaults write com.apple.dock minimize-to-application -bool true'
	'defaults write com.apple.dock static-only -bool true && killall Dock'
)

# Keyboard & Text settings
keyboard_settings=(
	'defaults write -g ApplePressAndHoldEnabled -bool false'
	'defaults write -g KeyRepeat -int 2'
	'defaults write -g InitialKeyRepeat -int 15'
)

# System settings
system_settings=(
	'defaults write NSGlobalDomain AppleShowAllExtensions -bool true'
	'defaults write com.apple.systemsound com.apple.sound.beep.volume -int 0'
	'defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true'
)

# Apply settings with user confirmation
apply_settings "Finder" "${finder_settings[@]}"
apply_settings "Dock" "${dock_settings[@]}"
apply_settings "Keyboard & Text" "${keyboard_settings[@]}"
apply_settings "System Preferences" "${system_settings[@]}"

echo -e "\nRestoration complete! Some changes may require a restart."
