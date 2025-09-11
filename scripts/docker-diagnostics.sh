#!/bin/bash
# docker-diagnostics.sh - Run Docker installation diagnostics

set -e

VM_NAME=${1:-test-vm}

echo "=== Docker installation diagnostics ==="
echo "VM Name: $VM_NAME"

# Check if Docker daemon is running
echo "--- Docker daemon process ---"
sudo lxc exec $VM_NAME -- bash -c "ps aux | grep docker" || true

# Check Docker logs
echo "--- Docker service logs ---"
sudo lxc exec $VM_NAME -- bash -c "journalctl -u docker.service --no-pager -n 50" || true

# Check available disk space
echo "--- Disk usage ---"
sudo lxc exec $VM_NAME -- bash -c "df -h" || true

# Check memory usage
echo "--- Memory usage ---"
sudo lxc exec $VM_NAME -- bash -c "free -h" || true

# Network connectivity test
echo "--- Network connectivity test ---"
sudo lxc exec $VM_NAME -- bash -c "curl -I --connect-timeout 30 --max-time 60 https://download.docker.com/linux/ubuntu/gpg" || true

echo "Docker diagnostics completed!"
