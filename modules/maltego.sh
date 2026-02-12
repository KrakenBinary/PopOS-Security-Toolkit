#!/usr/bin/env bash
register_tool "maltego" "Maltego" "Reconnaissance" "maltego" "maltego" \
    "Proprietary OSINT and graphical link analysis tool for forensic and intelligence operations. Transforms discover relationships from open sources. Community Edition is free."
install_maltego() {
    log_msg "yellow" "  Maltego requires download from maltego.com"
    log_msg "cyan"   "  https://www.maltego.com/downloads/"
    snap install maltego 2>/dev/null && return 0; return 1
}
uninstall_maltego() { snap remove maltego 2>/dev/null || apt-get remove -y maltego 2>/dev/null; }
