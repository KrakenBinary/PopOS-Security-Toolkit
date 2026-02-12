# PopOS Security Toolkit

A btop-inspired TUI for installing and managing penetration testing tools on PopOS/Ubuntu/Debian.

## Quick Install (from GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/popos-toolkit/main/install.sh | sudo bash
```

## Local Usage

```bash
git clone https://github.com/YOUR_USER/popos-toolkit.git
cd popos-toolkit
sudo ./run.sh
```

## Controls

| Key       | Action                                      |
|-----------|---------------------------------------------|
| `← →`    | Switch focus between categories and tools   |
| `↑ ↓`    | Navigate within the focused panel           |
| `Space`  | Toggle: queue install / uninstall / dequeue |
| `A`      | Apply all queued operations                 |
| `C`      | Clear the queue                             |
| `R`      | Re-detect installed tools                   |
| `Q`      | Quit (confirms if queue has items)          |

## Status Icons

| Icon | Meaning              |
|------|----------------------|
| `○`  | Not installed        |
| `●`  | Installed            |
| `◆`  | Queued for install   |
| `◇`  | Queued for uninstall |
| `⟳`  | Processing           |
| `✗`  | Failed               |

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
install_unique_id() { your_logic_here; }
# Optional: custom uninstall override
uninstall_unique_id() { your_logic_here; }
```

## License

MIT
