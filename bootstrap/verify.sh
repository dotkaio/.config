#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
BREW_BIN="/opt/homebrew/bin/brew"
TERMINAL_SOURCE="source \"\$HOME/.config/terminal/zshrc\""
ALLOW_NIX=0

if [[ "${1:-}" == "--allow-nix" ]]; then
  ALLOW_NIX=1
elif [[ $# -gt 0 ]]; then
  printf 'usage: %s [--allow-nix]\n' "$0" >&2
  exit 2
fi

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1"
}

[[ "$(uname -s)" == "Darwin" ]] || fail "macOS is required"
[[ "$(uname -m)" == "arm64" ]] || fail "Apple Silicon is required"
[[ -x "$BREW_BIN" ]] || fail "Homebrew is missing at $BREW_BIN"
[[ -f "$BREWFILE" ]] || fail "Brewfile is missing"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1

"$BREW_BIN" bundle check --file="$BREWFILE" >/dev/null || fail "Brewfile dependencies are incomplete"
pass "Brewfile dependencies"

formulae=(
  bun ffmpeg gh hf imsg llama.cpp openai-whisper pnpm ripgrep rustup shellcheck
  tesseract tree uv wget yt-dlp
)
for formula in "${formulae[@]}"; do
  "$BREW_BIN" list --formula "$formula" >/dev/null 2>&1 || fail "missing formula: $formula"
done
pass "Homebrew formulae"

casks=(iterm2 santa ungoogled-chromium)
for cask in "${casks[@]}"; do
  "$BREW_BIN" list --cask "$cask" >/dev/null 2>&1 || fail "missing cask: $cask"
done
pass "Homebrew casks"

commands=(
  brew bun ffmpeg gh hf imsg llama-cli pnpm rg rustup shellcheck tesseract tree uv
  wget whisper yt-dlp
)
for command_name in "${commands[@]}"; do
  command -v "$command_name" >/dev/null 2>&1 || fail "command does not resolve: $command_name"
done
pass "required commands"

grep -Fqx "$TERMINAL_SOURCE" "$HOME/.zshrc" || fail "$HOME/.zshrc does not source the terminal configuration"
pass "shell configuration"

if [[ "$ALLOW_NIX" -eq 0 ]]; then
  if [[ -e /nix ]]; then
    if mount | grep -q ' on /nix ' || find /nix -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
      fail "/nix is still active or contains files"
    fi
    warn "macOS will remove the empty synthetic /nix directory after the next reboot"
  fi
  [[ ! -e /etc/nix ]] || fail "/etc/nix still exists"
  [[ ! -e /usr/local/bin/determinate-nixd ]] || fail "determinate-nixd still exists"
  ! find /Library/LaunchDaemons -maxdepth 1 -name 'systems.determinate.*' -print -quit 2>/dev/null | grep -q . || fail "Determinate launch daemon remains"
  ! launchctl print system/systems.determinate.nix-daemon >/dev/null 2>&1 || fail "Determinate Nix daemon is loaded"
  ! dscl . -list /Users 2>/dev/null | grep -Eq '^_nixbld' || fail "Nix build users remain"
  ! dscl . -list /Groups 2>/dev/null | grep -Eq '^nixbld$|^_nixbld$' || fail "Nix build group remains"

  brew_target="$(readlink "$BREW_BIN" 2>/dev/null || true)"
  [[ "$brew_target" != /nix/* ]] || fail "Homebrew still points into the Nix store"
  [[ "$("$BREW_BIN" --repository)" == "/opt/homebrew" ]] || fail "Homebrew repository is not standalone"

  login_path="$(TERM_PROGRAM='' zsh -lic 'printf %s "$PATH"' 2>/dev/null)"
  [[ ":$login_path:" != *:/nix/* ]] || fail "login-shell PATH still contains Nix"
  pass "Nix removal"
fi

printf '\nAll bootstrap checks passed.\n'
