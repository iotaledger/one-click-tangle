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

# We no longer create the P2P Identity as it is automatically
# Created by Hornet 1.0.5
peerSetup () {
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
