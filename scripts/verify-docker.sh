#!/bin/bash
# verify-docker.sh - Verify Docker installation and functionality

set -e

VM_NAME=${1:-test-vm}

echo "=== Verifying Docker installation ==="
echo "VM Name: $VM_NAME"

# Check Docker version
echo "--- Docker version ---"
sudo lxc exec $VM_NAME -- bash -c "docker --version"

# Check Docker service status
echo "--- Docker service status ---"
sudo lxc exec $VM_NAME -- bash -c "systemctl status docker --no-pager"

# Test Docker functionality
echo "--- Testing Docker functionality ---"
sudo lxc exec $VM_NAME -- bash -c "docker info"

echo "--- Running test container ---"
sudo lxc exec $VM_NAME -- bash -c "docker run --rm hello-world"

echo "Docker verification completed successfully!"
