#!/bin/bash
# launch-vm.sh - Launch LXD VM for testing

set -e

VM_NAME=${1:-test-vm}
VM_IMAGE=${2:-ubuntu:24.04}

echo "=== Launching LXD VM ==="
echo "VM Name: $VM_NAME"
echo "VM Image: $VM_IMAGE"

sudo lxc launch $VM_IMAGE $VM_NAME --vm

echo "VM '$VM_NAME' launched successfully!"
