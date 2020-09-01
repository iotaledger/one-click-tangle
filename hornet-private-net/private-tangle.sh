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

startTangle () {
  setupCoordinator

  sleep 3

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

  if [ -f ./db/private-tangle/coordinator.tree ]; then
    rm ./db/private-tangle/coordinator.tree
  fi

  if [ -f ./db/private-tangle/coordinator.state ]; then
    rm ./db/private-tangle/coordinator.state
  fi
  
  echo "Generating Merkle Tree... of depth ${MERKLE_TREE_DEPTH}. This can take time ⏳ ..."

    # Add the Merkle Tree Depth to the Configuration
  cp config/config-coo.json config/config-coo-tmp.json
  sed 's/"merkleTreeDepth": [[:digit:]]\+/"merkleTreeDepth": '$MERKLE_TREE_DEPTH'/g' config/config-coo-tmp.json > config/config-coo.json
  rm config/config-coo-tmp.json

  # Running NGINX Server that will allow us to check the logs

  docker-compose --log-level ERROR up -d nginx

  if [ $? -eq 0 ]; 
    then
      echo "NGINX Server up and running. You can check logs at curl http://localhost:9000/merkle-tree-generation.log.html"
    else 
      echo "Warning: NGINX Server could not be started. You can check logs at $MERKLE_TREE_LOG_FILE"
  fi

  if [ -f $MERKLE_TREE_LOG_FILE ]; then
    rm $MERKLE_TREE_LOG_FILE
  fi

  echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="30"></head><body><pre>' >> $MERKLE_TREE_LOG_FILE
  docker-compose run --rm -e COO_SEED=$COO_SEED coo hornet tool merkle >> $MERKLE_TREE_LOG_FILE

  MERKLE_TREE_ADDR=$(tail -f "$MERKLE_TREE_LOG_FILE" | grep "Merkle tree root"  \
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
  sed '0,/"address"/s/"address": \("\).*\("\)/"address": \1'$MERKLE_TREE_ADDR'\2/' config/config-spammer-tmp.json > config/config-spammer.json
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
