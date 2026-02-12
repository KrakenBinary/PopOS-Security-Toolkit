#!/usr/bin/env bash
register_tool "wireshark" "Wireshark" "Packet Analysis" "wireshark" "wireshark" \
    "The world's foremost network protocol analyzer. Deep inspection of hundreds of protocols, live capture, offline analysis, rich VoIP analysis, and powerful display filters."
install_wireshark() {
    echo "[INFO] Installing Wireshark..." >> "${RUN_LOG}"

    # Install with non-interactive frontend
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark >> "${RUN_LOG}" 2>&1; then
        echo "[ERROR] Failed to install Wireshark" >> "${RUN_LOG}"
        return 1
    fi

    # Reconfigure to allow non-root users to capture packets
    echo "[INFO] Configuring Wireshark for non-root capture..." >> "${RUN_LOG}"
    dpkg-reconfigure -f noninteractive wireshark-common >> "${RUN_LOG}" 2>&1

    verify_binary wireshark || return 1
    return 0
}
