#!/bin/bash

# Script to run a new Hornet Chrysalis Node
# hornet.sh install .- Intalls a new Hornet Node (and starts it)
# hornet.sh start   .- Starts a new Hornet Node
# hornet.sh stop    .- Stops the Hornet Node

set -e

help () {
  echo "Installs Hornet version:  $(cat docker-compose.yaml | grep image | cut -d : -f 3)"
  echo "usage: hornet.sh [install||start|stop] -p <peer_multiAdress>"
}

##### Command line parameter processing

command="$1"
peer=""

if [ $#  -lt 1 ]; then
    echo "Illegal number of parameters"
    help
    exit 1
fi

if [ "$2" == "-p" ]; then
    peer="$3"
fi

if ! [ -x "$(command -v jq)" ]; then
    echo "jq utility not installed"
    echo "You can install it following the instructions at https://stedolan.github.io/jq/download/"
    exit 156
fi

HORNET_UPSTREAM="https://raw.githubusercontent.com/gohornet/hornet/main/"

#####

clean () {
    if [ -d ./db ]; then
        echo "Cleaning up previous DB files"
        sudo rm -Rf ./db
    fi

    if [ -d ./p2pstore ]; then
        echo "Cleaning up previous P2P files"
        sudo rm -Rf ./p2pstore
    fi

    if [ -d ./snapshots ]; then
        echo "Cleaning up previous snapshot files"
        sudo rm -Rf ./snapshots
    fi
}

# Sets up the necessary directories if they do not exist yet
volumeSetup () {
    ## Directory for the Hornet DB files
    if ! [ -d ./db ]; then
        mkdir ./db
        mkdir ./db/mainnet
    fi

    if ! [ -d ./snapshots ]; then
        mkdir ./snapshots
        mkdir ./snapshots/mainnet
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

# The coordinator public key ranges are obtained
cooSetup () {
    cat config-template/config-template.json | jq --argjson protocol \
    "$(wget $HORNET_UPSTREAM/config.json -O - -q | jq '.protocol')" \
    '. |= . + {$protocol}' > config/config.json
}

peerSetup () {
    # And now we configure our Node's peers
    cp config-template/peering-template.json config/peering.json
    if [ -n "$peer" ]; then
        echo "Peering with: $peer"
        # This is the case where no previous peer definition was there
        sed -i 's/\[\]/\[{"alias": "peer1","multiAddress": "'$peer'"}\]/g' config/peering.json
    else
        echo "Configuring autopeering ..."
        autopeeringSetup
    fi 
}

autopeeringSetup () {
    # The autopeering plugin is enabled
    cat config/config.json | jq '.node.enablePlugins[.node.enablePlugins | length] |= . + "Autopeering"' > config/config-autopeering.json

    # Then the autopeering configuration is added from Hornet
    cat config/config-autopeering.json | jq --argjson autopeering \
    "$(wget $HORNET_UPSTREAM/config.json -O - -q | jq '.p2p.autopeering')" \
    '.p2p |= . + {$autopeering}' > config/config.json

    rm config/config-autopeering.json
}

startHornet () {
    if ! [ -f ./snapshots/mainnet/full_snapshot.bin ]; then
        echo "Install Hornet first with './hornet.sh install'"
        exit 129
    fi
    docker-compose --log-level ERROR up -d
}

installHornet () {
    clean

    volumeSetup

    cp config-template/profiles.json config/profiles.json

    cooSetup

    peerSetup
}

stopHornet () {
    echo "Stopping hornet..."
    docker-compose --log-level ERROR down -v --remove-orphans
}

######################
## Script starts here
######################
case "${command}" in
  "help")
    help
    ;;
  "install")
    stopHornet
    installHornet
    docker-compose --log-level ERROR up -d
    ;;
  "start")
    startHornet
    ;;
  "stop")
	stopHornet
	;;
  *)
	echo "Command not Found."
	help
	exit 127;
	;;
esac
