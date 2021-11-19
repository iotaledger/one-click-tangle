#!/bin/bash

# Common utilities both used by hornet.sh and hornet-k8s.sh

HORNET_UPSTREAM="https://raw.githubusercontent.com/gohornet/hornet/main/"

# The coordinator public key ranges are obtained
cooSetup () {
    cat config/config.json | jq --argjson protocol \
    "$(wget $HORNET_UPSTREAM/config.json -O - -q | jq '.protocol')" \
    '. |= . + {$protocol}' > config/config-coo.json

    mv config/config-coo.json config/config.json
}

peerSetup () {
    # We obtain a new P2P identity for the Node
    set +e
    docker-compose run --rm hornet tool p2pidentity-gen > p2pidentity.txt 2> /dev/null
    # We try to keep backwards compatibility
    if [ $? -eq 1 ]; then
        docker-compose run --rm hornet tool p2pidentity > p2pidentity.txt
         # Now we extract the private key (only needed on Hornet versions previous to 1.0.5)
        private_key=$(cat p2pidentity.txt | head -n 1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
        # and then set it on the config.json file
        sed -i 's/"identityPrivateKey": ".*"/"identityPrivateKey": "'$private_key'"/g' config/config.json
    fi
    set -e

    # And now we configure our Node's peers
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
