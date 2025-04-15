#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/janeczku/calibre-web

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    git \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    imagemagick
msg_ok "Installed Dependencies"

msg_info "Setup Python3"
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
$STD apt-get install -y \
    python3-pip \
    pip \
    python3-irc
$STD pip install jaraco.stream
$STD pip install python-Levenshtein
$STD pip install soupsieve
$STD pip install pypdf
msg_ok "Setup Python3"

msg_info "Installing Kepubify"
mkdir -p /opt/kepubify
cd /opt/kepubify
curl -fsSLO https://github.com/pgaskin/kepubify/releases/latest/download/kepubify-linux-64bit &>/dev/null
chmod +x kepubify-linux-64bit
msg_ok "Installed Kepubify"

msg_info "Installing Calibre-Web"
mkdir -p /opt/calibre-web
$STD apt-get install -y calibre
$STD curl -fsSL https://github.com/janeczku/calibre-web/raw/master/library/metadata.db -o /opt/calibre-web/metadata.db
$STD pip install calibreweb
$STD pip install jsonschema
msg_ok "Installed Calibre-Web"

msg_info "Installing LazyLibrarian"
$STD git clone https://gitlab.com/LazyLibrarian/LazyLibrarian /opt/LazyLibrarian
cd /opt/LazyLibrarian
$STD pip install .
msg_ok "Installed LazyLibrarian"

msg_info "Creating Calibre Service"
cat <<EOF >/etc/systemd/system/cps.service
[Unit]
Description=Calibre-Web Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/calibre-web
ExecStart=/usr/local/bin/cps
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cps
msg_ok "Created Calibre Service"

msg_info "Creating LazyLibrarian Service"
cat <<EOF >/etc/systemd/system/lazylibrarian.service
[Unit]
Description=LazyLibrarian Daemon
After=syslog.target network.target
[Service]
UMask=0002
Type=simple
ExecStart=/usr/bin/python3 /opt/LazyLibrarian/LazyLibrarian.py
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q lazylibrarian
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
