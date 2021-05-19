#!/bin/bash

# Script to run a new Private Tangle
# private_tangle.sh install .- Installs a new Private Tangle
# private_tangle.sh start   .- Starts a new Private Tangle
# private_tangle.sh update  .- Updates the Private Tangle
# private_tangle.sh stop    .- Stops the Tangle

set -e

help () {
  echo "usage: private-tangle.sh [start|stop|update|install]"
}

if [ $#  -lt 1 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

command="$1"

ip_address=$(echo $(dig +short myip.opendns.com @resolver1.opendns.com))


clean () {
  # TODO: Differentiate between start, restart and remove
  stopContainers

  # We need sudo here as the files are going to be owned by the hornet user
  if [ -f ./db/private-tangle/coordinator.state ]; then
    sudo rm ./db/private-tangle/coordinator.state
  fi

  if [ -d ./db/private-tangle/coo.db ]; then
    sudo rm -Rf ./db/private-tangle/coo.db/*
  fi

  if [ -d ./db/private-tangle/node1.db ]; then
    sudo rm -Rf ./db/private-tangle/node1.db/*
  fi

  if [ -d ./db/private-tangle/spammer.db ]; then
    sudo rm -Rf ./db/private-tangle/spammer.db/*
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
  ## Directories for the Tangle DB files
  if ! [ -d ./db ]; then
    mkdir ./db
  fi

  if ! [ -d ./db/private-tangle ]; then
    mkdir ./db/private-tangle
  fi

  if ! [ -d ./db/private-tangle/coo.db ]; then
    mkdir ./db/private-tangle/coo.db
  fi

  if ! [ -d ./db/private-tangle/spammer.db ]; then
    mkdir ./db/private-tangle/spammer.db
  fi

  if ! [ -d ./db/private-tangle/node1.db ]; then
    mkdir ./db/private-tangle/node1.db
  fi

  # Logs
  if ! [ -d ./logs ]; then
    mkdir ./logs
  fi

  # Snapshots
  if ! [ -d ./snapshots ]; then
    mkdir ./snapshots
  fi

  if ! [ -d ./snapshots/private-tangle ]; then
    mkdir ./snapshots/private-tangle
  fi

  # P2P
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

installTangle () {
  # First of all volumes have to be set up
  volumeSetup

  # TODO: In the feature differentitate between "start", "stop", "remove"
  # And only cleaning when we want to really remove all previous state
  clean

  # Initial snapshot
  generateSnapshot

  # P2P identities are generated
  setupIdentities

  # Peering of the nodes is configured
  setupPeering

  setupCoordinator

  # Run the coordinator
  docker-compose --log-level ERROR up -d coo

  # Run the spammer
  docker-compose --log-level ERROR up -d spammer

  # Run a regular node 
  docker-compose --log-level ERROR up -d node
}

### 
### Generates the initial snapshot
### 
generateSnapshot () {
  echo "Generating an initial snapshot..."
    # First a key pair is generated
  docker-compose run --rm node hornet tool ed25519key > key-pair.txt

  # Extract the public key use to generate the address
  local public_key="$(getPublicKey key-pair.txt)"

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

# Extracts the public key from a key pair
getPublicKey () {
  echo $(cat "$1" | tail -1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
}

# Extracts the private key from a key pair
getPrivateKey () {
  echo $(cat "$1" | head -n 1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
}

###
### Sets the Coordinator up by creating a key pair
setupCoordinator () {
  local coo_key_pair_file=coo-milestones-key-pair.txt

  docker-compose run --rm node hornet tool ed25519key > "$coo_key_pair_file"
  # Private Key is exported as it is needed to run the Coordinator
  export COO_PRV_KEYS="$(getPrivateKey $coo_key_pair_file)"

  local coo_public_key="$(getPublicKey $coo_key_pair_file)"

  setCooPublicKey "$coo_public_key" config/config-coo.json
  setCooPublicKey "$coo_public_key" config/config-node.json
  setCooPublicKey "$coo_public_key" config/config-spammer.json
}

setCooPublicKey () {
  local public_key="$1"
  sed -i 's/"key": ".*"/"key": "'$public_key'"/g' "$2"
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
        "multiAddress": "/dns/$peerName1/tcp/15600/p2p/$peerID1"
      },
      {
        "alias": "$peerName2",
        "multiAddress": "/dns/$peerName2/tcp/15600/p2p/$peerID2"
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

  setupPeerIdentity "node1" "$node1_peerID" "spammer" "$spammer_peerID" config/peering-coo.json
  setupPeerIdentity "node1" "$node1_peerID" "coo" "$coo_peerID" config/peering-spammer.json
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
	"install")
    installTangle
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
