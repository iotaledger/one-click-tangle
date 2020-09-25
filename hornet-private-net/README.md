# Private Tangle Setup using Hornet

## Usage

* Make the the bash script executable by running
```
chmod +x private-tangle.sh
```

* Start a new Tangle with Coordinator, Spammer and 1 Node

*Warning: It destroys previous data.* 

```
./private-tangle.sh start <merkle_tree_depth> <coo_bootstrap_wait_time>
```

The parameter `coo_bootstrap_wait_time` is optional (default is `6` seconds) and denotes the time in seconds to wait for the coordinator to bootstrap. Such time shall be proportional to the depth of the Merkle Tree. For a Merkle Tree of depth `10` it  can be just a few seconds. For a Merkle Tree of depth `24` it could be in the order of `60` seconds. 

`Note: We intend to make the coordinator bootstrap process more robust. Probably it could require a GoHornet patch. `

* Stop all the containers by running 
```
./private-tangle.sh stop
```
