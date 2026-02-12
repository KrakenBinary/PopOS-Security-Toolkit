#!/usr/bin/env bash
register_tool "beef" "BeEF" "Exploitation" "beef-xss" "beef-xss" \
    "Browser Exploitation Framework focusing on web browser vulnerabilities. Hooks browsers and uses them as beachheads for directed command modules and client-side attack vectors."
install_beef() {
    apt-get install -y beef-xss 2>/dev/null || {
        log_msg "yellow" "  apt unavailable, trying git install..."
        apt-get install -y ruby ruby-dev build-essential git
        cd /opt && git clone https://github.com/beefproject/beef.git 2>/dev/null && cd beef && ./install
    }
}
