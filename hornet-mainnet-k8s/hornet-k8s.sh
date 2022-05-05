#!/bin/bash

# Script to deploy a new Hornet Chrysalis Node on Kubernetes
# hornet.sh deploy .- Deploys a new Hornet Node on the cluster
# hornet.sh scale .- Scales Hornet
# hornet.sh undeploy .- Undeploys the Hornet Node

set -e

help () {
  echo "usage: hornet-k8s.sh [deploy|scale|undeploy]"
  echo "Parameter: NAMESPACE=<Kubernetes Namespace>"
  echo "Parameter: INSTANCES=<Number of Instances>"
  echo "Parameter: PEER=<multiPeerAddress>"
  echo "Parameter: INGRESS_CLASS=<IngressClass: one of ['nginx', 'gce', 'alb']>"
}

##### Command line parameter processing

command="$1"
peer="$PEER"
namespace="$NAMESPACE"
declare -i instances=1
declare -i replicas=0
ingress_class="$INGRESS_CLASS"

configmap_name="hornet-config"

if [ -z "$namespace" ]; then
    namespace="tangle"
fi

if ! [ -z "$INSTANCES" ]; then
    instances=$INSTANCES
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

if ! [ -x "$(command -v openssl)" ]; then
    echo "openssl not installed"
    echo "You can install it following instructions at https://formulae.brew.sh/formula/openssl@1.1"
    exit 156
fi

if ! [ -x "$(command -v kubectl)" ]; then
    echo "kubectl utility not installed"
    echo "You can install it following the instructions at https://kubernetes.io/docs/tasks/tools/"
    exit 158
fi

#####

hornet_base_dir="../hornet-mainnet"

chmod +x $hornet_base_dir/utils.sh
source $hornet_base_dir/utils.sh

# P2P identities of the nodes
declare -a p2p_identities

createSecret () {
    # We remove the Dashboard secret from the config
    cat config/config-template.json \
    | jq 'del(.dashboard.auth.passwordHash) | del(.dashboard.auth.passwordSalt)' - \
    > config/config.json

    # Now these secrets are stored on a Secret
    local dashboard_hash=$(cat config/config-template.json | jq -r '.dashboard.auth.passwordHash' -)
    local dashboard_salt=$(cat config/config-template.json | jq -r '.dashboard.auth.passwordSalt'  -)

    rm config/config-template.json
    
    kubectl  -n $namespace create secret generic hornet-secret --from-literal='DASHBOARD_AUTH_PASSWORDHASH='"$dashboard_hash" \
    --from-literal='DASHBOARD_AUTH_PASSWORDSALT='"$dashboard_salt" --dry-run=client -o yaml | kubectl apply -f -
}

createPrivateKeys () {
    mkdir -p config/keys

    # for each of the instances a new secret with private key is created
    for  (( i=0; i<instances; i++ ))
    do
        # If they key already exists we just reuse it (normally during an scale operation)
        if ! [ -f config/keys/identity-$i.key ]; then
            # If the proper version of OpenSSL is not installed this has highly chances fo failure
            set +e
            openssl genpkey -algorithm ed25519 -out config/keys/identity.key
            if ! [ $? -eq 0 ]; then
                echo "Cannot generate a private key for your node. Please check your OpenSSL version"
                exit -100
            fi
            set -e
        else
            mv config/keys/identity-$i.key config/keys/identity.key 
        fi

        # We need to store this to later perform the Node peering
        p2p_identity=$(docker run -it -v "$PWD/config/keys:/p2pstore/" gohornet/hornet:1.2.1 tool p2pidentity-extract --databasePath /p2pstore |\
          tail -n 1 | cut -f 2 -d : | tr -d '\r\n ')          
        p2p_identities[i]="$p2p_identity"

        mv config/keys/identity.key config/keys/identity-$i.key
    done

    # Secret with the Private Key of the Node is also created
    kubectl -n $namespace create secret generic hornet-private-key --from-file=config/keys --dry-run=client -o yaml | kubectl apply -f -
}

createStatefulSet () {
    cat hornet.yaml | kubectl patch -n $namespace --dry-run=client -p \
    $'spec:\n  replicas: '"$instances" -o yaml -f - \
    | kubectl apply -f -
}

createNodePortServices () {
    for  (( i=replicas; i<instances; i++ ))
    do
        cat hornet-service.yaml | kubectl patch --dry-run=client -p \
        $'metadata:\n  namespace: '"$namespace" -o yaml -f - \
        | kubectl patch --dry-run=client -p $'metadata:\n  name: 'hornet-"$i" -o yaml -f - \
        | kubectl patch --dry-run=client -p \
        '{"spec":{"selector":{"statefulset.kubernetes.io/pod-name": '\"hornet-set-"$i"\"'}}}' -o yaml -f - \
        | kubectl apply -f -
    done
}

# Peers the nodes between them
peerNodes () {
    declare -i start=1
    if [ $replicas -gt 0 ]; then
        start=replicas
    fi

    for  (( i=start; i<instances; i++ ))
    do
       peerHost=hornet-$((i-1))
       peerAddr=${p2p_identities[$((i-1))]}
       alias="$peerHost"
       multiAddress="/dns/$peerHost/tcp/15600/p2p/$peerAddr"
       cat $hornet_base_dir/config-template/peering-template.json | \
       jq '.' | jq '.peers |= . + [{ "alias": "'$alias'", "multiAddress": "'$multiAddress'"}]' > config/peering-$i.json
    done

    if [ -f config/peering.json ]; then
        # Peering config of the first node
        mv config/peering.json config/peering-0.json
    fi

    echo "Nodes peered"
}

deleteNodePortServices () {
    for  (( i=0; i<$instances; i++ ))
    do
        kubectl -n $namespace delete service hornet-"$i"
    done
}

initialise () {
    # Resetting previous state
    rm -Rf config/keys/*
    rm -Rf config/peering*.json

    cp $hornet_base_dir/config-template/profiles.json config/profiles.json
    cp $hornet_base_dir/config-template/config-template.json config/config-template.json
    cp $hornet_base_dir/config-template/peering-template.json config/peering.json
}

deployHornet () {
    initialise

    # Namespace on which the node or nodes will be living
    kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -

    createSecret
    createPrivateKeys

    cooSetup

    peerSetup

    # Now we peer the nodes among themselves
    peerNodes

    # Config Map is created or overwritten
    kubectl -n $namespace create configmap $configmap_name --from-file=config --dry-run=client -o yaml | kubectl apply -f -

    # Service, Ingress associated and Statefulset associated
    kubectl apply -n $namespace -f hornet-rest-service.yaml
    createStatefulSet

    kubectl apply -n $namespace -f hornet-ingress.yaml
    kubectl annotate -f hornet-ingress.yaml -n $namespace --overwrite kubernetes.io/ingress.class=$ingress_class

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
    # In order to scale we need to check whether the set already exists
    set +e
    kubectl get statefulsets/hornet-set -n $namespace > /dev/null 2>&1
    if ! [ $? -eq 0 ]; then
        echo "Error: Statefulset 'hornet-set' does not exist on namespace '$namespace'. Deploy first"
        exit 400
    fi
    set -e

    # First we need to know whether we are upscaling or downscaling
    # If upscaling we need to generate additional secrets and additional peering configuration
    replicas=$(kubectl get statefulsets/hornet-set -n $namespace -o jsonpath='{.spec.replicas}' | tr -d '\r\n')
    if [ $instances -gt $replicas ]; then
        # We create additional secrets if needed
        createPrivateKeys
         # Now we peer the nodes among themselves
        peerNodes
    fi

    # Config Map has to be recreated so that the new peering info is provided
    kubectl -n $namespace create configmap $configmap_name --from-file=config --dry-run=client -o yaml | kubectl apply -f -

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
