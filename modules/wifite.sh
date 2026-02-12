#!/usr/bin/env bash
register_tool "wifite" "Wifite" "Wireless Attacks" "wifite" "wifite" \
    "Automated wireless attack tool that streamlines auditing WEP, WPA, and WPS encrypted networks. Minimal user interaction, sorts targets by signal strength."
install_wifite() { apt-get install -y wifite 2>/dev/null || pip3 install wifite 2>/dev/null; }
