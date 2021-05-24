#!/bin/bash 

# General bootstrap script

# Detects the platform downloads the latest bootstrap from Github
# And executes it
# For the time being only the Linux AWS is supported

tangleExplorer () {
  cd ../explorer
  cp ./config/private-network.json ./my-network.json

  # Set the Coordinator Address
  sed -i 's/"coordinatorAddress": \("\).*\("\)/"coordinatorAddress": \1'$(cat ../hornet-private-net/coo-milestones-public-key.txt)'\2/g' ./my-network.json

  # Set in the Front-End App configuration the API endpoint
  sed -i 's/"apiEndpoint": \("\).*\("\)/"apiEndpoint": \1http:\/\/'$(echo $(dig +short myip.opendns.com @resolver1.opendns.com))':4000\2/g' ./config/webapp.config.local.json

  # Run tangle explorer installation
  ./tangle-explorer.sh install my-network.json
}

###################################################
## Script starts here. 
###################################################

wget https://raw.githubusercontent.com/iotaledger/one-click-tangle/chrysalis/bootstrap/private-net/parameters.sh
chmod +x ./parameters.sh

# First the private Tangle is installed
./private-tangle.sh install $TANGLE_COO_BOOTSTRAP_WAIT

# And then the Tangle Explorer
tangleExplorer
