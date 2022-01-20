#!/bin/bash

### Utility functions ###

# Extracts the public key from a key pair
getPublicKey () {
  cat $1 | awk -F : '{if ($1 ~ /public key/) print $2}' | sed "s/ \+//g" | tr -d "\n" | tr -d "\r"
}

# Extracts the private key from a key pair
getPrivateKey () {
  cat $1 | awk -F : '{if ($1 ~ /private key/) print $2}' | sed "s/ \+//g" | tr -d "\n" | tr -d "\r"
}

setCooPublicKey () {
  local public_key="$1"
  sed -i 's/"key": ".*"/"key": "'$public_key'"/g' "$2"
}

generateP2PIdentity () {
  docker-compose run --rm "$1" tool p2pidentity-gen > "$2"
}

setupIdentityPrivateKey () {
  local private_key=$(cat $1 | awk -F : '{if ($1 ~ /private key/) print $2}' | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
  # and then set it on the config.json file
  sed -i 's/"identityPrivateKey": ".*"/"identityPrivateKey": "'$private_key'"/g' "$2"
}

# Extracts the peerID from the identity file
getPeerID () {
  cat $1 | awk -F : '{if ($1 ~ /PeerID/) print $2}' | sed "s/ \+//g" | tr -d "\n" | tr -d "\r"
}

getAutopeeringID () {
   cat $1 | awk -F : '{if ($1 ~ /public key \(base58\)/) print $2}' | sed "s/ \+//g" | tr -d "\n" | tr -d "\r"
}

createSubfolders () {
  local folders="$@"

  for folder in $folders;  do
    if ! [ -d "./$folder" ]; then
      mkdir "./$folder"
    fi
  done
}

removeSubfolderContent () {
  local folders="$@"

  for folder in $folders; do
    if [ -d "./$folder" ]; then
      sudo rm -Rf ./"$folder"/*
    fi
  done
}

# Sets entry node for autopeering
setEntryNode () {
  sed -i 's/"entryNodes": \[.*\]/"entryNodes": \["'$1'"\]/g' "$2"
}

# Resets a peering file
resetPeeringFile() {
  if [ -f "$1" ]; then
    sudo rm "$1"
  fi
  
  cat <<EOF > "$1"
  {
    "peers": [
    ]
  } 
EOF
}
