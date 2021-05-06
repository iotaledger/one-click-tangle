#!/bin/bash 

# Script that builds an AWS AMI that allows to install and then run a Private Tangle

set -e

wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/chrysalis/bootstrap/ami-install.sh
chmod +x ami-install.sh

source ../ami-install.sh

wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/chrysalis/bootstrap/private-net/bootstrap.sh -O /bin/install-private-tangle.sh
chmod +x /bin/install-private-tangle.sh
