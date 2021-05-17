#!/bin/bash

# Script to run a new Private Tangle
# private_tangle.sh start .- Starts a new Tangle
# private_tangle.sh stop  .- Stops the Tangle

set -e

help () {
  echo "usage: private-tangle.sh [start|stop] [merkle_tree_depth] [boostrap_wait_time]"
}

if [ $#  -lt 1 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

command="$1"

if [ "$command" == "start" ]; then
  if [ $# -lt 2 ]; then
    echo "Please provide the depth of the Merkle Tree"
    help
    exit 1
  fi
fi

#######
# TODO: Enable Hornet to notify bootstrap without relying on waiting
#######
# Obtaining the bootstrap wait time
# Six seconds wait time by default for bootstrapping coordinator
COO_BOOTSTRAP_WAIT=$3
if [ -z "$3" ]; then
  COO_BOOTSTRAP_WAIT=6
fi

MERKLE_TREE_LOG_FILE=./logs/merkle-tree-generation.log.html

ip_address=$(echo $(dig +short myip.opendns.com @resolver1.opendns.com))


clean () {
  # TODO: Differentiate between start, restart and remove
  stopContainers

  # We need sudo here as the files are going to be owned by the hornet user
  if [ -f ./db/private-tangle/coordinator.state ]; then
    sudo rm ./db/private-tangle/coordinator.state
  fi

  if [ -d ./db/private-tangle/coo.db ]; then
    sudo rm -Rf ./db/private-tangle/coo.db
  fi

  if [ -d ./db/private-tangle/node.db ]; then
    sudo rm -Rf ./db/private-tangle/node.db
  fi

  if [ -d ./db/private-tangle/spammer.db ]; then
    sudo rm -Rf ./db/private-tangle/spammer.db
  fi

  if [ -d ./p2pstore ]; then
    sudo rm -Rf ./p2pstore
  fi

  if [ -d ./snapshots/private-tangle ]; then
    sudo rm -Rf ./snapshots/private-tangle/*
  fi
}

# Sets up the necessary directories if they do not exist yet
volumeSetup () {
  ## Directory for the Tangle DB files
  if ! [ -d ./db ]; then
    mkdir ./db
  fi

  if ! [ -d ./db/private-tangle ]; then
    mkdir ./db/private-tangle
  fi

  if ! [ -d ./logs ]; then
    mkdir ./logs
  fi

  if ! [ -d ./snapshots ]; then
    mkdir ./snapshots
  fi

  if ! [ -d ./snapshots/private-tangle ]; then
    mkdir ./snapshots/private-tangle
  fi

  if ! [ -d ./p2pstore ]; then
    mkdir ./p2pstore
  fi

  ## Change permissions so that the Tangle data can be written (hornet user)
  ## TODO: Check why on MacOS this cause permission problems
  if ! [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Setting permissions for Hornet..."
    sudo chown -R 65532:65532 db 
    sudo chown -R 65532:65532 snapshots 
    sudo chown -R 65532:65532 p2pstore
  fi 
}

startTangle () {
  # First of all volumes have to be set up
  volumeSetup

  # TODO: In the feature differentitate between "start", "stop", "remove"
  # And only cleaning when we want to really remove all previous state
  clean

  # Initial snapshot
  generateSnapshot

  # P2P identities are generated
  # setupIdentities

  # Peering of the nodes is configured
  # setupPeering

  # setupCoordinator

  # Run the coordinator
  # docker-compose --log-level ERROR up -d coo

  # Run the spammer
  # docker-compose --log-level ERROR up -d spammer

  # Run a regular node 
  # docker-compose --log-level ERROR up -d node
}

### 
### Generates the initial snapshot
### 
generateSnapshot () {
  echo "Generating an initial snapshot..."
    # First a key pair is generated
  docker-compose run --rm node hornet tool ed25519key > key-pair.txt

  # Extract the public key
  public_key=$(cat key-pair.txt | tail -1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r") 
  echo "$public_key"

  # Generate the address
  docker-compose run --rm node hornet tool ed25519addr "$public_key" | cut -d ":" -f 2\
   | sed "s/ \+//g" | tr -d "\n" | tr -d "\r" > address.txt

  # Generate the snapshot
  cd snapshots/private-tangle
  docker-compose run --rm -v "$PWD:/output_dir" node hornet tool snapgen "private-tangle"\
   "$(cat ../../address.txt)" 2779530283277761 /output_dir/full_snapshot.bin

  echo "Initial Ed25519 Address generated. You can find the keys at key-pair.txt and the address at address.txt"

  cd .. && cd ..
}

setupCoordinator () {
  generateMerkleTree

  # Copy the Merkle Tree Address to the different nodes configuration
  sed -i 's/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/g' config/config-coo.json

  sed -i 's/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/g' config/config-node.json

  sed -i '0,/"address"/s/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/' config/config-spammer.json

  echo "Bootstrapping the Coordinator..."
  # Bootstrap the coordinator
  docker-compose run -d --rm -e COO_SEED=$COO_SEED coo hornet --cooBootstrap > coo.bootstrap.container

  # Waiting for coordinator bootstrap
  # We guarantee that if bootstrap has not finished yet we sleep another time 
  # for a few seconds more until bootstrap has been performed
  bootstrapped=1
  # Number of seconds waited for each tick (proportional to the depth of the Merkle Tree)
  bootstrap_tick=$COO_BOOTSTRAP_WAIT
  echo "Waiting for $bootstrap_tick seconds ... ⏳"
  sleep $bootstrap_tick
  docker logs $(cat ./coo.bootstrap.container) 2>&1 | grep "milestone issued (1)"
  bootstrapped=$?
    
  if [ $bootstrapped -eq 0 ]; then
    echo "Coordinator bootstrapped!"
    docker kill -s SIGINT $(cat ./coo.bootstrap.container)
    echo "Waiting coordinator bootstrap to stop gracefully..."
    sleep 10
    docker rm $(cat ./coo.bootstrap.container)
    rm ./coo.bootstrap.container
  else
    echo "Error. Coordinator has not been boostrapped."
    clean
    exit 127
  fi  
}

generateP2PIdentity () {
  docker-compose run --rm node hornet tool p2pidentity > $1
}

# Generates the P2P identities of the Nodes
generateP2PIdentities () {
  generateP2PIdentity node1.identity.txt
  generateP2PIdentity coo.identity.txt
  generateP2PIdentity spammer.identity.txt
}

setupIdentityPrivateKey () {
  local private_key=$(cat $1 | head -n 1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
  # and then set it on the config.json file
  sed -i 's/"identityPrivateKey": ".*"/"identityPrivateKey": "'$private_key'"/g' $2
}

###
### Sets up the identities of the different nodes
###
setupIdentities () {
  generateP2PIdentities

  setupIdentityPrivateKey node1.identity.txt config/config-node.json
  setupIdentityPrivateKey coo.identity.txt config/config-coo.json
  setupIdentityPrivateKey spammer.identity.txt config/config-spammer.json
}

# Sets up the identity of the peers
setupPeerIdentity () {
  local peerName1="$1"
  local peerID1="$2"

  local peerName2="$3"
  local peerID2="$4"

  local peer_conf_file="$5"

  cat <<EOF > "$peer_conf_file"
  {
    "peers": [
      {
        "alias": "$peerName1",
        "multiAddress": "/ip4/$peerName1/tcp/15600/p2p/$peerID1"
      },
      {
        "alias": "$peerName2",
        "multiAddress": "/ip4/$peerName2/tcp/15600/p2p/$peerID2"
      }
    ]
  } 
EOF

}

# Extracts the peerID from the identity file
getPeerID () {
  local identity_file="$1"
  echo $(cat $identity_file | tail -1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
}

### 
### Sets the peering configuration
### 
setupPeering () {
  local node1_peerID=$(getPeerID node1.identity.txt)
  local coo_peerID=$(getPeerID coo.identity.txt)
  local spammer_peerID=$(getPeerID spammer.identity.txt)

  setupPeerIdentity "node" "$node1_peerID" "spammer" "$spammer_peerID" config/peering-coo.json
  setupPeerIdentity "node" "$node1_peerID" "coo" "$coo_peerID" config/peering-spammer.json
  setupPeerIdentity "coo" "$coo_peerID" "spammer" "$spammer_peerID" config/peering-node.json
}


stopContainers () {
  echo "Stopping containers..."
	docker-compose --log-level ERROR down -v --remove-orphans
}

# TODO: start, stop, remove, resume
case "${command}" in
	"help")
    help
    ;;
	"start")
    startTangle
    ;;
  "stop")
		stopContainers
		;;
  *)
		echo "Command not Found."
		help
		exit 127;
		;;
esac
