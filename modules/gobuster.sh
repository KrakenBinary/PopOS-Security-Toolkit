#!/usr/bin/env bash
register_tool "gobuster" "Gobuster" "Web App Testing" "gobuster" "gobuster" \
    "Fast directory/file brute-forcer written in Go. Enumerates URIs, DNS subdomains, virtual host names, and S3 buckets with high concurrency."
install_gobuster() { apt-get install -y gobuster 2>/dev/null || go install github.com/OJ/gobuster/v3@latest 2>/dev/null; }
