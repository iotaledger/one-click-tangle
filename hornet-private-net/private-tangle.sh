#!/bin/bash

# Script to run a new Private Tangle
# private_tangle.sh start .- Starts a new Tangle
# private_tangle.sh stop .- Stops the Tangle

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

MERKLE_TREE_DEPTH=$2

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

# Generates a new seed ensuring last trit is always 0
generateSeed () {
  local seed=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Z9' | fold -w 80 | head -n 1)$(cat /dev/urandom | LC_ALL=C tr -dc 'A-DW-Z9' | fold -w 1 | head -n 1)
  echo "$seed"
} 

clean () {
  # TODO: Differentiate between start, restart and remove
  stopContainers

  # We need sudo here as the files are going to be owned by the hornet user
  
  if [ -f $MERKLE_TREE_LOG_FILE ]; then
    sudo rm $MERKLE_TREE_LOG_FILE
  fi

  if [ -f ./logs/coo-bootstrap.log ]; then
    sudo rm ./logs/coo-bootstrap.log
  fi

  if [ -f ./db/private-tangle/coordinator.tree ]; then
    sudo rm ./db/private-tangle/coordinator.tree
  fi

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

}

# Sets up the necessary directories if they do not exist yet
volumeSetup () {
  ## Directory for the Tangle DB files
  if ! [ -d ./db ]; then
    mkdir ./db
    mkdir ./db/private-tangle
  fi

  if ! [ -d ./logs ]; then
    mkdir ./logs
  fi

  if ! [ -d ./snapshots ]; then
    mkdir ./snapshots
    mkdir ./snapshots/private-tangle
  fi

  ## Change permissions so that the Tangle data can be written (hornet user)
  ## TODO: Check why on MacOS this cause permission problems
  sudo chown 39999:39999 db/private-tangle 

}

startTangle () {
  # First of all volumes have to be set up
  volumeSetup

  # TODO: In the feature differentitate between "start", "stop", "remove"
  # And only cleaning when we want to really remove all previous state
  clean

  # Initial address for the snapshot
  generateInitialAddress

  # Change permissions for the snapshots 
  sudo chown 39999:39999 snapshots/private-tangle

  setupCoordinator

  # We could get rid of nginx as we no longer need it. We show a message to the user. 
  # docker-compose rm -s -f nginx
  completed_message="Your Merkle Tree has already been generated.  <a href=\"http://$ip_address:8081\">Go to Hornet Node Dashboard</a>"
  echo '<!DOCTYPE html><html><body><p style="color: red;">' > $MERKLE_TREE_LOG_FILE 
  echo "$completed_message" >> $MERKLE_TREE_LOG_FILE 
  echo '</p></body></html>' >> $MERKLE_TREE_LOG_FILE

  # Run the coordinator
  docker-compose --log-level ERROR up -d coo

  # Run the spammer
  docker-compose --log-level ERROR up -d spammer

  # Run a regular node 
  docker-compose --log-level ERROR up -d node
}

generateMerkleTree () {
  echo "Generating a new seed for the coordinator..."

  # We ensure last trit is 0
  export COO_SEED=$(generateSeed)
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
      echo "You can check logs at curl http://localhost:9000/merkle-tree-generation.log.html"
      if [ "$AMAZON_LINUX" = "true" ];
        then
          echo "Your log files are also available at http://$ip_address:9000/merkle-tree-generation.log.html"
      fi
    else 
      echo "Warning: NGINX Logs Server could not be started. You can  manuallycheck logs at $MERKLE_TREE_LOG_FILE"
  fi

  echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="5"></head><body><pre>' >> $MERKLE_TREE_LOG_FILE
  docker-compose run --rm -e COO_SEED=$COO_SEED coo hornet tool merkle >> $MERKLE_TREE_LOG_FILE

  if [ $? -ne 0 ]; 
    then
      echo "Error while generating Merkle Tree. Please check logs and permissions"
      exit 127
  fi

  MERKLE_TREE_ADDR=$(cat "$MERKLE_TREE_LOG_FILE" | grep "Merkle tree root"  \
  | cut  -d ":" -f 2 - | sed "s/ //g" | tr -d "\n" | tr -d "\r")

  echo $MERKLE_TREE_ADDR > merkle-tree.addr

  echo "Done. Check merkle-tree.addr"
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

# Generates the initial address for the snapshot
generateInitialAddress () {
  echo "Generating an initial IOTA address holding all IOTAs..."

  local seed=$(generateSeed)
  echo $seed > ./utils/node.seed 

  # Now we run a tiny Node.js utility to get the first address to be on the snapshot
  docker-compose run --rm -w /usr/src/app address-generator sh -c 'npm install --prefix=/package "@iota/core" > /dev/null && node address-generator.js $(cat node.seed) 2> /dev/null > address.txt'
  echo "$(cat ./utils/address.txt);2779530283277761" > ./snapshots/private-tangle/snapshot.csv

  rm -f ./utils/address.txt
  mv ./utils/node.seed .

  echo "Initial Address generated. You can find the seed at node.seed"
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
