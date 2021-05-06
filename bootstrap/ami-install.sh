#!/bin/bash 

# Script that includes common scripts for builds an AWS AMI (Docker and Git Artefacts)

# All the git and Docker stuff is installed on the machine

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

gitInstall

dockerInstall
