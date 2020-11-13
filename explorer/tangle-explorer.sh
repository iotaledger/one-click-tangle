#!/bin/bash

# Script to deploy a Tangle Explorer component

set -e

### Initialization code

EXPLORER_SRC=./explorer-src
APP_DATA=./application-data

if [ $#  -lt 1 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

command="$1"
network_file="$2"

DEFAULT_NETWORK_FILE="config/private-network.json"

if [ "$command" == "install" ]; then
  if [ $# -lt 2 ]; then
    network_file="$DEFAULT_NETWORK_FILE"
  fi
fi

# Obtaining the source of the Explorer
if ! [ -f $network_file ]; then
  echo "The IOTA network definition file does not exist"
  exit 1
fi

###################

help () {
  echo "usage: tangle-explorer.sh [install|start|stop] [json-file-with-network-details.json]"
}

clean () {
  if [ -d $EXPLORER_SRC ]; then
    rm -Rf $EXPLORER_SRC
  fi

  if [ -d $APP_DATA ]; then
    rm -Rf $APP_DATA
  fi
}

stopContainers () {
  echo "Stopping containers..."
	docker-compose --log-level ERROR down -v --remove-orphans
}


prepareConfig () {
  if ! [ -d $APP_DATA ]; then
    mkdir $APP_DATA
  fi

  if ! [ -d $APP_DATA/network ]; then
    mkdir $APP_DATA/network
  fi

  cp $network_file ./application-data/network/private-network.json

  # Configuration of the API Server
  cp config/api.config.local.json $EXPLORER_SRC/api/src/data/config.local.json

  # Configuration of the Web App
  cp config/webapp.config.local.json $EXPLORER_SRC/client/src/assets/config/config.local.json

  # TODO: Check why is it really needed
  rm $EXPLORER_SRC/client/package-lock.json
}

installExplorer () {
  clean

  git clone https://github.com/iotaledger/explorer $EXPLORER_SRC

  # We stop container after having source code available otherwise docker-compose would fail
  stopContainers

  prepareConfig
}

startExplorer () {
  # Running the Explorer API
  docker-compose --log-level ERROR up -d  --build
}

stopExplorer () {
  stopContainers
}

case "${command}" in
	"help")
    help
    ;;
	"install")
    installExplorer
    startExplorer
    ;;
  "start")
		startExplorer
		;;
  "stop")
		stopExplorer
		;;
  *)
		echo "Command not Found."
		help
		exit 127;
		;;
esac
