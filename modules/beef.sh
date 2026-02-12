#!/usr/bin/env bash
register_tool "beef" "BeEF" "Exploitation" "beef-xss" "beef-xss" \
    "Browser Exploitation Framework focusing on web browser vulnerabilities. Hooks browsers and uses them as beachheads for directed command modules and client-side attack vectors."
install_beef() {
    echo "[INFO] Attempting to install BeEF via apt..." >> "${RUN_LOG}"

    # Try distribution package first
    if apt-get install -y beef-xss >> "${RUN_LOG}" 2>&1; then
        verify_binary beef-xss && return 0
    fi

    # If apt fails, try git installation
    echo "[INFO] apt installation failed, attempting git installation" >> "${RUN_LOG}"

    # Install prerequisites
    echo "[INFO] Installing prerequisites..." >> "${RUN_LOG}"
    safe_exec apt-get install -y ruby ruby-dev build-essential git || {
        echo "[ERROR] Failed to install prerequisites for BeEF" >> "${RUN_LOG}"
        return 1
    }

    # Clone to temporary location first
    local temp_dir="/tmp/beef-install.$$"
    safe_git_clone "https://github.com/beefproject/beef.git" "$temp_dir" || {
        cleanup_on_failure "$temp_dir"
        return 1
    }

    # Run installer
    safe_cd "$temp_dir" || {
        cleanup_on_failure "$temp_dir"
        return 1
    }

    if ! ./install >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] BeEF installer script failed" >> "${RUN_LOG}"
        cd /
        cleanup_on_failure "$temp_dir"
        return 1
    fi

    # Move to final location
    cd /
    if [[ -d /opt/beef ]]; then
        echo "[INFO] Removing existing /opt/beef" >> "${RUN_LOG}"
        rm -rf /opt/beef
    fi

    if ! mv "$temp_dir" /opt/beef 2>>"${RUN_LOG}"; then
        echo "[ERROR] Failed to move BeEF to /opt/beef" >> "${RUN_LOG}"
        cleanup_on_failure "$temp_dir"
        return 1
    fi

    # Verify installation
    verify_binary beef-xss || {
        echo "[WARN] beef-xss binary not found, check /opt/beef/beef" >> "${RUN_LOG}"
    }

    return 0
}
