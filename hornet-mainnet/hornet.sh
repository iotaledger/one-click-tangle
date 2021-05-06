#!/bin/bash

# Script to run a new Hornet Chrysalis Node
# hornet.sh install .- Intalls a new Hornet Node (and starts it)
# hornet.sh start   .- Starts a new Hornet Node
# hornet.sh stop    .- Stops the Hornet Node
# hornet.sh update  .- Updates the Hornet Node

set -e

help () {
  echo "usage: hornet.sh [install|update|start|stop] -p <peer_multiAdress> -i <docker_image>"
}

##### Command line parameter processing

command="$1"
peer=""
image=""

if [ $#  -lt 1 ]; then
    echo "Illegal number of parameters"
    help
    exit 1
fi

if [ "$2" == "-p" ]; then
    peer="$3"
fi

if [ "$4" == "-p" ]; then
    peer="$5"
fi

if [ "$2" == "-i" ]; then
    image="$3"
fi

if [ "$4" == "-i" ]; then
    image="$5"
fi

#####

clean () {
    if [ -d ./db/mainnet/hornet.db ]; then
        sudo rm -Rf ./db/mainnet/hornet.db
    fi

    if [ -d ./p2pstore ]; then
        sudo rm -Rf ./p2pstore
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

peerSetup () {
    if [ -n "$peer" ]; then
        echo "Peering with: $peer"
        # This is the case where no previous peer definition was there
        sed -i 's/\[\]/\[{"alias": "peer1"},{"multiAddress": "'$peer'"}\]/g' config/peering.json
        # This is the case for overwriting previous peer definition
        sed -i 's/{"multiAddress":\s\+".\+"}/{"multiAddress": "'$peer'"}/g' config/peering.json
    fi
}

imageSetup () {
    # The image only is set if it is passed as parameter
    # Otherwise the image is taken from the docker-compose
    if [ -n "$image" ]; then
        echo "Using image: $image"
        sed -i 's/image: .\+/image: '$image'/g' docker-compose.yaml
    fi
}

startHornet () {
    docker-compose --log-level ERROR up -d
}

installHornet () {
    clean

    imageSetup
    volumeSetup

    peerSetup
}

updateHornet () {
    if ! [ -f ./p2pstore/key.pub ]; then
      echo "Previous version of Hornet not running. Use 'install' instead"
      exit 127
    fi

    imageSetup

    docker-compose pull hornet
}

stopHornet () {
    echo "Stopping hornet..."
    docker-compose --log-level ERROR down -v --remove-orphans
}

## Script starts here
case "${command}" in
  "help")
    help
    ;;
  "install")
    stopHornet
    installHornet
    startHornet
    ;;
  "update")
    stopHornet
    updateHornet
    startHornet
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
