#!/bin/bash 

# General bootstrap script

# Detects the platform downloads the latest bootstrap from Github
# And executes it
# For the time being only the Linux AWS is supported

if [ -f ./bootstrap-amazonlinux.sh ]; then
  rm -f ./bootstrap-amazonlinux.sh
fi

wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/master/bootstrap/parameters.sh
wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/master/bootstrap/bootstrap-amazonlinux.sh

chmod +x ./parameters.sh
chmod +x ./bootstrap-amazonlinux.sh

source ./parameters.sh
nohup ./bootstrap-amazonlinux.sh &
