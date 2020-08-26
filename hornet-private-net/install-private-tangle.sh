#!/bin/bash

# Merkle tree generation (tree levels passed as parameter)

COO_SEED=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Z9' | fold -w 81 | head -n 1)
echo $COO_SEED > coordinator.seed 

rm ./db/private-tangle/coordinator.tree 2> /dev/null

MERKLE_TREE_ADDR=$(docker-compose run --rm -e COO_SEED=$COO_SEED hornet-coo hornet tool merkle | grep "Merkle tree root"  \
| cut  -d ":" -f 2 - | sed "s/ //g" | tr -d "\n" | tr -d "\r")

echo -n $MERKLE_TREE_ADDR > merkle-tree.root

PP=$(cat merkle-tree.root)

# Copy the Merkle Tree Address to the coordinator configuration
cp config/config-coo.json config/config-coo-tmp.json
sed 's/"address": \("\).*\("\)/"address": \1'$PP'\2/g' config/config-coo-tmp.json > config/config-coo.json
rm config/config-coo-tmp.json

# Bootstrap the coordinator
# docker-compose run --rm -e COO_SEED=$COO_SEED hornet-coo hornet


# Run the coordinator
# docker-compose service start hornet-coo


# Run the spammer
# docker-compose service start hornet-spammer


# Run a regular node 
# docker-compose service start hornet-node