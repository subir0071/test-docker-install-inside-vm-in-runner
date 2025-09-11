#!/bin/bash
# test-vm-basic.sh - Test basic VM functionality

set -e

VM_NAME=${1:-test-vm}

echo "=== Testing basic VM functionality ==="
echo "VM Name: $VM_NAME"

sudo lxc exec $VM_NAME -- bash -c "echo Hello from LXD VM"
sudo lxc exec $VM_NAME -- bash -c "uname -a"
sudo lxc exec $VM_NAME -- bash -c "cat /etc/os-release"

echo "Basic VM functionality test completed!"
