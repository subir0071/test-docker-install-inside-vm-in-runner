#!/bin/bash

# Configure IPv4-only networking for LXD VMs
# This script addresses the root cause of network connectivity issues:
# VMs getting IPv6-only addresses in GitHub runners where IPv6 is not supported

set -euo pipefail

echo "=== Configuring IPv4-only networking for LXD ==="

# Get the default LXD bridge name
DEFAULT_BRIDGE="lxdbr0"

echo "--- Current network configuration ---"
lxc network list || true

echo "--- Checking if default bridge exists ---"
if lxc network show $DEFAULT_BRIDGE >/dev/null 2>&1; then
    echo "Default bridge $DEFAULT_BRIDGE exists"
    
    echo "--- Current bridge configuration ---"
    lxc network show $DEFAULT_BRIDGE
    
    echo "--- Configuring bridge for IPv4-only ---"
    # Disable IPv6 on the default bridge
    lxc network set $DEFAULT_BRIDGE ipv6.address none
    
    # Ensure IPv4 is properly configured
    lxc network set $DEFAULT_BRIDGE ipv4.address 10.0.0.1/24
    lxc network set $DEFAULT_BRIDGE ipv4.nat true
    lxc network set $DEFAULT_BRIDGE ipv4.dhcp true
    
    echo "--- Updated bridge configuration ---"
    lxc network show $DEFAULT_BRIDGE
else
    echo "Default bridge $DEFAULT_BRIDGE does not exist, creating IPv4-only bridge"
    
    echo "--- Creating IPv4-only bridge ---"
    lxc network create $DEFAULT_BRIDGE \
        ipv4.address=10.0.0.1/24 \
        ipv4.nat=true \
        ipv4.dhcp=true \
        ipv6.address=none
    
    echo "--- Bridge created successfully ---"
    lxc network show $DEFAULT_BRIDGE
fi

echo "--- Verifying network configuration ---"
lxc network list

echo "IPv4-only networking configuration completed!"
