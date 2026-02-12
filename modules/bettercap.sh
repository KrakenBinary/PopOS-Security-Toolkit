#!/usr/bin/env bash
register_tool "bettercap" "Bettercap" "Packet Analysis" "bettercap" "bettercap" \
    "Swiss Army knife for WiFi, BLE, wireless HID, and Ethernet network recon and MITM attacks. Interactive session, extensible via caplets, includes web UI."
install_bettercap() {
    echo "[INFO] Attempting to install Bettercap via apt..." >> "${RUN_LOG}"

    # Try distribution package first
    if apt-get install -y bettercap >> "${RUN_LOG}" 2>&1; then
        verify_binary bettercap && return 0
    fi

    # If apt fails, try go install
    echo "[INFO] apt installation failed, attempting go installation" >> "${RUN_LOG}"

    # Install build dependencies
    echo "[INFO] Installing build dependencies..." >> "${RUN_LOG}"
    safe_exec apt-get install -y golang git build-essential libpcap-dev libusb-1.0-0-dev libnetfilter-queue-dev || {
        echo "[ERROR] Failed to install build dependencies for Bettercap" >> "${RUN_LOG}"
        return 1
    }

    # Install via go
    safe_go_install "github.com/bettercap/bettercap@latest" || return 1

    # Verify installation
    verify_binary bettercap || return 1

    return 0
}
