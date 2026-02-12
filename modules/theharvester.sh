#!/usr/bin/env bash
register_tool "theharvester" "TheHarvester" "Reconnaissance" "theharvester" "theHarvester" \
    "Gathers emails, subdomains, hosts, employee names, open ports from public sources including search engines, PGP key servers, and the SHODAN database."
install_theharvester() {
    echo "[INFO] Attempting to install TheHarvester via apt..." >> "${RUN_LOG}"

    # Try distribution package first
    if apt-get install -y theharvester >> "${RUN_LOG}" 2>&1; then
        verify_binary theHarvester && return 0
    fi

    # If apt fails, try pip3 install
    echo "[INFO] apt installation failed, attempting pip3 installation" >> "${RUN_LOG}"

    # Install via pip3
    safe_pip3_install theHarvester || return 1

    # Verify installation
    verify_binary theHarvester || return 1

    return 0
}
