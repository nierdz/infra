#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

export DEBIAN_FRONTEND=noninteractive

# Create my first user for ansible
useradd kmet
mkdir -p /home/kmet/.ssh

# Push my ssh keys in it
pushd /home/kmet/.ssh
wget https://github.com/nierdz.keys -O authorized_keys
popd

# Remove some OVH shit and install usefull packages
apt-get update
apt-get -y upgrade
apt-get -y install sudo python3-apt
apt-get -y autoremove

# Give me some power!
echo "kmet ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/kmet

# Fix permissions
chown -R kmet:kmet /home/kmet
