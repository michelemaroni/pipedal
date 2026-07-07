#!/bin/bash

# Get the absolute path for the repo from the script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

cd $SCRIPT_DIR 
echo "Changed directory to $SCRIPT_DIR \n"

# Get the required submodules from git
git submodule update --init --recursive
echo "Updated repo submodules"

# Update and upgrade system
sudo apt update && sudo apt upgrade -y
echo "Updated and upgrade systemn"

# Install dependencies via apt
sudo apt install -y cmake ninja-build build-essential g++ \
	git curl \
	liblilv-dev libboost-dev  \
    	libsystemd-dev catch libasound2-dev uuid-dev \
    	authbind libavahi-client-dev  libnm-dev libicu-dev \
    	libsdbus-c++-dev libzip-dev google-perftools \
    	libgoogle-perftools-dev \
    	libpipewire-0.3-dev libbz2-dev libssl-dev librsvg2-dev
echo "Installed apt dependencies"

# Install react dependencies
# Minimum required Node.js major version
MIN_MAJOR=22

# Function to extract the major version number from a semver string like v22.3.0
get_major_version() {
    echo "$1" | sed -E 's/^v([0-9]+).*/\1/'
}

# Check whether the `node` command exists
if command -v node >/dev/null 2>&1; then
    # Grab the full version (e.g., v22.3.0) and extract the major part
    FULL_VERSION=$(node -v)
    INSTALLED_MAJOR=$(get_major_version "$FULL_VERSION")
    echo "Node.js $FULL_VERSION is installed (major version $INSTALLED_MAJOR)."
else
    INSTALLED_MAJOR=
    echo "Node.js is not installed."
fi

# Determine if the installed major version meets the minimum requirement
if [[ -z "$INSTALLED_MAJOR" ]] || (( INSTALLED_MAJOR < MIN_MAJOR )); then
    echo "Node.js version ${MIN_MAJOR}+ is required – running install script..."
    #Download and install nvm:
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
    # in lieu of restarting the shell
    \. "$HOME/.nvm/nvm.sh"
    # Download and install Node.js:
    nvm install 22
else
    echo "Node.js version $INSTALLED_MAJOR satisfies the requirement (>= $MIN_MAJOR)."
fi

# Check ract and npm version
echo "Installed node.js version $(node -v) with npm version $(npm -v)"

cd $SCRIPT_DIR

./react-config

# Apply esbuild fix
cd $SCRIPT_DIR/vite
npm approve-scripts esbuild
