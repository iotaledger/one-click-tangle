# Hornet Chrysalis Node

## Usage

* Make the the bash script executable by running
```
chmod +x hornet.sh
```

* Install a Hornet Node connected to the Chrysalis mainnet

```
./hornet.sh install -p <peer_multiAddress> -i <docker_image>
```

The `peer_multiAddress` parameter must conform to the format specified [here](https://hornet.docs.iota.org/post_installation/peering.html)

Optionally a Docker image name can be passed, even though, by default, the image name present in the `docker-compose.yaml` file will be used, normally `gohornet/hornet:latest`. 

* Stop Hornet by running
```
./hornet.sh stop
```

* Start Hornet by running
```
./hornet.sh start
```

* Update Hornet by running
```
./hornet.sh update
```
