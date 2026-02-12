#!/usr/bin/env bash
register_tool "gobuster" "Gobuster" "Web App Testing" "gobuster" "gobuster" \
    "Fast directory/file brute-forcer written in Go. Enumerates URIs, DNS subdomains, virtual host names, and S3 buckets with high concurrency."
install_gobuster() {
    echo "[INFO] Attempting to install Gobuster via apt..." >> "${RUN_LOG}"

    # Try distribution package first
    if apt-get install -y gobuster >> "${RUN_LOG}" 2>&1; then
        verify_binary gobuster && return 0
    fi

    # If apt fails, try go install
    echo "[INFO] apt installation failed, attempting go installation" >> "${RUN_LOG}"

    # Install via go
    safe_go_install "github.com/OJ/gobuster/v3@latest" || return 1

    # Verify installation
    verify_binary gobuster || return 1

    return 0
}
