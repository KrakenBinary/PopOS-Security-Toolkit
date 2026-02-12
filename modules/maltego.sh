#!/usr/bin/env bash
register_tool "maltego" "Maltego" "Reconnaissance" "maltego" "maltego" \
    "Proprietary OSINT and graphical link analysis tool for forensic and intelligence operations. Transforms discover relationships from open sources. Community Edition is free."
install_maltego() {
    echo "[INFO] Attempting to install Maltego via snap..." >> "${RUN_LOG}"

    # Try snap installation
    safe_snap_install maltego || {
        echo "[WARN] Snap installation failed" >> "${RUN_LOG}"
        echo "[INFO] Maltego may require manual download from:" >> "${RUN_LOG}"
        echo "[INFO] https://www.maltego.com/downloads/" >> "${RUN_LOG}"
        return 1
    }

    verify_binary maltego || return 1
    return 0
}

uninstall_maltego() {
    echo "[INFO] Attempting to remove Maltego..." >> "${RUN_LOG}"

    # Try snap first
    if command -v snap &>/dev/null && snap list maltego &>/dev/null; then
        snap remove maltego >> "${RUN_LOG}" 2>&1
        return 0
    fi

    # Fallback to apt
    apt-get remove -y maltego >> "${RUN_LOG}" 2>&1
    return 0
}
