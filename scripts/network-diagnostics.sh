#!/bin/bash
# network-diagnostics.sh - Run comprehensive network diagnostics inside VM

set -e

VM_NAME=${1:-test-vm}

echo "=== Network Connectivity Diagnostics ==="
echo "VM Name: $VM_NAME"

# Check network interfaces
echo "--- Network interfaces ---"
sudo lxc exec $VM_NAME -- bash -c "ip addr show" || true

# Check routing table
echo "--- Routing table ---"
sudo lxc exec $VM_NAME -- bash -c "ip route show" || true

# Check DNS configuration
echo "--- DNS configuration ---"
sudo lxc exec $VM_NAME -- bash -c "cat /etc/resolv.conf" || true

# Test DNS resolution
echo "--- DNS resolution tests ---"
sudo lxc exec $VM_NAME -- bash -c "nslookup archive.ubuntu.com" || true
sudo lxc exec $VM_NAME -- bash -c "nslookup security.ubuntu.com" || true
sudo lxc exec $VM_NAME -- bash -c "nslookup download.docker.com" || true

# Test connectivity to key hosts
echo "--- Connectivity tests ---"
sudo lxc exec $VM_NAME -- bash -c "ping -c 3 8.8.8.8" || true
sudo lxc exec $VM_NAME -- bash -c "ping -c 3 archive.ubuntu.com" || true
sudo lxc exec $VM_NAME -- bash -c "curl -I --connect-timeout 10 --max-time 30 http://archive.ubuntu.com" || true
sudo lxc exec $VM_NAME -- bash -c "curl -I --connect-timeout 10 --max-time 30 https://download.docker.com" || true

echo "Network diagnostics completed!"
