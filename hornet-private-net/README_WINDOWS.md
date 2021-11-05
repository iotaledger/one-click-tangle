# Instructions to Set up a Private Tangle on Windows 10

1. Install [Docker for Windows](https://docs.docker.com/desktop/windows/install)
- Make sure to also install the required Windows components for WSL 2 ([Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about))

2. After the installation you can check your **Docker** (`>=18.03`) and **Docker Compose** (`>=1.21`) versions using the following CMD commands
```console
docker -v
docker-compose -v
```

3. Install Ubuntu distribution using the following CMD commands step by step (list available distributions / install Ubuntu / check version)
```console
wsl --list --online
wsl --install --distribution Ubuntu
wsl -l -v
```

4. Make Ubuntu your default WSL distribution by using the following CMD commands (set default distribution / check new default)
```console
wsl --set-default Ubuntu
wsl --list
```

5. Docker Desktop Settings
- Enable WSL integration with new Ubuntu distribution (*Settings > Resources > WSL INTEGRATION*)
- Make sure Docker Compose v2 is <ins>deactivated</ins> (*Settings>General*)
- You can also deactivate Docker Compose v2 by running
```console
docker-compose disable-v2
```

6. Clone [one-click-tangle](https://github.com/iotaledger/one-click-tangle) repository with the following CMD commands
```console
git clone https://github.com/iotaledger/one-click-tangle
cd one-click-tangle
```

7. Private Tangle Installation
- Run Ubuntu as <ins>administrator</ins>
- Navigate to <ins>your</ins> repo path with the following Linux command
```console
cd /mnt/<repo_path>/one-click-tangle/hornet-private-net/
```
- Trigger shell script with 30 seconds to wait for the Coordinator bootstrap step with the following Linux command (This will set up several docker containers)
```console
./private-tangle.sh install 30
```

8. Now you can use your private tangle as described in the main [README](https://github.com/iotaledger/one-click-tangle/blob/a8ff9269b76fd7f3eb1e4ef95426ca8fc263e52b/hornet-private-net/README.md)