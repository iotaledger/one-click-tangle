#!/bin/bash 

export TANGLE_MERKLE_TREE_DEPTH=24 # Default Merkle Tree Depth 
export TANGLE_COO_BOOTSTRAP_WAIT=60 # We will wait 1 minute for coordinator bootstrap

# General bootstrap script

# Detects the platform downloads the latest bootstrap from Github
# And executes it
# For the time being only the Linux AWS is supported

if [ -f ./bootstrap-amazonlinux.sh ]; then
  rm -f ./bootstrap-amazonlinux.sh
fi

wget https://raw.githubusercontent.com/jmcanterafonseca-iota/IOTA-Tangle-Node-Deployment/master/bootstrap/bootstrap-amazonlinux.sh

chmod +x ./bootstrap-amazonlinux.sh

source ./bootstrap-amazonlinux.sh
