# Private Tangle Exploter Setup

## Usage

* Make the the bash script executable by running
```
chmod +x tangle-explorer.sh
```

* Start a new Tangle Explorer

*Warning: It destroys previous data.* 

```
./tangle-explorer.sh start <network-definition.json>
```

The `network-definition.json` parameter is optional. By default it will be taken the file present at
`config/private-network.json`. The format of the file is described [here](https://github.com/iotaledger/explorer/blob/master/api/DEPLOYMENT.md).

* Stop all the containers by running 
```
./tangle-explorer.sh stop
```
