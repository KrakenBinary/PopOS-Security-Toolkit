# PopOS Security Toolkit

A btop-inspired TUI for installing and managing penetration testing tools on PopOS/Ubuntu/Debian.

## Features

- 🎯 Interactive TUI for browsing and installing 50+ security tools
- 🔧 **New**: Built-in configuration manager for Git and GitHub setup
- 🛡️ **Improved**: Enhanced error handling and security in all install functions
- 📦 Queue-based installation management
- 🔍 Automatic detection of installed tools
- 🎨 Intuitive keyboard-driven interface

## Quick Install (from GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/KrakenBinary/PopOS-Security-Toolkit/main/install.sh | sudo bash
```

This will:
- Install to `/opt/popos-toolkit`
- Create a symlink at `/usr/local/bin/popos-toolkit`
- Make it accessible system-wide

Then run:
```bash
sudo popos-toolkit
```

## Local Usage

```bash
git clone https://github.com/KrakenBinary/PopOS-Security-Toolkit.git
cd PopOS-Security-Toolkit
sudo ./run.sh
```

## Controls

### Tools Mode

| Key       | Action                                      |
|-----------|---------------------------------------------|
| `T`      | **Toggle to Configuration mode**            |
| `← →`    | Switch focus between categories and tools   |
| `↑ ↓`    | Navigate within the focused panel           |
| `Space`  | Toggle: queue install / uninstall / dequeue |
| `A`      | Apply all queued operations                 |
| `C`      | Clear the queue                             |
| `R`      | Re-detect installed tools                   |
| `Q`      | Quit (confirms if queue has items)          |

### Configuration Mode

| Key       | Action                                      |
|-----------|---------------------------------------------|
| `T`      | **Return to Tools mode**                    |
| `↑ ↓`    | Navigate configuration options              |
| `Enter`  | Edit selected field                         |
| `S`      | Save configuration and apply changes        |
| `G`      | Generate SSH key (when on SSH key field)    |
| `Esc`    | Go back / Cancel editing                    |
| `Q`      | Quit                                        |

## Status Icons

| Icon | Meaning              |
|------|----------------------|
| `○`  | Not installed        |
| `●`  | Installed            |
| `◆`  | Queued for install   |
| `◇`  | Queued for uninstall |
| `⟳`  | Processing           |
| `✗`  | Failed               |

## Configuration Features

Press `T` from the main screen to access the configuration manager:

### Git Configuration
- Set `user.name` and `user.email`
- Automatically applies to `git config --global`
- No more manual terminal commands!

### GitHub Configuration
- **SSH Key Management**: Specify or generate ed25519 SSH keys
- **GitHub Token**: Store your personal access token securely (masked in UI)
- Configuration stored in `~/.popos-toolkit/config` with 600 permissions

## Adding a New Tool

Create a new `.sh` file in `modules/`:

```bash
#!/usr/bin/env bash
register_tool "unique_id" \
    "Display Name" \
    "Category Name" \
    "apt-package-name" \
    "binary-to-check" \
    "Description of the tool."

# Optional: custom install override
install_unique_id() {
    # Use helper functions from lib/install_helpers.sh:
    # - safe_exec, safe_download, safe_git_clone
    # - safe_pip3_install, safe_go_install, safe_snap_install
    # - require_command, verify_binary
    your_logic_here
}

# Optional: custom uninstall override
uninstall_unique_id() { your_logic_here; }
```

## Recent Improvements

### Security & Reliability (Latest Update)
- ✅ **Fixed critical security vulnerability** in Metasploit installer
- ✅ **New helper library** (`lib/install_helpers.sh`) with safe installation functions
- ✅ **Enhanced error handling** across all custom install functions:
  - BeEF, Bettercap, Gobuster, TheHarvester, Wifite
  - BurpSuite, Maltego, Wireshark
- ✅ **Prerequisite validation** - checks for Go, pip3, snap before attempting installation
- ✅ **Proper cleanup** on installation failures
- ✅ **Better logging** - all errors logged to `run.log` instead of being silently suppressed

### New Features
- ✅ **Configuration Manager** - Press `T` to configure Git and GitHub settings
- ✅ **SSH Key Generation** - Generate ed25519 keys directly from the TUI
- ✅ **Secure Token Storage** - GitHub tokens stored with proper permissions (600)

## License

MIT
