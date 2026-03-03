#!/bin/bash

echo "Starting macOS preferences restoration..."
echo "You will be prompted before applying each category."

# apply_settings() {
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
