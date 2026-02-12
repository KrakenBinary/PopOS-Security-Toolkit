#!/usr/bin/env bash
register_tool "bettercap" "Bettercap" "Packet Analysis" "bettercap" "bettercap" \
    "Swiss Army knife for WiFi, BLE, wireless HID, and Ethernet network recon and MITM attacks. Interactive session, extensible via caplets, includes web UI."
install_bettercap() {
    apt-get install -y bettercap 2>/dev/null || {
        log_msg "yellow" "  apt unavailable, trying go install..."
        apt-get install -y golang git build-essential libpcap-dev libusb-1.0-0-dev libnetfilter-queue-dev
        go install github.com/bettercap/bettercap@latest 2>/dev/null
    }
}
