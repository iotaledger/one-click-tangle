#!/bin/bash

# Script to add a new Hornet Node to a Private Tangle

# private-hornet.sh [install|update|start|stop] <node_details> <coo_public_key>? <peer_address>? <snapshot_file>?
# node_details must be a colon-separated string including "node_name:api_port:peering_port:dashboard_port"
# example "mynode:14627:15601:8082"
# if the ports are not provided the default ones will be used

set -e

# Common utility functions
chmod +x ../utils.sh
source ../utils.sh

help () {
  echo "usage: private-hornet.sh [install|update|start|stop] <node_details> <coo_public_key>? <peer_address>? <snapshot_file>?"
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

DEFAULT_API_PORT="14265"
DEFAULT_PEERING_PORT="15600"
DEFAULT_DASHBOARD_PORT="8081"

node_name="${node_params[0]}"
api_port="${node_params[1]}"
peering_port="${node_params[2]}"
dashboard_port="${node_params[3]}"

if [ -z "$api_port" ]; then
  api_port=$DEFAULT_API_PORT
fi

if [ -z "$peering_port" ]; then
  peering_port=$DEFAULT_PEERING_PORT
fi

if [ -z "$dashboard_port" ]; then
  dashboard_port=$DEFAULT_DASHBOARD_PORT
fi

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
  peer_address="$4"
else 
  if [ -f ../node1.identity.txt ]; then
    peer_address="/dns/node1/tcp/15600/p2p/$(getPeerID ../node1.identity.txt)"
  else
    echo "Please provide a peering address"
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
  stopContainers

  if [ -d ./db ]; then
    sudo rm -Rf ./db/*
  fi

  if [ -d ./p2pstore ]; then
    sudo rm -Rf ./p2pstore
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
  cp ../../docker-compose.yml .
  sed -i 's/node/'$node_name'/g' docker-compose.yml
  sed -i 's/0.0.0.0:'$DEFAULT_API_PORT'/0.0.0.0:'$api_port'/g' docker-compose.yml
  sed -i 's/0.0.0.0:'$DEFAULT_PEERING_PORT'/0.0.0.0:'$peering_port'/g' docker-compose.yml
  sed -i 's/0.0.0.0:'$DEFAULT_DASHBOARD_PORT'/0.0.0.0:'$dashboard_port'/g' docker-compose.yml

  cp ../../../config/config-node.json ./config/config.json
  sed -i 's/node1/'$node_name'/g' ./config/config.json

  cp ../../../config/profiles.json ./config/profiles.json
  cp ../../peering.json ./config/peering.json

  cp "$snapshot_file" ./snapshots/private-tangle
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
  setupPeering

  # Coordinator set up
  setupCoordinator

  # And finally containers are started
  startContainer
}

startContainer () {
  # Run a regular node 
  docker-compose --log-level ERROR up -d "$node_name"
}

updateNode () {
  if ! [ -f ./db/LOG ]; then
    echo "Install your Node first with './private-hornet.sh install'"
    exit 129
  fi

  stopContainers

  # We ensure we are now going to run with the latest Hornet version
  image="gohornet\/hornet:latest"
  sed -i 's/image: .\+/image: gohornet\/hornet:latest/g' docker-compose.yml

  docker-compose pull

  startContainer
}


###
### Sets the Coordinator address
###
setupCoordinator () {
  echo "$(pwd)"
  setCooPublicKey "$coo_public_key" "./config/config.json"
}

###
### Sets up the identities of the different nodes
###
setupIdentity () {
  generateP2PIdentity "$node_name" identity.txt

  setupIdentityPrivateKey identity.txt "./config/config.json"
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

stopContainers () {
  echo "Stopping containers..."
	docker-compose --log-level ERROR down -v --remove-orphans
}

stopNode () {
  if ! [ -f ./db/LOG ]; then
    echo "Install your Node first with './private-hornet.sh install'"
    exit 128 
  fi

  stopContainers
}

startNode () {
  if ! [ -f ./db/LOG ]; then
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
  "update")
    updateNode
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
