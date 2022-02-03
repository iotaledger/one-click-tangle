#!/bin/bash

# Script to deploy a new Hornet Chrysalis Node on Kubernetes
# hornet.sh deploy .- Deploys a new Hornet Node on the cluster
# hornet.sh scale .- Scales Hornet
# hornet.sh undeploy .- Undeploys the Hornet Node

set -e

help () {
  echo "usage: hornet-k8s.sh [deploy|scale|update|undeploy]"
  echo "Parameter: NAMESPACE=<Kubernetes Namespace>"
  echo "Parameter: INSTANCES=<Number of Instances>"
  echo "Parameter: PEER=<multiPeerAddress>"
  echo "Parameter: INGRESS_CLASS=<IngressClass: one of ['nginx', 'gce', 'alb']>"
}

##### Command line parameter processing

command="$1"
peer="$PEER"
namespace="$NAMESPACE"
instances="$INSTANCES"
ingress_class="$INGRESS_CLASS"

if [ -z "$namespace" ]; then
    namespace="tangle"
fi

if [ -z "$instances" ]; then
    instances=1
fi

if [ -z "$ingress_class" ]; then
    ingress_class="nginx"
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

hornet_base_dir="../hornet-mainnet"

cp $hornet_base_dir/config-template/profiles.json config/profiles.json
cp $hornet_base_dir/config-template/config-template.json config/config-template.json
cp $hornet_base_dir/config-template/peering-template.json config/peering.json

chmod +x $hornet_base_dir/utils.sh
source $hornet_base_dir/utils.sh

createSecret () {
    # We remove the Dashboard secret from the config
    cat config/config-template.json \
    | jq 'del(.dashboard.auth.passwordHash) | del(.dashboard.auth.passwordSalt)' - \
    > config/config.json

    # Now these secrets are stored on a Secret
    dashboard_hash=$(cat config/config-template.json | jq -r '.dashboard.auth.passwordHash' -)
    dashboard_salt=$(cat config/config-template.json | jq -r '.dashboard.auth.passwordSalt'  -)

    rm config/config-template.json
    
    kubectl  -n $namespace create secret generic hornet-secret --from-literal='DASHBOARD_AUTH_PASSWORDHASH='"$dashboard_hash" \
    --from-literal='DASHBOARD_AUTH_PASSWORDSALT='"$dashboard_salt" --dry-run=client -o yaml | kubectl apply -f -

    private_key=$(openssl genpkey -algorithm ed25519)
    # Secret with the Private Key of the Node is also created
    kubectl -n $namespace create secret generic hornet-private-key --from-literal='private_key='"$private_key" --dry-run=client -o yaml | kubectl apply -f -
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
        kubectl -n $namespace delete service hornet-"$i"
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

    # Ingress class is established
    sed -i 's/\(kubernetes.io\/ingress.class\)\(.*\)/\1: '$ingress_class'/g' hornet-ingress.yaml
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
    kubectl delete -n $namespace secret hornet-secret
    kubectl delete -n $namespace secret hornet-private-key
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
  *)
	echo "Command not Found."
	help
	exit 127;
	;;
esac
