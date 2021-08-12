#!/bin/bash

### Utility functions ###

# Extracts the public key from a key pair
getPublicKey () {
  echo $(cat "$1" | tail -1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
}

# Extracts the private key from a key pair
getPrivateKey () {
  echo $(cat "$1" | head -n 1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
}

setCooPublicKey () {
  local public_key="$1"
  sed -i 's/"key": ".*"/"key": "'$public_key'"/g' "$2"
}

generateP2PIdentity () {
  docker-compose run --rm "$1" hornet tool p2pidentity > $2
}

setupIdentityPrivateKey () {
  local private_key=$(cat $1 | head -n 1 | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
  # and then set it on the config.json file
  sed -i 's/"identityPrivateKey": ".*"/"identityPrivateKey": "'$private_key'"/g' $2
}

# Extracts the peerID from the identity file
getPeerID () {
  local identity_file="$1"
  local line_count=$(cat identity.txt | wc -l | tr -d ' ' | tr -d '\n' | tr -d '\r')
  if [ $line_count == "6" ]; then
    echo $(cat $identity_file | sed '4q;d' | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
  else
    echo $(cat $identity_file | sed '3q;d' | cut -d ":" -f 2 | sed "s/ \+//g" | tr -d "\n" | tr -d "\r")
  fi
}
