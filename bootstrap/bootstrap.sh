#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
BREW_BIN="/opt/homebrew/bin/brew"
ZSHRC="$HOME/.zshrc"
TERMINAL_SOURCE="source \"\$HOME/.config/terminal/zshrc\""

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || fail "This bootstrap supports macOS only."
[[ "$(uname -m)" == "arm64" ]] || fail "This bootstrap currently supports Apple Silicon only."
[[ -f "$BREWFILE" ]] || fail "Missing Brewfile: $BREWFILE"

if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  fail "Finish installing the Xcode Command Line Tools, then rerun this script."
fi

if [[ ! -x "$BREW_BIN" ]]; then
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

log "Installing declared tools and applications"
"$BREW_BIN" bundle install --file="$BREWFILE"
"$BREW_BIN" analytics off >/dev/null

log "Configuring Git identity"
git config --global user.name dotkaio
git config --global user.email github@kaio.email

log "Ensuring the terminal configuration is loaded"
touch "$ZSHRC"
if ! grep -Fqx "$TERMINAL_SOURCE" "$ZSHRC"; then
  printf '%s\n' "$TERMINAL_SOURCE" >> "$ZSHRC"
fi

log "Verifying bootstrap"
"$SCRIPT_DIR/verify.sh" "$@"

printf '\nBootstrap complete. Open a new terminal session.\n'
