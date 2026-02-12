#!/usr/bin/env bash
# NO set -e or set -u here — they kill the TUI silently
# Associative array lookups on missing keys + read timeouts both
# return non-zero which set -e/set -u treat as fatal.

# Resolve symlinks to get the actual script location
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
TOOLKIT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
LIB_DIR="${TOOLKIT_DIR}/lib"
SCRIPT_DIR="${TOOLKIT_DIR}/modules"
APP_TITLE="  ◈  PopOS Security Toolkit  ◈  "
DEBUG_LOG="${TOOLKIT_DIR}/debug.log"

export TOOLKIT_DIR LIB_DIR SCRIPT_DIR APP_TITLE DEBUG_LOG

# Source installation helpers
source "${LIB_DIR}/install_helpers.sh"

# ─── Debug Logger ───────────────────────────────────────────────
: > "$DEBUG_LOG"
dbg() { echo "[$(date +%H:%M:%S)] $*" >> "$DEBUG_LOG" 2>/dev/null; }
dbg "=== PopOS Security Toolkit starting ==="
dbg "Bash version: ${BASH_VERSION}"
dbg "TOOLKIT_DIR: ${TOOLKIT_DIR}"
dbg "Terminal: $(tput cols 2>/dev/null || echo '?')x$(tput lines 2>/dev/null || echo '?')"
dbg "EUID: ${EUID}"
dbg "TERM: ${TERM:-unset}"

# ─── Preflight Checks ──────────────────────────────────────────
FAIL=""

if [[ $EUID -ne 0 ]]; then
    FAIL="Not running as root. Use: sudo ./run.sh"
fi

for d in "$LIB_DIR" "$SCRIPT_DIR"; do
    if [[ ! -d "$d" ]]; then FAIL="Missing directory: ${d}"; fi
done

for f in "${LIB_DIR}/app.sh" "${LIB_DIR}/tui_engine.sh" "${LIB_DIR}/registry.sh" "${LIB_DIR}/runner.sh"; do
    if [[ ! -f "$f" ]]; then FAIL="Missing file: ${f}"; fi
done

MOD_COUNT=$(find "${SCRIPT_DIR}" -name "*.sh" 2>/dev/null | wc -l)
if (( MOD_COUNT == 0 )); then
    FAIL="No tool modules found in ${SCRIPT_DIR}/"
fi

if (( BASH_VERSINFO[0] < 4 )); then
    FAIL="Bash 4+ required. You have: ${BASH_VERSION}"
fi

if [[ ! -t 1 ]]; then
    FAIL="No interactive terminal detected."
fi

if [[ -n "$FAIL" ]]; then
    echo ""
    echo -e "\033[1;31m  ✗ Startup Failed\033[0m"
    echo -e "\033[1;31m  ─────────────────────────────────────\033[0m"
    echo -e "\033[1;31m  ${FAIL}\033[0m"
    echo ""
    dbg "PREFLIGHT FAIL: $FAIL"
    exit 1
fi

cols=$(tput cols 2>/dev/null || echo 80)
rows=$(tput lines 2>/dev/null || echo 24)
dbg "Terminal size confirmed: ${cols}x${rows}"

if (( cols < 100 || rows < 30 )); then
    echo ""
    echo -e "\033[1;33m  ⚠ Terminal Too Small\033[0m"
    echo -e "\033[1;33m  ─────────────────────────────────────\033[0m"
    echo -e "\033[1;33m  Current: ${cols} columns × ${rows} rows\033[0m"
    echo -e "\033[1;33m  Minimum: 100 columns × 30 rows\033[0m"
    echo ""
    echo -e "\033[0;36m  Resize your terminal and press Enter.\033[0m"
    read -rp "  [Enter to continue, Ctrl+C to abort]: "
fi

dbg "Preflight passed. Sourcing app.sh..."

# ─── Cleanup Trap ───────────────────────────────────────────────
TUI_STARTED=0
cleanup() {
    local exit_code=$?
    dbg "Cleanup called. exit_code=${exit_code} TUI_STARTED=${TUI_STARTED}"

    if (( TUI_STARTED )); then
        tput cnorm 2>/dev/null
        tput rmcup 2>/dev/null
        stty sane 2>/dev/null
        echo -ne "\033[0m"
        clear
    fi

    if (( exit_code != 0 )); then
        echo ""
        echo -e "\033[1;31m  ✗ Exited with error (code: ${exit_code})\033[0m"
        echo -e "\033[0;36m  Debug log: ${DEBUG_LOG}\033[0m"
        echo ""
        echo -e "\033[0;36m  Last 20 lines:\033[0m"
        tail -20 "$DEBUG_LOG" 2>/dev/null | sed 's/^/    /'
        echo ""
    else
        echo -e "\033[1;36m◈  PopOS Security Toolkit — Goodbye!\033[0m"
    fi
}
trap cleanup EXIT INT TERM

# ─── Launch ─────────────────────────────────────────────────────
source "${LIB_DIR}/app.sh"
dbg "app.sh sourced successfully"
TUI_STARTED=1
dbg "Calling run_app..."
run_app
dbg "run_app exited normally"
