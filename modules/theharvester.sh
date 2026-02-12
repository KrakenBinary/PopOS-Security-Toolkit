#!/usr/bin/env bash
register_tool "theharvester" "TheHarvester" "Reconnaissance" "theharvester" "theHarvester" \
    "Gathers emails, subdomains, hosts, employee names, open ports from public sources including search engines, PGP key servers, and the SHODAN database."
install_theharvester() { apt-get install -y theharvester 2>/dev/null || pip3 install theHarvester 2>/dev/null; }
