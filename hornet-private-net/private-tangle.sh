#!/bin/bash

# Script to run a new Private Tangle
# private_tangle.sh start .- Starts a new Tangle
# private_tangle.sh stop .- Stops the Tangle

set -e

help () {
  echo "usage: private_tangle [start|stop]"
}

if (( $# != 1 )); then
    echo "Illegal number of parameters"
    help
    exit 1
fi

startTangle () {
  setupCoordinator

  # Run the coordinator
  docker-compose --log-level ERROR up -d coo

  # Run the spammer
  docker-compose --log-level ERROR up -d spammer

  # Run a regular node 
  docker-compose --log-level ERROR up -d node
}

generateMerkleTree () {
  echo "Generating a new seed for the coordinator..."

  export COO_SEED=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Z9' | fold -w 81 | head -n 1)
  echo $COO_SEED > coordinator.seed 

  echo "Done. Check coordinator.seed"

  rm ./db/private-tangle/coordinator.tree 2> /dev/null
  rm ./db/private-tangle/coordinator.state 2> /dev/null

  echo "Generating Merkle Tree... This can take time ⏳ ..."

  MERKLE_TREE_ADDR=$(docker-compose run --rm -e COO_SEED=$COO_SEED coo hornet tool merkle | grep "Merkle tree root"  \
  | cut  -d ":" -f 2 - | sed "s/ //g" | tr -d "\n" | tr -d "\r")

  echo $MERKLE_TREE_ADDR > merkle-tree.addr

  echo "Done. Check merkle-tree.addr"
}

setupCoordinator () {
  generateMerkleTree

  # Copy the Merkle Tree Address to the different nodes configuration
  cp config/config-coo.json config/config-coo-tmp.json
  sed 's/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/g' config/config-coo-tmp.json > config/config-coo.json
  rm config/config-coo-tmp.json

  cp config/config-node.json config/config-node-tmp.json
  sed 's/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/g' config/config-node-tmp.json > config/config-node.json
  rm config/config-node-tmp.json

  cp config/config-spammer.json config/config-spammer-tmp.json
  sed 's/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/1' config/config-spammer-tmp.json > config/config-spammer.json
  rm config/config-spammer-tmp.json

  echo "Bootstrapping the Coordinator..."
  # Bootstrap the coordinator
  docker-compose run --rm -e COO_SEED=$COO_SEED coo hornet --cooBootstrap

  echo "Coordinator bootstrapped!"
}

stopContainers () {
  echo "Stopping containers"
	docker-compose --log-level ERROR down -v --remove-orphans
}

command="$1"
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
