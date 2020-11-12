#!/bin/bash

# Script to deploy a Tangle Explorer component

set -e

help () {
  echo "usage: tangle-explorer.sh [start|stop] [json-file-with-network-details.json]"
}

clean () {
  stopContainers

  if [ -d ./tangle-explorer ]; then
    rm -Rf ./tangle-explorer
  fi
}

stopContainers () {
  echo "Stopping containers..."
	docker-compose --log-level ERROR down -v --remove-orphans
}

if [ $#  -lt 1 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

command="$1"
network_file="$2"

DEFAULT_NETWORK_FILE="config/private-network-default.json"

if [ "$command" == "start" ]; then
  if [ $# -lt 2 ]; then
    network_file="$DEFAULT_NETWORK_FILE"
  fi
fi

# Obtaining the source of the Explorer
if ! [ -f $network_file]; then
  echo "The IOTA network definition file does not exist"
  exit 1
fi

startExplorer () {
  clean

  git clone https://github.com/iotaledger/explorer tangle-explorer

  cd tangle-explorer

  if ! [ -d ./network-data ]; then
    mkdir ./network-data
  fi

  cp $network_file ./network-data/private-network.json

  # Compile the Web App code. This will leave the compiled JS in the dist folder
  docker-compose run --rm -w /usr/src/app webapp-compiler sh -c 'npm install --prefix=/package > /dev/null && npm run build 2> /dev/null'

  # Running the Explorer API
  docker-compose --log-level ERROR up -d explorer-api

  # Running the WebApp (NGINX using content generated)
  docker-compose --log-level ERROR up -d explorer-webapp 
}

case "${command}" in
	"help")
    help
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
