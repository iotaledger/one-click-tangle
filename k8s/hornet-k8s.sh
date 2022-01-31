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

target=k8s

##### Command line parameter processing

command="$1"
peer="$PEER"
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

createSecret () {
    # We remove the Dashboard secret from the config
    cat ../config-template/config.json \
    | jq 'del(.dashboard.auth.passwordHash) | del(.dashboard.auth.passwordSalt)' - \
    > config/config.json

    # Now these secrets are stored on a Secret
    dashboard_hash=$(cat ../config-template/config.json | jq -r '.dashboard.auth.passwordHash' -)
    dashboard_salt=$(cat ../config-template/config.json | jq -r '.dashboard.auth.passwordSalt'  -)
    

    kubectl  -n $namespace create secret generic hornet-secret --from-literal='DASHBOARD_AUTH_PASSWORDHASH='"$dashboard_hash" \
    --from-literal='DASHBOARD_AUTH_PASSWORDSALT='"$dashboard_salt" --dry-run=client -o yaml | kubectl apply -f -
}

createStatefulSet () {
    cat hornet.yaml | kubectl patch -n $namespace --dry-run=client -p \
    $'spec:\n  replicas: '"$instances" -o yaml -f - \
    | kubectl apply -f -
}

createNodePortServices () {
    for  (( i=0; i<$instances; i++ ))
    do
        cat hornet-service.yaml | kubectl patch --dry-run=client -p \
        $'metadata:\n  namespace: '"$namespace" -o yaml -f - \
        | kubectl patch --dry-run=client -p $'metadata:\n  name: 'hornet-"$i" -o yaml -f - \
        | kubectl patch --dry-run=client -p \
        '{"spec":{"selector":{"statefulset.kubernetes.io/pod-name": '\"hornet-set-"$i"\"'}}}' -o yaml -f - \
        | kubectl apply -f -
    done
}

deleteNodePortServices () {
    for  (( i=0; i<$instances; i++ ))
    do
        kubectl -n $namespace delete service hornet-tcp-"$i"
    done
}

deployHornet () {
    # Namespace on which the node or nodes will be living
    kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -

    createSecret

    cooSetup

    peerSetup

    # Config Map is created or overewritten
    kubectl -n $namespace create configmap hornet-config --from-file=config --dry-run=client -o yaml | kubectl apply -f -

    # Service, Ingress associated and Statefulset associated
    kubectl apply -n $namespace -f hornet-rest-service.yaml
    createStatefulSet
    kubectl apply -n $namespace -f hornet-ingress.yaml

    # Finally the NodePort services are created
    createNodePortServices
}

undeployHornet () {
    kubectl delete -n $namespace -f hornet-ingress.yaml
    kubectl delete -n $namespace -f hornet-rest-service.yaml
    deleteNodePortServices
    kubectl delete -n $namespace -f hornet.yaml
    kubectl delete -n $namespace configmap hornet-config
}

scaleHornet () {
    kubectl scale -n $namespace statefulsets hornet-set --replicas=$instances
    # Finally the NodePort services are created
    createNodePortServices
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
