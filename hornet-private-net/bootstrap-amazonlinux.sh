#!/bin/bash

# Script to bootstrap a machone before running a Private Tangle
# 

set -e

gitInstall () {
  echo "Installing git ..."
  sudo yum update -y
  sudo yum install git -y
}

dockerInstall() {
  echo "Installing docker ..."

  sudo yum install docker -y
  # Add the ec2-user to the docker group so you can execute Docker commands without using sudo.
  ## Exit the terminal and re-login to make the change effective
  sudo usermod -a -G docker ec2-user

  sudo systemctl enable docker
 
  ## Start docker service
  sudo systemctl start docker

  ## Install docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
}

scriptsInstall() {
  git clone https://github.com/jmcanterafonseca-iota/IOTA-Tangle-Node-Deployment
  
  cd IOTA-Tangle-Node-Deployment/hornet-private-net
  # The script that will launch all the process
  chmod +x ./private-tangle.sh
}

volumeSetup() {
  ## Directory for the Tangle DB files
  mkdir ./db
  mkdir ./db/private-tangle

  mkdir ./logs

  mkdir ./snapshots
  mkdir ./snapshots/private-tangle

  ## Change permissions so that the Tangle data can be written
  sudo chown 39999:39999 db/private-tangle 
}

prepareEnv() {
  gitInstall
  dockerInstall
  scriptsInstall
  volumeSetup
}

## Script starts here
prepareEnv
# echo "Please enter Merkle Tree Depth"
source ./private-tangle.sh start 20
