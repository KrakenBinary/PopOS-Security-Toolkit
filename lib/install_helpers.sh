#!/usr/bin/env bash
# lib/install_helpers.sh - Helper functions for safe installation operations

# require_command - Check if a command exists, fail with helpful message if not
# Usage: require_command <command_name> <package_name> || return 1
require_command() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if ! command -v "$cmd" &>/dev/null; then
        echo "[ERROR] Required command '$cmd' not found" >> "${RUN_LOG}"
        echo "[INFO] Install it with: sudo apt-get install -y $pkg" >> "${RUN_LOG}"
        return 1
    fi
    return 0
}

# safe_cd - Change directory with error checking
# Usage: safe_cd <directory> || return 1
safe_cd() {
    local target="$1"

    if ! cd "$target" 2>>"${RUN_LOG}"; then
        echo "[ERROR] Failed to change directory to: $target" >> "${RUN_LOG}"
        return 1
    fi
    return 0
}

# safe_mkdir - Create directory with error checking
# Usage: safe_mkdir <directory> || return 1
safe_mkdir() {
    local target="$1"

    if ! mkdir -p "$target" 2>>"${RUN_LOG}"; then
        echo "[ERROR] Failed to create directory: $target" >> "${RUN_LOG}"
        return 1
    fi
    return 0
}

# safe_download - Download file with error checking
# Usage: safe_download <url> <output_file> [checksum] || return 1
safe_download() {
    local url="$1"
    local output="$2"
    local checksum="$3"

    echo "[INFO] Downloading: $url" >> "${RUN_LOG}"

    # Try curl first, then wget
    if command -v curl &>/dev/null; then
        if ! curl -fsSL -o "$output" "$url" 2>>"${RUN_LOG}"; then
            echo "[ERROR] Download failed: $url" >> "${RUN_LOG}"
            rm -f "$output" 2>/dev/null
            return 1
        fi
    elif command -v wget &>/dev/null; then
        if ! wget -q -O "$output" "$url" 2>>"${RUN_LOG}"; then
            echo "[ERROR] Download failed: $url" >> "${RUN_LOG}"
            rm -f "$output" 2>/dev/null
            return 1
        fi
    else
        echo "[ERROR] Neither curl nor wget found" >> "${RUN_LOG}"
        return 1
    fi

    # Verify checksum if provided
    if [[ -n "$checksum" ]]; then
        echo "[INFO] Verifying checksum..." >> "${RUN_LOG}"
        local actual_sum
        actual_sum=$(sha256sum "$output" | awk '{print $1}')

        if [[ "$actual_sum" != "$checksum" ]]; then
            echo "[ERROR] Checksum mismatch!" >> "${RUN_LOG}"
            echo "[ERROR] Expected: $checksum" >> "${RUN_LOG}"
            echo "[ERROR] Got: $actual_sum" >> "${RUN_LOG}"
            rm -f "$output" 2>/dev/null
            return 1
        fi
        echo "[INFO] Checksum verified" >> "${RUN_LOG}"
    fi

    return 0
}

# safe_exec - Execute command with logging
# Usage: safe_exec <command> [args...] || return 1
safe_exec() {
    echo "[EXEC] $*" >> "${RUN_LOG}"

    if ! "$@" >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] Command failed: $*" >> "${RUN_LOG}"
        return 1
    fi
    return 0
}

# safe_git_clone - Clone git repository with error checking
# Usage: safe_git_clone <repo_url> <target_dir> || return 1
safe_git_clone() {
    local repo="$1"
    local target="$2"

    require_command git git || return 1

    echo "[INFO] Cloning repository: $repo" >> "${RUN_LOG}"

    if ! git clone "$repo" "$target" >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] Git clone failed: $repo" >> "${RUN_LOG}"
        rm -rf "$target" 2>/dev/null
        return 1
    fi

    return 0
}

# safe_pip3_install - Install Python package with pip3
# Usage: safe_pip3_install <package> [package...] || return 1
safe_pip3_install() {
    require_command pip3 python3-pip || return 1

    echo "[INFO] Installing Python packages: $*" >> "${RUN_LOG}"

    if ! pip3 install --upgrade "$@" >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] pip3 install failed for: $*" >> "${RUN_LOG}"
        return 1
    fi

    return 0
}

# safe_go_install - Install Go package
# Usage: safe_go_install <package_path> || return 1
safe_go_install() {
    local pkg="$1"

    require_command go golang-go || return 1

    echo "[INFO] Installing Go package: $pkg" >> "${RUN_LOG}"

    if ! go install "$pkg" >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] go install failed for: $pkg" >> "${RUN_LOG}"
        return 1
    fi

    # Ensure GOPATH/bin is in PATH by symlinking to /usr/local/bin
    local gopath="${GOPATH:-$HOME/go}"
    local binary_name
    binary_name=$(basename "$pkg" | cut -d'@' -f1)

    if [[ -f "$gopath/bin/$binary_name" ]]; then
        echo "[INFO] Creating symlink for: $binary_name" >> "${RUN_LOG}"
        ln -sf "$gopath/bin/$binary_name" /usr/local/bin/ 2>>"${RUN_LOG}"
    fi

    return 0
}

# safe_snap_install - Install snap package
# Usage: safe_snap_install <package> [--classic] || return 1
safe_snap_install() {
    require_command snap snapd || return 1

    echo "[INFO] Installing snap package: $*" >> "${RUN_LOG}"

    if ! snap install "$@" >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] snap install failed for: $*" >> "${RUN_LOG}"
        return 1
    fi

    return 0
}

# cleanup_on_failure - Remove directory on installation failure
# Usage: cleanup_on_failure <directory>
cleanup_on_failure() {
    local target="$1"

    if [[ -d "$target" ]]; then
        echo "[INFO] Cleaning up failed installation: $target" >> "${RUN_LOG}"
        rm -rf "$target" 2>>"${RUN_LOG}"
    fi
}

# verify_binary - Check if binary was successfully installed
# Usage: verify_binary <command_name> || return 1
verify_binary() {
    local cmd="$1"

    if ! command -v "$cmd" &>/dev/null; then
        echo "[ERROR] Installation verification failed - binary not found: $cmd" >> "${RUN_LOG}"
        return 1
    fi

    echo "[INFO] Installation verified: $cmd" >> "${RUN_LOG}"
    return 0
}
