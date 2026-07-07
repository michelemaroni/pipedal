#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

cd $SCRIPT_DIR 
echo "Changed directory to $SCRIPT_DIR \n"

git submodule update --init --recursive
echo "Updated repo submodules \n"

sudo apt update && sudo apt upgrade -y
echo "Updated and upgrade system \n"

sudo apt install -y cmake ninja-build build-essential g++ \
	git curl \
	liblilv-dev libboost-dev  \
    	libsystemd-dev catch libasound2-dev uuid-dev \
    	authbind libavahi-client-dev  libnm-dev libicu-dev \
    	libsdbus-c++-dev libzip-dev google-perftools \
    	libgoogle-perftools-dev \
    	libpipewire-0.3-dev libbz2-dev libssl-dev librsvg2-dev
echo "Installed apt dependencies"

# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"
# Download and install Node.js:
nvm install 22

echo "Intalled  node.js version $(node -v) with npm version $(npm -v)"

cd $SCRIPT_DIR

./react-config

cd $SCRIPT_DIR/vite
#npm approve-scripts esbuild
