#!/usr/bin/env bash
register_tool "burpsuite" "Burp Suite" "Web App Testing" "burpsuite" "burpsuite" \
    "Integrated platform for web application security testing. Intercepting proxy, crawler, scanner, intruder, repeater, and extensible plugins. Community Edition is free."
install_burpsuite() {
    log_msg "yellow" "  Burp Suite requires manual download from PortSwigger."
    log_msg "cyan"   "  https://portswigger.net/burp/releases"
    snap install burpsuite 2>/dev/null && return 0
    return 1
}
uninstall_burpsuite() { snap remove burpsuite 2>/dev/null || return 1; }
