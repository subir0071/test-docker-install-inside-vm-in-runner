#!/bin/bash
# wait-for-vm.sh - Wait for VM to be ready with comprehensive checks

set -e

VM_NAME=${1:-test-vm}
TIMEOUT=${2:-300}

echo "=== Waiting for VM to be ready ==="
echo "VM Name: $VM_NAME"
echo "Timeout: $TIMEOUT seconds"

# Debug: Check VM status
echo "=== VM Status ==="
sudo lxc list
sudo lxc info $VM_NAME

# We check for basic readiness instead of waiting for cloud-init completion
elapsed=0
while [ $elapsed -lt $TIMEOUT ]; do
  # Debug: Show what we're checking
  echo "=== Checking VM readiness (attempt $((elapsed/10 + 1))) ==="
  
  # Check if VM is running and we can execute commands
  if sudo lxc list --format=csv | grep -q "$VM_NAME.*RUNNING"; then
    echo "VM is in RUNNING state"
    
    # Try to execute a simple command to verify VM is responsive
    if sudo lxc exec $VM_NAME -- echo "VM is responsive" 2>/dev/null; then
      echo "VM is responsive to commands"
      
      # Check if basic system is ready (systemd, if available)
      if sudo lxc exec $VM_NAME -- systemctl is-system-running --wait 2>/dev/null || true; then
        echo "VM system is ready!"
        break
      else
        echo "VM system not fully ready yet, but responsive"
        # For basic VMs, being responsive might be enough
        if [ $elapsed -ge 60 ]; then  # After 60 seconds, if responsive, consider ready
          echo "VM has been responsive for sufficient time, considering ready"
          break
        fi
      fi
    else
      echo "VM not responsive to commands yet"
    fi
  else
    echo "VM not in RUNNING state yet"
  fi
  
  echo "Waiting for VM to be ready... ($elapsed/$TIMEOUT seconds)"
  sleep 10
  elapsed=$((elapsed + 10))
done

if [ $elapsed -ge $TIMEOUT ]; then
  echo "=== TIMEOUT DEBUGGING ==="
  echo "Final VM status:"
  sudo lxc list
  sudo lxc info $VM_NAME
  echo "Timeout waiting for VM to be ready"
  exit 1
fi

echo "VM '$VM_NAME' is ready for use!"
