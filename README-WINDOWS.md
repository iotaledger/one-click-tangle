# Windows

Below are instructions on how to run the one-click-tangle on windows using docker, docker-compose and WSL.

## Instructions

Ensure you have Docker desktop installed on your machine https://www.docker.com/products/docker-desktop

Windows Subsystem for Linux also needs to be installed on your machine https://docs.microsoft.com/en-us/windows/wsl/install

A distro where you will be running your linux distribution needs to be installed. One of the best option is Ubuntu which can be found here https://ubuntu.com/wsl

Open the linux distro that you installed from the windows store and install docker-compose in the WSL distribution. Notes on how to install it can be found here https://docs.docker.com/compose/install/ 

Ensure docker-compose v2 is disabled. There are two ways to do this:

- From the Docker menu, click Preferences (Settings on Windows) > General. Clear the Use Docker Compose V2 check box.
- To disable it from the cli, run

  ```
  docker-compose disable-v2
  ```

You can now try and run the one-click-tangle on your WSL distribution.
