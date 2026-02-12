#!/usr/bin/env bash
register_tool "wifite" "Wifite" "Wireless Attacks" "wifite" "wifite" \
    "Automated wireless attack tool that streamlines auditing WEP, WPA, and WPS encrypted networks. Minimal user interaction, sorts targets by signal strength."
install_wifite() {
    echo "[INFO] Attempting to install Wifite via apt..." >> "${RUN_LOG}"

    # Try distribution package first
    if apt-get install -y wifite >> "${RUN_LOG}" 2>&1; then
        verify_binary wifite && return 0
    fi

    # If apt fails, try pip3 install
    echo "[INFO] apt installation failed, attempting pip3 installation" >> "${RUN_LOG}"

    # Install via pip3
    safe_pip3_install wifite || return 1

    # Verify installation
    verify_binary wifite || return 1

    return 0
}
