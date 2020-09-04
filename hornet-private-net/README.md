# Private Tangle Setup using Hornet

## Usage

* Make the the bash script executable by running
```
chmod +x private-tangle.sh
```

* Start a new Tangle with Coordinator, Spammer and 1 Node

*Warning: It destroys previous data.* 
```
./private-tangle.sh start <merkle_tree_depth>
```

* Stop all the containers by running 
```
./private-tangle.sh stop
```
