#!/usr/bin/env bash
register_tool "metasploit" "Metasploit Framework" "Exploitation" "metasploit-framework" "msfconsole" \
    "The world's most used penetration testing platform. Over 2000 exploits, 1000 auxiliary modules, and 500+ payloads for developing and executing exploit code against remote targets."
install_metasploit() {
    log_msg "cyan" "  Downloading Metasploit installer..."
    curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall 2>/dev/null
    chmod 755 /tmp/msfinstall && /tmp/msfinstall && rm -f /tmp/msfinstall
}
uninstall_metasploit() {
    [[ -f /opt/metasploit-framework/uninstall ]] && /opt/metasploit-framework/uninstall || apt-get remove -y metasploit-framework 2>/dev/null
}
