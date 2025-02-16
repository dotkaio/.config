#!/bin/bash

BACKUP_DIR="$HOME/Backup/macOS_prefs"
mkdir -p "$BACKUP_DIR"

backup() {
	echo "Backing up system preferences..."

	# Finder Preferences
	defaults read com.apple.finder >"$BACKUP_DIR/finder.plist"

	# Keyboard Shortcuts
	defaults read com.apple.symbolichotkeys >"$BACKUP_DIR/keyboard_shortcuts.plist"

	# Display Configurations
	sudo defaults read /Library/Preferences/com.apple.windowserver >"$BACKUP_DIR/display.plist"

	# iTerm Preferences
	defaults read com.googlecode.iterm2 >"$BACKUP_DIR/iterm.plist"

	# Chromium Preferences
	if defaults read org.chromium.Chromium &>/dev/null; then
		defaults read org.chromium.Chromium >"$BACKUP_DIR/chromium.plist"
	elif defaults read com.google.Chrome &>/dev/null; then
		defaults read com.google.Chrome >"$BACKUP_DIR/chrome.plist"
	fi

	# Copy fallback files
	cp "$HOME/Library/Preferences/com.apple.finder.plist" "$BACKUP_DIR/" 2>/dev/null
	cp "$HOME/Library/Preferences/com.googlecode.iterm2.plist" "$BACKUP_DIR/" 2>/dev/null
	cp -R "$HOME/Library/Saved Application State/com.apple.finder.savedState" "$BACKUP_DIR/" 2>/dev/null

	echo "Backup completed! Files stored in $BACKUP_DIR"
}

restore() {
	echo "Restoring system preferences..."

	# Finder Preferences
	defaults write com.apple.finder -dict "$(cat "$BACKUP_DIR/finder.plist")"

	# Keyboard Shortcuts
	defaults write com.apple.symbolichotkeys -dict "$(cat "$BACKUP_DIR/keyboard_shortcuts.plist")"

	# Display Configurations
	sudo defaults write /Library/Preferences/com.apple.windowserver -dict "$(cat "$BACKUP_DIR/display.plist")"

	# iTerm Preferences
	defaults write com.googlecode.iterm2 -dict "$(cat "$BACKUP_DIR/iterm.plist")"

	# Chromium Preferences
	if [ -f "$BACKUP_DIR/chromium.plist" ]; then
		defaults write org.chromium.Chromium -dict "$(cat "$BACKUP_DIR/chromium.plist")"
	elif [ -f "$BACKUP_DIR/chrome.plist" ]; then
		defaults write com.google.Chrome -dict "$(cat "$BACKUP_DIR/chrome.plist")"
	fi

	# Restore fallback files
	cp "$BACKUP_DIR/com.apple.finder.plist" "$HOME/Library/Preferences/" 2>/dev/null
	cp "$BACKUP_DIR/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/" 2>/dev/null
	cp -R "$BACKUP_DIR/com.apple.finder.savedState" "$HOME/Library/Saved Application State/" 2>/dev/null

	# Restart services
	killall Finder
	killall cfprefsd
	echo "Restore completed!"
}

case "$1" in
-b) backup ;;
-r) restore ;;
*) echo "Usage: $0 {backup|restore}" ;;
esac
