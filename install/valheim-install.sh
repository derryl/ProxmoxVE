#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: n8flx
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.satisfactorygame.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os



APP="Valheim"
APPID=896660
APP_INSTALL_DIR="/opt/valheim/server"
STEAM_SAVE_DIR="/home/steam/.config/unity3d/IronGate/Valheim"

msg_info "Installing Dependencies"
$STD apt install -y \
  lib32gcc-s1 \
  lib32stdc++6
msg_ok "Installed Dependencies"

msg_info "Creating Steam User and Application Directories"
useradd --system \
  --create-home \
  --home-dir /home/steam \
  --shell /usr/sbin/nologin \
  steam
mkdir -p /opt/valheim/server /opt/steamcmd
chown -R steam:steam /opt/valheim /opt/steamcmd /home/steam
msg_ok "Created Steam User and Application Directories"

fetch_and_deploy_from_url \
  "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
  "/opt/steamcmd"
chown -R steam:steam /opt/steamcmd

msg_info "Installing $APP Dedicated Server"
$STD runuser -u steam -- /opt/steamcmd/steamcmd.sh +login anonymous +quit || true

$STD runuser -u steam -- /opt/steamcmd/steamcmd.sh \
  +force_install_dir /opt/valheim/server \
  +login anonymous \
  +app_update 896660 validate \
  +quit
msg_ok "Installed $APP Dedicated Server"

cp /opt/valheim/server/start_server.sh /opt/valheim/server/start_valheim_custom_server.sh
chmod +x /opt/valheim/server/start_valheim_custom_server.sh
chown steam:steam /opt/valheim/server/start_valheim_custom_server.sh

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/valheim.service
[Unit]
Description=Valheim Dedicated Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=steam
Group=steam
WorkingDirectory=/opt/valheim/server
Environment=LANG=C.UTF-8
Environment=HOME=/home/steam
ExecStart=/opt/valheim/server/start_valheim_custom_server.sh -log
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=120
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now valheim
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
