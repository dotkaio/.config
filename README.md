# macOS/Linux Configuration

Personal dotfiles and system configuration for macOS and Linux systems. Includes custom Zsh functions, aliases, Homebrew management, and various productivity tools.

## Features

- Custom Zsh configuration with auto-completion and syntax highlighting
- Homebrew package management helpers
- Security utilities (Santa integration, plist monitoring, firewall management)
- Network tools (proxy management, IP utilities, tcpdump wrappers)
- Development utilities (git shortcuts, file operations, text processing)
- iTerm2 and terminal theming
- GitHub CLI configuration

## Getting Started

### Prerequisites

- macOS or Linux
- Zsh shell
- Git

### Installation

1. **Create a `.zshrc` file** if it doesn't exist:

```bash
touch ~/.zshrc
```

2. **Clone this repository** to `~/.config`:

```bash
git clone https://github.com/kaiorferraz/.config ~/.config
```

3. **Update your `.zshrc`** to source the configuration:

```bash
echo 'export CONFIG="$HOME/.config"' >> ~/.zshrc
echo 'source $CONFIG/terminal/zshrc.zsh' >> ~/.zshrc
```

4. **Set Zsh as your default shell**:

```bash
chsh -s $(which zsh)
```

5. **Restart your terminal** or source the configuration:

```bash
source ~/.zshrc
```

## Usage

### Package Management

#### Homebrew Installation

```bash
# Install Homebrew locally in ~/.config
install brew local

# Install Homebrew in default location
install brew
```

#### Package Operations

```bash
# Install packages
install <package-name>

# Reinstall packages
reinstall <package-name>

# Remove packages
remove <package-name>

# Update Homebrew and all packages
update

# Cleanup old versions
cleanup

# Remove unused dependencies
autoremove

# Get package info
info <package-name>

# List installed packages
list

# Search for packages
search <package-name>

# Search web
search web <query>
```

### Security & System Monitoring

#### Plist File Monitoring

```bash
# Verify plist files for changes
plist verify

# Update plist checksums
plist update
```

#### Application Blocking (Santa)

```bash
# Block an application
block /path/to/app

# Unblock an application
unblock /path/to/app

# Unblock common apps
unblockall
```

#### Firewall Management

```bash
# Enable firewall
pf up

# Disable firewall
pf down

# Show firewall status
pf status

# Reload firewall rules
pf reload

# Show current rules
pf show
```

### Network Utilities

```bash
# Get your public IP
shwip

# Get IP address from domain
get_ip <domain>

# Download proxy lists
proxy

# Network packet capture
dump arp      # Capture ARP traffic
dump icmp     # Capture ICMP traffic
dump syn      # Capture SYN packets
dump udp      # Capture UDP traffic
dump pflog    # Capture firewall logs

# Test network speed
speed

# WiFi control
wifi on       # Turn WiFi on
wifi off      # Turn WiFi off
wifi name     # Get WiFi network name
```

### Development Tools

#### Git Shortcuts

```bash
# Quick commit and push
push

# Clone repository to ~/Developer
clone <repository-url>
```

#### File Operations

```bash
# Enhanced directory listing
t [directory]    # Tree view with colors
ll              # Detailed list view

# Create directory with parents
md <directory>

# Replace text in file
replace <file> <old_string> <new_string>

# Extract archives
extract zip <file.zip>
extract tar <file.tar>
extract tar.gz <file.tar.gz>
```

#### Text Processing

```bash
# Convert text to numbers (leet speak)
echo "hello" | to_number

# Convert uppercase to lowercase
echo "HELLO" | lower

# Convert lowercase to uppercase
echo "hello" | upper

# Get string length
len "string"

# Redact IP addresses from file
rmip <input_file> <output_file>

# Split file into chunks
chunk <file> [chunk_size]
```

### Random Generators

```bash
# Generate random password (26 chars) and copy to clipboard
rand pass

# Generate random username and copy to clipboard
rand user

# Generate random line from file
rand line <file>

# Change Mac computer identity
rand mac
```

### Productivity

```bash
# Open config in VS Code
zshrc [file]

# Navigate to iCloud Drive
icloud

# Open Xcode
xcode [project]

# Create today's dated directory and cd into it
td

# Download YouTube video
yt <url>

# Text-to-speech using OpenAI
tts "Your text here"

# AI query using Groq
groq "Your question here"

# AI with Ollama
ai <command>
llm <command>
```

### macOS Specific

```bash
# Battery status
battery

# Finder search
finder <search-term>

# Create encrypted DMG
dmg crypt <name> <size>

# Create regular DMG
dmg <name> <size>

# Convert DMG to ISO
dmg2iso <input.dmg> <output>

# Switch to Intel architecture
intel

# Switch to ARM64 architecture
arm64

# Show/hide files
hide <file>
```

### Shell History

```bash
# Show top 25 most used commands
shwhistory top

# Clean duplicate history entries
shwhistory clear
```

## Directory Structure

```
~/.config/
├── config/          # System configuration files
├── gh/              # GitHub CLI config
├── iterm2/          # iTerm2 settings
├── proxy/           # Proxy lists
├── scripts/         # Utility scripts
│   ├── applescript/
│   ├── bash/
│   ├── perl/
│   └── python/
└── terminal/        # Terminal configuration
    ├── completions/ # Zsh completions
    ├── fresh/
    ├── highlight/   # Syntax highlighting
    ├── suggestions.zsh
    ├── themes/
    └── zshrc.zsh    # Main Zsh config
```

## Aliases

Common aliases included:

- `..`, `...`, `....` - Navigate up directories
- `dev` - Run `pnpm dev`
- `ga` - Git add all
- `gm` - Git commit with message
- `status` - Git status
- `copy` / `paste` - Clipboard operations
- `sha256` - SHA256 checksum
- `today` - Get today's date

See `terminal/zshrc.zsh` for the complete list.

## Environment Variables

The configuration sets various environment variables:

- `CONFIG` - Points to ~/.config
- `HOMEBREW_*` - Homebrew behavior settings
- `PNPM_HOME` - pnpm directory
- `CHROME_EXECUTABLE` - Chromium path

## Requirements

Optional but recommended tools:

- Homebrew
- wget
- tree
- jq
- colordiff
- yt-dlp
- ollama
- Santa (for app blocking)

## Contributing

This is a personal configuration repository. Feel free to fork and customize for your own use.

## License

Personal use configuration - use at your own risk.
