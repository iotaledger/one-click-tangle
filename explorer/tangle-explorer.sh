#!/bin/bash

# Script to deploy a Tangle Explorer component
# tangle-explorer.sh install .- Installs a new Tangle Exlorer
# tangle-explorer.sh start   .- Starts a new Tangle Exlorer
# tangle-explorer.sh update  .- Updates the Tangle Exlorer
# tangle-explorer.sh stop    .- Stops the Tangle Exlorer

set -e

help () {
  echo "usage: tangle-explorer.sh [install|start|stop|update] [json-file-with-network-details.json] or [private-tangle-install-folder]"
}

if [ $#  -lt 1 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

### Initialization code

EXPLORER_SRC=./explorer-src
APP_DATA=./application-data

command="$1"
network_file="$2"
is_config_folder=false

DEFAULT_NETWORK_FILE="config/private-network.json"

if [ "$command" == "install" ]; then
  if [ $# -lt 2 ]; then
    network_file="$DEFAULT_NETWORK_FILE"
  fi
fi

# Obtaining the source of the Explorer
if ! [ -d $network_file ]; then
  if ! [ -f $network_file ]; then
    echo "The IOTA network definition file or private tangle installation folder does not exist"
    exit 1
  fi
else 
  is_config_folder=true
  folder_config="$2/config"
  # The copy process will leave the network configuration under this file
  network_file="./my-network.json"
fi

###################

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

# Builds the network configuration file 
# in case only a folder with configuration files is given
buildConfig() {
  echo "Config"
  
  echo $(cat $folder_config/../coo-milestones-public-key.txt)
  cp ./config/private-network.json ./my-network.json

  # Set the Coordinator Address
  sed -i 's/"coordinatorAddress": \("\).*\("\)/"coordinatorAddress": \1'$(cat $folder_config/../coo-milestones-public-key.txt)'\2/g' ./my-network.json

  # Set in the Front-End App configuration the API endpoint
  sed -i 's/"apiEndpoint": \("\).*\("\)/"apiEndpoint": \1http:\/\/localhost:4000\2/g' ./config/webapp.config.local.json
}

# Copies the configuration
copyConfig () {
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
  # We need to create network it will fail if it does exist
  set +e
  docker network create private-tangle 2> /dev/null
  set -e

  clean

  git clone https://github.com/iotaledger/explorer $EXPLORER_SRC

  # We stop container after having source code available otherwise docker-compose would fail
  stopContainers

  # If the input parameter is a folder with config then we need to build it
  if [ "$is_config_folder" = true ]; then
    buildConfig
  fi

  copyConfig
}

startExplorer () {
  if ! [ -d "$EXPLORER_SRC" ]; then
    echo "Install the Tangle explorer first with './tangle-explorer.sh install'"
    exit 129
  fi

  # Running the Explorer API
  docker-compose --log-level ERROR up -d  --build
}

stopExplorer () {
  stopContainers
}

updateExplorer () {
  if ! [ -d "$EXPLORER_SRC" ]; then
    echo "Install the Tangle explorer first with './tangle-explorer.sh install'"
    exit 129
  fi

  stopExplorer

  cd $EXPLORER_SRC
  git pull

  startExplorer
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
  "update")
		updateExplorer
		;;
  *)
		echo "Command not Found."
		help
		exit 127;
		;;
esac
