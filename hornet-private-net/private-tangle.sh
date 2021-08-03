#!/bin/bash

# Script to run a new Private Tangle
# private-tangle.sh install .- Installs a new Private Tangle
# private-tangle.sh start   .- Starts a new Private Tangle
# private-tangle.sh update  .- Updates the Private Tangle
# private-tangle.sh stop    .- Stops the Tangle

set -e

chmod +x ./utils.sh
source ./utils.sh

help () {
  echo "usage: private-tangle.sh [start|stop|update|install] <coo_bootstrap_wait_time?>"
}

if [ $#  -lt 1 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

command="$1"

ip_address=$(echo $(dig +short myip.opendns.com @resolver1.opendns.com))
COO_BOOTSTRAP_WAIT=10

if [ -n "$2" ]; then
  COO_BOOTSTRAP_WAIT="$2"
fi

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

  clean

  # The network is created to support the containers
  docker network prune -f
  # Ensure the script does not stop if it has not been pruned
  set +e
  docker network create "private-tangle"
  set -e

  # When we install we ensure container images are updated
  updateContainers

  # Initial snapshot
  generateSnapshot

  # P2P identities are generated
  setupIdentities

  # Peering of the nodes is configured
  setupPeering

  # Coordinator set up
  setupCoordinator

  # And finally containers are started
  startContainers
}

startContainers () {
  # Run the coordinator
  docker-compose --log-level ERROR up -d coo

  # Run the spammer
  docker-compose --log-level ERROR up -d spammer

  # Run a regular node 
  docker-compose --log-level ERROR up -d node
}

updateContainers () {
  docker-compose pull
}

updateTangle () {
  if ! [ -f ./snapshots/private-tangle/full_snapshot.bin ]; then
    echo "Install your Private Tangle first with './private-tangle.sh install'"
    exit 129
  fi

  stopContainers

  # We ensure we are now going to run with the latest Hornet version
  image="gohornet\/hornet:latest"
  sed -i 's/image: .\+/image: '$image'/g' docker-compose.yml

  updateContainers

  startTangle
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
   "$(cat ../../address.txt)" 1000000000 /output_dir/full_snapshot.bin

  echo "Initial Ed25519 Address generated. You can find the keys at key-pair.txt and the address at address.txt"

  cd .. && cd ..
}

###
### Sets the Coordinator up by creating a key pair
###
setupCoordinator () {
  local coo_key_pair_file=coo-milestones-key-pair.txt

  docker-compose run --rm node hornet tool ed25519key > "$coo_key_pair_file"
  # Private Key is exported as it is needed to run the Coordinator
  export COO_PRV_KEYS="$(getPrivateKey $coo_key_pair_file)"

  local coo_public_key="$(getPublicKey $coo_key_pair_file)"
  echo "$coo_public_key" > coo-milestones-public-key.txt

  setCooPublicKey "$coo_public_key" config/config-coo.json
  setCooPublicKey "$coo_public_key" config/config-node.json
  setCooPublicKey "$coo_public_key" config/config-spammer.json

  bootstrapCoordinator
}

# Bootstraps the coordinator
bootstrapCoordinator () {
  echo "Bootstrapping the Coordinator..."
  # Need to do it again otherwise the coo will not bootstrap
  if ! [[ "$OSTYPE" == "darwin"* ]]; then
    sudo chown -R 65532:65532 p2pstore
  fi

  # Bootstrap the coordinator
  docker-compose run -d --rm -e COO_PRV_KEYS=$COO_PRV_KEYS coo hornet --cooBootstrap --cooStartIndex 0 > coo.bootstrap.container

  # Waiting for coordinator bootstrap
  # We guarantee that if bootstrap has not finished yet we sleep another time 
  # for a few seconds more until bootstrap has been performed
  bootstrapped=1
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

# Generates the P2P identities of the Nodes
generateP2PIdentities () {
  generateP2PIdentity node node1.identity.txt
  generateP2PIdentity node coo.identity.txt
  generateP2PIdentity node spammer.identity.txt
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

  # We need this so that the peering can be properly updated
  if ! [[ "$OSTYPE" == "darwin"* ]]; then
    sudo chown 65532:65532 config/peering-node.json
  fi
}

stopContainers () {
  echo "Stopping containers..."
	docker-compose --log-level ERROR down -v --remove-orphans
}

startTangle () {
  if ! [ -f ./snapshots/private-tangle/full_snapshot.bin ]; then
    echo "Install your Private Tangle first with './private-tangle.sh install'"
    exit 128 
  fi

  export COO_PRV_KEYS="$(getPrivateKey coo-milestones-key-pair.txt)"
  startContainers
}

case "${command}" in
	"help")
    help
    ;;
	"install")
    installTangle
    ;;
  "start")
    startTangle
    ;;
  "update")
    updateTangle
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
