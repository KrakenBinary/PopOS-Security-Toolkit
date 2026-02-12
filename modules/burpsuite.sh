#!/usr/bin/env bash
register_tool "burpsuite" "Burp Suite" "Web App Testing" "burpsuite" "burpsuite" \
    "Integrated platform for web application security testing. Intercepting proxy, crawler, scanner, intruder, repeater, and extensible plugins. Community Edition is free."
install_burpsuite() {
    echo "[INFO] Attempting to install Burp Suite via snap..." >> "${RUN_LOG}"

    # Try snap installation
    safe_snap_install burpsuite || {
        echo "[WARN] Snap installation failed" >> "${RUN_LOG}"
        echo "[INFO] Burp Suite may require manual download from:" >> "${RUN_LOG}"
        echo "[INFO] https://portswigger.net/burp/releases" >> "${RUN_LOG}"
        return 1
    }

    verify_binary burpsuite || return 1
    return 0
}

uninstall_burpsuite() {
    echo "[INFO] Removing Burp Suite via snap..." >> "${RUN_LOG}"
    snap remove burpsuite >> "${RUN_LOG}" 2>&1
    return 0
}
