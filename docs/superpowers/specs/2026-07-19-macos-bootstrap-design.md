# Thin macOS Bootstrap Design

## Goal

Replace Nix with a small, understandable, idempotent bootstrap system for frequent macOS reinstalls.

## Architecture

The version-controlled `bootstrap/` directory is the single entry point:

- `bootstrap.sh` validates macOS, installs Homebrew when absent, applies the Brewfile, and ensures the existing terminal configuration is sourced.
- `Brewfile` declares required CLI tools and GUI applications.
- `verify.sh` checks architecture, Homebrew health, declared packages, applications, shell integration, and required commands.
- `README.md` documents fresh-install, update, and verification workflows.

Existing application-specific configuration remains under `~/.config`. Secrets remain outside the bootstrap files and are restored separately.

## Safety and Migration

1. Create the bootstrap implementation without changing the active package manager.
2. Run syntax and idempotency checks.
3. Verify every CLI tool and GUI application currently declared through Nix is available through Homebrew.
4. Remove Nix paths from the shell configuration.
5. Run the official Determinate uninstaller.
6. Verify Nix services, files, users, groups, volumes, and shell hooks are gone while the Homebrew environment still passes.
7. Remove the obsolete `~/.config/nix` configuration only after uninstall verification.

The bootstrap never removes undeclared Homebrew software automatically.

## Error Handling

Scripts use strict shell mode, clear failure messages, path-independent directory resolution, and rerunnable operations. Missing Xcode Command Line Tools stop the bootstrap with the official installation command and a rerun instruction.

## Validation

- `bash -n` for every shell script.
- `brew bundle check` for package parity.
- `verify.sh` before and after Nix removal.
- Fresh login-shell command resolution without `/nix` in `PATH`.
- Filesystem and launchd audit for Determinate/Nix remnants.
