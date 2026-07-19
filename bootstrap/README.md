# macOS Bootstrap

A thin, idempotent macOS setup built from Bash and Homebrew.

## Fresh Mac

Restore this `~/.config` repository, then run:

```sh
~/.config/bootstrap/bootstrap.sh
```

The script:

1. checks macOS, Apple Silicon, and Xcode Command Line Tools;
2. installs Homebrew when needed;
3. applies `Brewfile`;
4. configures the Git identity;
5. ensures `~/.zshrc` loads `~/.config/terminal/zshrc`;
6. verifies the resulting environment.

It is safe to rerun. It never removes undeclared Homebrew software.

## Add or remove software

Edit `Brewfile`, then rerun `bootstrap.sh`. Use `brew` entries for CLI tools and `cask` entries for applications.

## Verify

```sh
~/.config/bootstrap/verify.sh
```

Verification checks the Brewfile, required commands, shell integration, standalone Homebrew installation, and absence of Nix. After uninstalling Nix, macOS may retain empty synthetic `/nix` and `/run` entries until the next reboot; they are inactive and do not prevent normal use.

## Secrets

SSH keys, API credentials, signing keys, and other secrets are intentionally excluded. Restore them separately after bootstrap.
