#!/bin/bash 

# Script that builds an AWS AMI that allows to install and then run a Private Tangle

wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/master/bootstrap/bootstrap.sh -O /bin/install-private-tangle.sh
chmod +x /bin/install-private-tangle.sh
