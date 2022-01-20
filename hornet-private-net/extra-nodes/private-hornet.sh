#!/bin/bash

# Script to install and deploy an additional Hornet Node to a Private Tangle

# private-hornet.sh install <node_connection_str> .- Installs a new Hornet Node on your Private Tangle
# private-hornet.sh start   <node_name> .- Starts a Hornet Node of your Private Tangle
# private-hornet.sh stop    <node_name> .- Stops a Hornet Node of your Private Tangle

# <node_connection_str> must be a colon-separated string in the form
# "node_name:api_port:peering_port:dashboard_port"
# example: "mynode:14627:15601:8082"
# if the ports are not provided the default ones (14265, 15600, 8081) will be used

# Full signature and parameters is described below: 
# private-hornet.sh [install|start|stop] <node_connection_str> <coo_public_key>? <peer_multiAdress|autopeering_multiaddress>? <snapshot_file>?


set -e

# Common utility functions
chmod +x ../utils.sh
source ../utils.sh

DEFAULT_API_PORT="14265"
DEFAULT_PEERING_PORT="15600"
DEFAULT_DASHBOARD_PORT="8081"

help () {
  echo "Installs an extra node based on Hornet version: $(cat docker-compose.yaml | grep image | cut -d : -f 3)"
  echo "usage: private-hornet.sh [install|start|stop] <node_connection_str> <coo_public_key>? <peer_multiAdress|autopeering_multiaddres>? <snapshot_file>?"
}

if [ $#  -lt 2 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

# Prepare all execution variables

command="$1"
node_details="$2"

# Split the node details string
IFS=':'
read -a node_params <<< "$node_details"

# Unless a port is specified no port will be open to the host

node_name="${node_params[0]}"
api_port="${node_params[1]}"
peering_port="${node_params[2]}"
dashboard_port="${node_params[3]}"

if [ -n "$3" ]; then
  coo_public_key="$3"
else 
  if [ -f ../coo-milestones-public-key.txt ]; then
    coo_public_key=$(cat ../coo-milestones-public-key.txt | tr -d "\n")
  else 
    echo "Please provide the coordinator's public key"
    exit 131
  fi
fi

if [ -n "$4" ]; then
  # We determine whether the address is a peer address or an entry node address
  if [[ "$4" =~ .*"\/autopeering\/".* ]]; then
    entry_node="$4"
  else 
    peer_address="$4"
  fi
else # If no peer address or autopeering entry node provided then autopeering is configured 
  if [ -f ../node-autopeering.identity.txt ]; then
    entry_node="\/dns\/node-autopeering\/udp\/14626\/autopeering\/$(getAutopeeringID ../node-autopeering.identity.txt)"
  else
    echo "Please provide a peering address or an autopeering entry node"
    exit 132
  fi
fi

if [ -n "$5" ]; then
  snapshot_file="$5"
else 
  if [ -f ../snapshots/private-tangle/full_snapshot.bin ]; then
    snapshot_file="../../../snapshots/private-tangle/full_snapshot.bin"
  else
    echo "Please provide a snapshot file of your Private Tangle"
    exit 133
  fi
fi


# Basic bootstrapping of folders for our Node

if ! [ -d ./nodes ]; then
  mkdir ./nodes
fi

if ! [ -d ./nodes/"$node_name" ]; then
  mkdir ./nodes/"$node_name"
fi

cd  ./nodes/"$node_name"

clean () {
  # We stop any container named as our node
  docker rm -f "$node_name" 2> /dev/null
  
  if [ -d ./db ]; then
    sudo rm -Rf ./db/*
  fi

  if [ -d ./p2pstore ]; then
    sudo rm -Rf ./p2pstore/*
  fi

  if [ -d ./config ]; then
    sudo rm -Rf ./config/*
  fi

  if [ -d ./snapshots/private-tangle ]; then
    sudo rm -Rf ./snapshots/private-tangle/*
  fi
}

# Sets up the necessary directories if they do not exist yet
volumeSetup () {  
  if ! [ -d ./config ]; then
    mkdir ./config
  fi

  if ! [ -d ./db ]; then
    mkdir ./db
  fi

  # P2P
  if ! [ -d ./p2pstore ]; then
    mkdir ./p2pstore
  fi

  if ! [ -d ./snapshots ]; then
    mkdir ./snapshots
  fi

  if ! [ -d ./snapshots/private-tangle ]; then
    mkdir ./snapshots/private-tangle
  fi

  ## Change permissions so that the Tangle data can be written (hornet user)
  ## TODO: Check why on MacOS this cause permission problems
  if ! [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Setting permissions for Hornet..."
    sudo chown -R 65532:65532 ./db 
    sudo chown -R 65532:65532 ./p2pstore
    sudo chown -R 65532:65532 ./snapshots
  fi 
}

bootstrapFiles () {
  cp ../../docker-compose.yaml .
  sed -i 's/node/'$node_name'/g' docker-compose.yaml

  local ports_init_str="  ports:"

  # Setting up the open ports to the host
  local ports="$ports_init_str"
  local separator="      "

  if [ -n "$api_port" ]; then
    local api_str="${separator}- \"0.0.0.0:${api_port}:${DEFAULT_API_PORT}\""
    ports="${ports}"$'\n'"${api_str}"
  fi

  if [ -n "$peering_port" ]; then
    local peering_str="${separator}- \"0.0.0.0:${peering_port}:${DEFAULT_PEERING_PORT}\""
     ports="${ports}"$'\n'"${peering_str}"
  fi

  if [ -n "$dashboard_port" ]; then
    local dashboard_str="${separator}- \"0.0.0.0:${dashboard_port}:${DEFAULT_DASHBOARD_PORT}\""
    ports="${ports}"$'\n'"${dashboard_str}"
  fi
  
  # If no ports are set we do not concat anything
  if ! [ "$ports" == "$ports_init_str" ]; then
    echo "$ports" >> docker-compose.yaml
  fi

  cp ../../../config/config-node.json ./config/config.json
  sed -i 's/node1/'$node_name'/g' ./config/config.json

  cp ../../../config/profiles.json ./config/profiles.json
  cp ../../peering.json ./config/peering.json

  if ! [[ "$OSTYPE" == "darwin"* ]]; then
    sudo cp "$snapshot_file" ./snapshots/private-tangle
    sudo chown -R 65532:65532 ./snapshots/private-tangle
  else 
    cp "$snapshot_file" ./snapshots/private-tangle
  fi
}

installNode () {
  # Ensure the script does not stop if it has not been pruned
  set +e
  docker network create "private-tangle"
  set -e

  # First of all volumes have to be set up
  volumeSetup

  # A new installation implies cleaning files
  clean

  bootstrapFiles

  # P2P identity is generated
  setupIdentity

  # Peering of the nodes is configured
  if [ -n "$peer_address" ]; then
    echo "Setting up peer node: $peer_address"
    setupPeering
  else 
    echo "Setting up autopeering entry node: $entry_node"
    setupAutopeering
  fi

  # Coordinator set up
  setupCoordinator

  # And finally containers are started
  startContainer
}

startContainer () {
  # Run a regular node 
  docker-compose --log-level ERROR up -d "$node_name"
}

###
### Sets the Coordinator address
###
setupCoordinator () {
  setCooPublicKey "$coo_public_key" "./config/config.json"
}

###
### Sets up the identities of the different nodes
###
setupIdentity () {
  generateP2PIdentity "$node_name" identity.txt
}

# Sets up the identity of the peers
setupPeerIdentity () {
  local peerName1="$1"
  local peerAddr="$2"

  local peer_conf_file="$3"

  cat <<EOF > "$peer_conf_file"
  {
    "peers": [
       {
        "alias": "$peerName1",
        "multiAddress": "$peerAddr"
      }
    ]
  } 
EOF

}

### 
### Sets the peering configuration
### 
setupPeering () {
  local node1_peerID=$(getPeerID identity.txt)

  setupPeerIdentity "peer1" "$peer_address" ./config/peering.json
  if ! [[ "$OSTYPE" == "darwin"* ]]; then
    sudo chown 65532:65532 ./config/peering.json
  fi
}

### 
### Sets the peering configuration
### 
setupAutopeering () {
  setEntryNode $entry_node ./config/config.json
}

stopContainers () {
  echo "Stopping containers..."
	docker-compose --log-level ERROR down -v --remove-orphans
}

stopNode () {
  if ! [ -f ./db/tangle/LOG ]; then
    echo "Install your Node first with './private-hornet.sh install'"
    exit 128 
  fi

  stopContainers
}

startNode () {
  if ! [ -f ./db/tangle/LOG ]; then
    echo "Install your Node first with './private-hornet.sh install'"
    exit 128 
  fi

  startContainer
}

case "${command}" in
	"help")
    help
    ;;
	"install")
    installNode
    ;;
  "start")
    startNode
    ;;
  "stop")
		stopNode
		;;
  *)
		echo "Command not Found."
		help
		exit 127;
		;;
esac
