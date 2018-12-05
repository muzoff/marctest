#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='marcoin.conf'
CONFIGFOLDER='/root/.marcoin'
COIN_DAEMON='marcoind'
COIN_CLI='marcoin-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/muzoff/marctest/raw/master/marcoin-ubuntu.tar.gz'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='marcoin'
COIN_PORT=44004
RPC_PORT=44005

function download_node() {
  echo -e "Prepare to download ${GREEN}$COIN_NAME${NC}."
  cd $TMP_FOLDER >/dev/null 2>&1
  wget -q $COIN_TGZ
  chmod 755 $COIN_ZIP
  tar -xvzf $COIN_ZIP >/dev/null 2>&1
  cp marcoin* $COIN_PATH
  chmod 755 /usr/local/bin/*
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
}

function update_node() {
  echo -e "Checking if ${RED}$COIN_NAME${NC} is already installed and running the lastest version."
  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service >/dev/null 2>&1
  sleep 10
  apt -y install jq >/dev/null 2>&1
  PROTOCOL_VERSION=$($COIN_PATH$COIN_CLI getinfo 2>/dev/null| jq .protocolversion)
  echo $
  if [[ "$PROTOCOL_VERSION" -eq 70914 ]]
  then
    echo -e "${RED}$COIN_NAME${NC} is already installed and running the lastest version."
    exit 0
  elif [[ "$PROTOCOL_VERSION" -eq 70913 ]]
  then
    echo -e "You are not running the latest version, sit tight while the update is taking place."
    systemctl stop $COIN_NAME.service >/dev/null 2>&1
    $COIN_PATH$COIN_CLI stop >/dev/null 2>&1
    sleep 10 >/dev/null 2>&1
    rm $COIN_PATH$COIN_DAEMON $COIN_PATH$COIN_CLI >/dev/null 2>&1
    download_node
    configure_systemd
    echo -e "${RED}$COIN_NAME${NC} updated to the latest version. Please make sure the Windows/Mac wallet is also updated."
    exit 0
  else
    echo -e "${RED}No $COIN_NAME${NC} installation detected. Continue with the normal installation"
  fi
}

function configure_systemd() {
  systemctl daemon-reload
  systemctl start $COIN_NAME.service >/dev/null 2>&1

}

##### Main #####
clear

update_node
