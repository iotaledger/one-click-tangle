#!/bin/bash

# Script to deploy a new Hornet Chrysalis Node on Kubernetes
# hornet.sh deploy .- Deploys a new Hornet Node on the cluster
# hornet.sh scale .- Scales Hornet
# hornet.sh undeploy .- Undeploys the Hornet Node
# hornet.sh update .- Updates the Hornet Node

set -e

help () {
  echo "usage: hornet-k8s.sh [deploy|scale|update|undeploy]"
  echo "Parameter: NAMESPACE=<Kubernetes Namespace>"
  echo "Parameter: INSTANCES=<Number of Instances>"
  echo "Parameter: IMAGE=<Docker Images to be used>"
  echo "Parameter: PEER=<multiPeerAddress>"
}

##### Command line parameter processing

command="$1"
peer="$PEER"
image="$IMAGE"
namespace="$NAMESPACE"
instances="$INSTANCES"

if [ -z "$namespace" ]; then
    namespace="tangle"
fi

if [ -z "$instances" ]; then
    instances=1
fi

if [ $#  -lt 1 ]; then
    echo "Illegal number of parameters"
    help
    exit 1
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

#####

cp ../config-template/*.json ./config
chmod +x ../utils.sh
source ../utils.sh

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
    cooSetup

    peerSetup

    # Namespace on which the node or nodes will be living
    kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -

    # Config Map is created or overewritten
    kubectl -n $namespace create configmap hornet-config --from-file=config --dry-run=client -o yaml | kubectl apply -f -

    # Service, Ingress associated and Statefulset associated
    kubectl apply -n $namespace -f hornet-rest-service.yaml
    kubectl apply -n $namespace -f hornet-service.yaml
    kubectl apply -n $namespace -f hornet.yaml
    kubectl apply -n $namespace -f hornet-ingress.yaml
}

undeployHornet () {
    kubectl delete -n $namespace -f hornet-ingress.yaml
    kubectl delete -n $namespace -f hornet-rest-service.yaml
    kubectl delete -n $namespace -f hornet-service.yaml
    kubectl delete -n $namespace -f hornet.yaml
    kubectl delete -n $namespace configmap hornet-config
}

scaleHornet () {
    kubectl scale -n $namespace statefulsets hornet-set --replicas=$instances
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
  "scale")
    scaleHornet
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
