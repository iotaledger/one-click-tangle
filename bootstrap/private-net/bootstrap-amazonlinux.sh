#!/bin/bash

# Script to bootstrap a machone before running a Private Tangle
# 

export AMAZON_LINUX=true

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

  echo "Installing docker-compose ..."
  ## Install docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  
  export PATH=$PATH:/usr/local/bin
}

scriptsInstall () {
  git clone https://github.com/iotaledger/one-click-tangle

  cd one-click-tangle/hornet-private-net
  # The script that will launch all the process
  chmod +x ./private-tangle.sh
  chmod +x ../explorer/tangle-explorer.sh
}

prepareEnv () {
  gitInstall
  dockerInstall
  scriptsInstall
}

bootstrap () {
  prepareEnv

  # Using this hack we allow to execute docker without logging out
  sg docker -c 'sg ec2-user -c "./private-tangle.sh start $TANGLE_MERKLE_TREE_DEPTH $TANGLE_COO_BOOTSTRAP_WAIT"'
}

tangleExplorer () {
  cd ../explorer
  cp ./config/private-network.json ./my-network.json

  # Set the Coordinator Address
  sed -i 's/"coordinatorAddress": \("\).*\("\)/"coordinatorAddress": \1'$(cat ../hornet-private-net/merkle-tree.addr)'\2/g' ./my-network.json

  # Set the coordinator.mwm
  sed -i 's/"mwm": [[:digit:]]\+/"mwm": '$(cat ../hornet-private-net/config/config-node.json | grep \"mwm\" | cut -d : -f 2 | tr -d "[ ,]")'/g' ./my-network.json

  # Set the coordinator.securityLevel
  sed -i 's/"coordinatorSecurityLevel": [:digit:]]\+/"coordinatorSecurityLevel": '$(cat ../hornet-private-net/config/config-node.json | grep \"securityLevel\" | cut -d : -f 2 | tr -d "[ ,]")'/g' ./my-network.json

  # Set in the Front-End App configuration the API endpoint
  sed -i 's/"apiEndpoint": \("\).*\("\)/"apiEndpoint": \1http:\/\/'$(echo $(dig +short myip.opendns.com @resolver1.opendns.com))':4000\2/g' ./config/webapp.config.local.json

  # Run tangle explorer installation
  sg docker -c 'sg ec2-user -c "./tangle-explorer.sh install my-network.json"'
}

###################################################
## Script starts here. 
###################################################

bootstrap
tangleExplorer
