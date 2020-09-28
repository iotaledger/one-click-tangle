#!/bin/bash

# Script to bootstrap a machone before running a Private Tangle
# 

export AMAZON_LINUX=true

# TODO: Remove this when a new version of bootstrap.sh is submitted to the Marketplace
parameterSetup () {
  if [ -z "$TANGLE_MERKLE_TREE_DEPTH" ]; then
    export TANGLE_MERKLE_TREE_DEPTH=24 # Default Merkle Tree Depth 
    export TANGLE_COO_BOOTSTRAP_WAIT=60 # We will wait 1 minute for coordinator bootstrap
  fi
}

set -e

gitInstall () {
  echo "Installing git ..."
  sudo yum update -y
  sudo yum install git -y
}

dockerInstall () {
  echo "Installing docker ..."

  sudo yum install docker -y
  # Add the ec2-user to the docker group so you can execute Docker commands without using sudo.
  sudo gpasswd -a ec2-user docker

  sudo systemctl enable docker
 
  ## Start docker service
  sudo systemctl start docker

  ## Install docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
}

scriptsInstall () {
  git clone https://github.com/jmcanterafonseca-iota/IOTA-Tangle-Node-Deployment

  cd IOTA-Tangle-Node-Deployment/hornet-private-net
  # The script that will launch all the process
  chmod +x ./private-tangle.sh
}

# Sets up the necessary directories if they do not exist yet
volumeSetup () {
  ## Directory for the Tangle DB files
  if ! [ -d ./db ]; then
    mkdir ./db
    mkdir ./db/private-tangle
  fi

  if ! [ -d ./logs ]; then
    mkdir ./logs
  fi

  if ! [ -d ./snapshots ]; then
    mkdir ./snapshots
    mkdir ./snapshots/private-tangle
  fi

  ## Change permissions so that the Tangle data can be written (hornet user)
  sudo chown 39999:39999 db/private-tangle 
}

prepareEnv () {
  parameterSetup
  gitInstall
  dockerInstall
  scriptsInstall
}

bootstrap () {
  prepareEnv

  volumeSetup

  # echo "Please enter Merkle Tree Depth"

  # Using this hack we allow to execute docker without logging out
  sg docker -c 'sg ec2-user -c "./private-tangle.sh start $TANGLE_MERKLE_TREE_DEPTH $TANGLE_COO_BOOTSTRAP_WAIT"'
}

###################################################
## Script starts here. 
###################################################

bootstrap
