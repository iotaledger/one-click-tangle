#!/bin/bash 

# General bootstrap script

# Detects the platform downloads the latest bootstrap from Github
# And executes it
# For the time being only the Linux AWS is supported

wget https://raw.githubusercontent.com/jmcanterafonseca-iota/IOTA-Tangle-Node-Deployment/master/bootstrap/boostrap-amazonlinux.sh

chmod +x ./bootstrap-amazonlinux.sh

source ./bootstrap-amazonlinux.sh
