#!/bin/bash 

# General bootstrap script for Chrysalis Hornet

scriptsInstall () {
  git clone https://github.com/iotaledger/one-click-tangle
  git fetch origin
  git checkout -b chrysalis origin/chrysalis

  cd one-click-tangle/hornet-mainnet
  # The script that will launch all the process
  chmod +x ./hornet.sh
}

scriptsInstall
./hornet.sh install
