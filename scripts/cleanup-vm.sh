#!/bin/bash
# cleanup-vm.sh - Clean up VM resources

set -e

VM_NAME=${1:-test-vm}

echo "=== Cleaning up VM ==="
echo "VM Name: $VM_NAME"

sudo lxc stop $VM_NAME || true
sudo lxc delete $VM_NAME || true

echo "VM '$VM_NAME' cleanup completed!"
