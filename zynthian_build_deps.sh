#!/bin/bash

# Install 
sudo apt update
sudo apt upgrade
sudo apt install -y cmake ninja-build build-essential g++ git \
    liblilv-dev libboost-dev  \
    libsystemd-dev catch libasound2-dev uuid-dev \
    authbind libavahi-client-dev  libnm-dev libicu-dev \
    libsdbus-c++-dev libzip-dev google-perftools \
    libgoogle-perftools-dev \
    libpipewire-0.3-dev libbz2-dev \
    nodejs npm curl

git submodule update --init --recursive

./react-config 

echo "=== Configuring inotify max_user_watches ==="
if grep -q "fs.inotify.max_user_watches=524288" /etc/sysctl.conf; then
    echo "inotify settings already configured"
else
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    echo "inotify configured"
