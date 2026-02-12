# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PopOS Security Toolkit is a btop-inspired TUI application for installing and managing penetration testing tools on PopOS/Ubuntu/Debian systems. It provides an interactive terminal interface with categories, tool lists, status tracking, and queue-based installation management.

## Running the Application

```bash
sudo ./run.sh
```

The application requires root privileges and an interactive terminal with minimum dimensions of 100×30 characters.

## Architecture

### Entry Point & Core Flow

- **run.sh**: Entry point that performs preflight checks (root access, Bash 4+, terminal detection), sets up cleanup traps, and sources `lib/app.sh`
- **lib/app.sh**: Main application logic that orchestrates the TUI loop, handles user input, and coordinates rendering
- **lib/tui_engine.sh**: Low-level rendering primitives (buffering, cursor positioning, box drawing, color management)
- **lib/registry.sh**: Tool registry management (loading modules, tracking tool state, category management)
- **lib/runner.sh**: Queue processing and installation/uninstallation execution
- **modules/*.sh**: Individual tool definitions that call `register_tool()` during module load

### Critical Bash Constraints

**NEVER use `set -e` or `set -u` in any file.** The TUI relies on:
- `read_key()` returning non-zero on timeout (normal operation)
- Associative array lookups on missing keys returning non-zero
- Both behaviors would cause fatal exits with `set -e`/`set -u` enabled

### Data Model

Tool state is tracked in associative arrays declared in `lib/registry.sh`:
- `TOOL_NAME`, `TOOL_DESC`, `TOOL_PKG`, `TOOL_CHECK`, `TOOL_CAT`: Tool metadata
- `TOOL_STATUS`: Current state (see state machine below)
- `CAT_TOOLS`: Maps category names to space-separated tool IDs
- `ALL_TOOL_IDS`: Array of all registered tool IDs
- `CATEGORIES`: Array of all category names

### Tool Status State Machine

```
not_installed ←→ queue_install → installing → installed | failed
installed ←→ queue_uninstall → uninstalling → not_installed | failed
```

Detection uses `command -v <binary>` or `dpkg -s <package>`.

## Adding a New Tool

Create a file in `modules/` (e.g., `modules/mytool.sh`):

```bash
#!/usr/bin/env bash
register_tool "tool_id" \
    "Display Name" \
    "Category Name" \
    "apt-package-name" \
    "binary-to-check" \
    "Description text."

# Optional: custom install logic
install_tool_id() {
    # Custom installation commands
    # Output goes to ${TOOLKIT_DIR}/run.log
}

# Optional: custom uninstall logic
uninstall_tool_id() {
    # Custom removal commands
}
```

Without custom functions, the runner uses `apt-get install/remove -y <package>`.

## TUI Rendering System

The TUI uses a buffered rendering approach:
1. `buf_clear()` - Reset buffer
2. `buf_add()` - Append ANSI sequences
3. `buf_flush()` - Write buffer to stdout
4. Layout is calculated in `calc_layout()` based on terminal dimensions
5. Full redraws occur on `NEEDS_REDRAW=1` or terminal resize

Panels: Title bar, Categories (left), Tools (center), Description (right), Status Log (bottom), Status bar (footer).

## Key Files

- **run.sh:112** - Calls `run_app()`
- **lib/app.sh:368** - Main event loop in `run_app()`
- **lib/app.sh:265** - Input handling in `handle_input()`
- **lib/registry.sh:13** - Tool registration function
- **lib/runner.sh:17** - Queue processing in `process_queue()`
- **lib/tui_engine.sh:143** - Non-blocking key reader with 150ms timeout

## Debugging

Debug output is written to `${TOOLKIT_DIR}/debug.log` via the `dbg()` function. Runtime logs (install/uninstall output) go to `${TOOLKIT_DIR}/run.log`.
