#!/usr/bin/env bash
REPO="YOUR_USER/popos-toolkit"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
INSTALL_DIR=$(mktemp -d /tmp/popos-toolkit.XXXXXX)

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31m✗ Must run as root: curl ... | sudo bash\033[0m"; exit 1
fi
if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    [[ -e /dev/tty ]] && exec </dev/tty >/dev/tty 2>/dev/tty || { echo "No terminal."; exit 1; }
fi

echo -e "\033[1;36m◈  PopOS Security Toolkit — Downloading...\033[0m"
mkdir -p "${INSTALL_DIR}/lib" "${INSTALL_DIR}/modules"

dl() { curl -fsSL "${BASE_URL}/${1}" -o "${2}" || { echo -e "\033[1;31m✗ Failed: ${1}\033[0m"; exit 1; }; }

dl "run.sh"            "${INSTALL_DIR}/run.sh"
dl "lib/tui_engine.sh" "${INSTALL_DIR}/lib/tui_engine.sh"
dl "lib/registry.sh"   "${INSTALL_DIR}/lib/registry.sh"
dl "lib/runner.sh"     "${INSTALL_DIR}/lib/runner.sh"
dl "lib/app.sh"        "${INSTALL_DIR}/lib/app.sh"

for m in nmap masscan netcat aircrack_ng reaver wifite metasploit beef john hashcat hydra wireshark tcpdump bettercap burpsuite sqlmap gobuster theharvester maltego; do
    dl "modules/${m}.sh" "${INSTALL_DIR}/modules/${m}.sh"
done
echo -e "\033[1;32m✓ Downloaded all modules.\033[0m"

export TOOLKIT_DIR="$INSTALL_DIR" LIB_DIR="${INSTALL_DIR}/lib" SCRIPT_DIR="${INSTALL_DIR}/modules"
export APP_TITLE="  ◈  PopOS Security Toolkit  ◈  " DEBUG_LOG="${INSTALL_DIR}/debug.log"

cleanup() {
    tput cnorm 2>/dev/null; tput rmcup 2>/dev/null
    stty sane 2>/dev/null; echo -ne "\033[0m"; clear
    rm -rf "${INSTALL_DIR}"
    echo -e "\033[1;36m◈  PopOS Security Toolkit — Goodbye!\033[0m"
}
trap cleanup EXIT INT TERM
chmod +x "${INSTALL_DIR}/run.sh"
source "${INSTALL_DIR}/lib/app.sh"
run_app
