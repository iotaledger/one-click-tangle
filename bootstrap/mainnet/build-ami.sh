#!/bin/bash 

# Script that builds an AWS AMI that allows to install and then run a Chrysalis Hornet Node

# All the git and Docker stuff is installed on the machine

set -e

wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/chrysalis/bootstrap/ami-install.sh
chmod +x ami-install.sh

source ./ami-install.sh

sudo wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/chrysalis/bootstrap/mainnet/install-hornet.sh -O /bin/install-hornet.sh
sudo chmod +x /bin/install-hornet.sh
