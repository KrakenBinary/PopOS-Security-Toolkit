#!/usr/bin/env bash
register_tool "metasploit" "Metasploit Framework" "Exploitation" "metasploit-framework" "msfconsole" \
    "The world's most used penetration testing platform. Over 2000 exploits, 1000 auxiliary modules, and 500+ payloads for developing and executing exploit code against remote targets."
install_metasploit() {
    echo "[INFO] Attempting to install Metasploit Framework via apt..." >> "${RUN_LOG}"

    # Try distribution package first (more secure)
    if apt-get install -y metasploit-framework >> "${RUN_LOG}" 2>&1; then
        verify_binary msfconsole && return 0
    fi

    # If apt fails, try official installer (with user warning)
    echo "[WARN] apt-get installation failed, attempting official installer" >> "${RUN_LOG}"
    echo "[WARN] This will download and execute a script from GitHub" >> "${RUN_LOG}"

    local installer="/tmp/msfinstall.$$"

    # Download installer script
    safe_download \
        "https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb" \
        "$installer" || {
            echo "[ERROR] Failed to download Metasploit installer" >> "${RUN_LOG}"
            return 1
        }

    # Execute installer
    chmod 755 "$installer" || {
        echo "[ERROR] Failed to make installer executable" >> "${RUN_LOG}"
        rm -f "$installer"
        return 1
    }

    if ! "$installer" >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] Metasploit installer failed" >> "${RUN_LOG}"
        rm -f "$installer"
        return 1
    fi

    # Cleanup
    rm -f "$installer"

    # Verify installation
    verify_binary msfconsole || return 1

    return 0
}
uninstall_metasploit() {
    # Try official uninstaller first
    if [[ -f /opt/metasploit-framework/uninstall ]]; then
        echo "[INFO] Running official Metasploit uninstaller" >> "${RUN_LOG}"
        /opt/metasploit-framework/uninstall >> "${RUN_LOG}" 2>&1
        return 0
    fi

    # Fallback to apt removal
    echo "[INFO] Removing via apt-get" >> "${RUN_LOG}"
    apt-get remove -y metasploit-framework >> "${RUN_LOG}" 2>&1
    return 0
}
