#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: n8flx
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.satisfactorygame.com/

APP="Valheim"
APPID=896660
APP_INSTALL_DIR="/opt/valheim/server"
STEAM_SAVE_DIR="/home/steam/.config/unity3d/IronGate/Valheim"

var_tags="${var_tags:-gaming;server}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -x /opt/steamcmd/steamcmd.sh || ! -d $APP_INSTALL_DIR ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping $APP"
  systemctl stop valheim.service
  msg_ok "Stopped $APP"

  create_backup $STEAM_SAVE_DIR

  msg_info "Updating $APP"
  $STD runuser -u steam -- /opt/steamcmd/steamcmd.sh +login anonymous +quit || true

  if $STD runuser -u steam -- /opt/steamcmd/steamcmd.sh \
    +force_install_dir /opt/valheim/server \
    +login anonymous \
    +app_update 896660 validate \
    +quit; then
    msg_ok "Updated $APP"
  else
    restore_backup
    systemctl start valheim.service
    msg_error "Failed to update $APP"
    exit 1
  fi

  restore_backup

  msg_info "Starting $APP"
  systemctl start valheim.service
  msg_ok "Started $APP"
  msg_ok "Updated Successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Add the server in Satisfactory Server Manager:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:7777${CL}"
echo -e "${INFO}${YW} Required ports:${CL} ${BGN}7777 TCP/UDP and 8888 TCP${CL}"
