#!/bin/bash

# Script to run a new Private Tangle
# private_tangle.sh start .- Starts a new Tangle
# private_tangle.sh stop .- Stops the Tangle

set -e

help () {
  echo "usage: private_tangle [start|stop] <merkle_tree_depth>"
}

if [ $#  -lt 1 ]; then
  echo "Illegal number of parameters"
  help
  exit 1
fi

command="$1"

if [ "$command" == "start" ]; then
  if [ $# != 2 ]; then
    echo "Please provide the depth of the Merkle Tree"
    help
    exit 1
  fi
fi

MERKLE_TREE_DEPTH=$2

MERKLE_TREE_LOG_FILE=./logs/merkle-tree-generation.log.html

clean () {
  # TODO: Differentiate between start, restart and remove
  stopContainers
  
  if [ -f $MERKLE_TREE_LOG_FILE ]; then
    rm $MERKLE_TREE_LOG_FILE
  fi

  if [ -f ./db/private-tangle/coordinator.tree ]; then
    rm ./db/private-tangle/coordinator.tree
  fi

  if [ -f ./db/private-tangle/coordinator.state ]; then
    rm ./db/private-tangle/coordinator.state
  fi

  if [ -d ./db/private-tangle/coo.db ]; then
    rm -Rf ./db/private-tangle/coo.db
  fi

  if [ -d ./db/private-tangle/node.db ]; then
    rm -Rf ./db/private-tangle/node.db
  fi


  if [ -d ./db/private-tangle/spammer.db ]; then
    rm -Rf ./db/private-tangle/spammer.db
  fi

}

startTangle () {
  # TODO: In the feature differentitate between "start", "stop", "remove"
  # And only cleaning when we want to really remove all previous state
  clean

  setupCoordinator

  echo "Waiting coordinator bootstrap to stop gracefully..."
  sleep 10

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
  
  echo "Generating Merkle Tree... of depth ${MERKLE_TREE_DEPTH}. This can take time ⏳ ..."

  # TODO: Use a loop to avoid duplication Add the Merkle Tree Depth to the Configuration
  sed -i 's/"merkleTreeDepth": [[:digit:]]\+/"merkleTreeDepth": '$MERKLE_TREE_DEPTH'/g' config/config-coo.json
  # Tree Depth has to be copied to the different nodes of the network
  sed -i 's/"merkleTreeDepth": [[:digit:]]\+/"merkleTreeDepth": '$MERKLE_TREE_DEPTH'/g' config/config-node.json
  sed -i 's/"merkleTreeDepth": [[:digit:]]\+/"merkleTreeDepth": '$MERKLE_TREE_DEPTH'/g' config/config-spammer.json

  # Running NGINX Server that will allow us to check the logs
  docker-compose --log-level ERROR up -d nginx

  if [ $? -eq 0 ]; 
    then
      echo "NGINX Server up and running. You can check logs at curl http://localhost:9000/merkle-tree-generation.log.html"
    else 
      echo "Warning: NGINX Server could not be started. You can check logs at $MERKLE_TREE_LOG_FILE"
  fi

  echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="5"></head><body><pre>' >> $MERKLE_TREE_LOG_FILE
  docker-compose run --rm -e COO_SEED=$COO_SEED coo hornet tool merkle >> $MERKLE_TREE_LOG_FILE

  MERKLE_TREE_ADDR=$(cat "$MERKLE_TREE_LOG_FILE" | grep "Merkle tree root"  \
  | cut  -d ":" -f 2 - | sed "s/ //g" | tr -d "\n" | tr -d "\r")

  echo $MERKLE_TREE_ADDR > merkle-tree.addr

  docker-compose rm -s -f nginx

  echo "Done. Check merkle-tree.addr"
}

setupCoordinator () {
  generateMerkleTree

  # Copy the Merkle Tree Address to the different nodes configuration
  sed -i 's/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/g' config/config-coo.json

  sed -i 's/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/g' config/config-node.json

  sed -i '0,/"address"/s/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/' config/config-spammer.json

  # TODO: Spawn a child process so that manual intervention is avoided
  echo "Bootstrapping the Coordinator... Press Ctrl+C when first milestone is issued"
  # Bootstrap the coordinator
  docker-compose run --rm -e COO_SEED=$COO_SEED coo hornet --cooBootstrap

  echo "Coordinator bootstrapped!"
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
