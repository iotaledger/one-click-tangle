#!/bin/bash

# Script to run a new Hornet Chrysalis Node
# hornet.sh deploy .- Installs a new Hornet Node (and starts it)
# hornet.sh stop .- Scales to 0
# hornet.sh undeploy .- Undeploys the Hornet Node
# hornet.sh update .- Updates the Hornet Node

set -e

help () {
  echo "usage: hornet-k8s.sh [deploy|stop|update|undeploy] -p <peer_multiAdress> -i <docker_image>"
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

if ! [ -x "$(command -v jq)" ]; then
    echo "jq utility not installed"
    echo "You can install it following the instructions at https://stedolan.github.io/jq/download/"
    exit 156
fi

if ! [ -x "$(command -v kubectl)" ]; then
    echo "kubectl utility not installed"
    echo "You can install it following the instructions at https://kubernetes.io/docs/tasks/tools/"
    exit 158
fi

HORNET_UPSTREAM="https://raw.githubusercontent.com/gohornet/hornet/main/"

#####


# The coordinator public key ranges are obtained
cooSetup () {
    cat config-template/config.json | jq --argjson protocol \
    "$(wget $HORNET_UPSTREAM/config.json -O - -q | jq '.protocol')" \
    '. |= . + {$protocol}' > config/config.json
}

peerSetup () {
    # And now we configure our Node's peers
    cp config-template/peering.json config/peering.json
    if [ -n "$peer" ]; then
        echo "Peering with: $peer"
        # This is the case where no previous peer definition was there
        sed -i 's/\[\]/\[{"alias": "peer1","multiAddress": "'$peer'"}\]/g' config/peering.json
        # This is the case for overwriting previous peer definition
        sed -i 's/{"multiAddress":\s\+".\+"}/{"multiAddress": "'$peer'"}/g' config/peering.json
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

imageSetup () {
    # The image only is set if it is passed as parameter
    # Otherwise the image is taken from the docker-compose
    if [ -n "$image" ]; then
        echo "Using image: $image"
        sed -i 's/image: .\+/image: '$image'/g' docker-compose.yaml
    fi

    # We ensure we have the image before
    docker-compose pull hornet
}

deployHornet () {
    cp config-template/profiles.json config/profiles.json

    cooSetup

    peerSetup

    # Namespace on which the node or nodes will be living
    kubectl create namespace tangle --dry-run=client -o yaml | kubectl apply -f -

    # Config Map is created or overewritten
    kubectl -n tangle create configmap hornet-config --from-file=config --dry-run=client -o yaml | kubectl apply -f -
    # Service associated and Statefulset associated
    kubectl apply -n tangle -f k8s/hornet-service.yaml
    kubectl apply -n tangle -f k8s/hornet.yaml
}

undeployHornet () {
    kubectl delete -n tangle -f k8s/hornet-service.yaml
    kubectl delete -n tangle -f k8s/hornet.yaml
    kubectl delete -n tangle configmap hornet-config
}

######################
## Script starts here
######################
case "${command}" in
  "help")
    help
    ;;
  "deploy")
    deployHornet
    ;;
  "undeploy")
    undeployHornet
    ;;
  "update")
    updateHornet
    ;;
  *)
	echo "Command not Found."
	help
	exit 127;
	;;
esac
