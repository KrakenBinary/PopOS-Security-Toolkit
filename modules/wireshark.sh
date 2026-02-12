#!/usr/bin/env bash
register_tool "wireshark" "Wireshark" "Packet Analysis" "wireshark" "wireshark" \
    "The world's foremost network protocol analyzer. Deep inspection of hundreds of protocols, live capture, offline analysis, rich VoIP analysis, and powerful display filters."
install_wireshark() { DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark; dpkg-reconfigure -f noninteractive wireshark-common 2>/dev/null; }
