#!/bin/bash
# install-lxd.sh - Install and configure LXD for testing

set -e

echo "=== Installing LXD ==="

# Install LXD via snap
sudo snap install lxd

# Wait for LXD daemon to start
echo "Waiting for LXD daemon to start..."
sleep 15

# Initialize LXD with default settings
sudo lxd init --auto

# Add runner to lxd group
sudo usermod -a -G lxd runner

# Fix socket permissions for CI environment
sudo chmod 666 /var/snap/lxd/common/lxd/unix.socket

# Test basic LXD functionality
echo "Testing LXD functionality..."
sudo lxc list

echo "LXD installation and configuration completed!"
