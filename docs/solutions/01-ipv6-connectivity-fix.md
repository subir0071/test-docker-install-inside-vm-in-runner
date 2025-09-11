# IPv6 Connectivity Issues Investigation

## Problem Analysis

Our VMs created with LXD inside GitHub shared runners are only getting IPv6 addresses and no IPv4 addresses. This could be the root cause of our network connectivity failures.

**Evidence from our VM status**:

```
+---------+---------+------+-----------------------------------------------+-----------------+-----------+
|  NAME   |  STATE  | IPV4 |                     IPV6                      |      TYPE       | SNAPSHOTS |
+---------+---------+------+-----------------------------------------------+-----------------+-----------+
| test-vm | RUNNING |      | fd42:5094:a3dc:4081:216:3eff:fe7a:dc62 (eth0) | VIRTUAL-MACHINE | 0         |
+---------+---------+------+-----------------------------------------------+-----------------+-----------+
```

**Key Observation**: The VM has no IPv4 address, only IPv6.

## Hypothesis

Many external services and package repositories may have limited or problematic IPv6 connectivity from GitHub runners. If our VM only has IPv6 connectivity, it cannot reach IPv4-only services, causing the network timeouts we observe.

## Research - GitHub Issues Analysis

### Issue #668: IPv6 on GitHub-hosted runners

**URL**: https://github.com/actions/runner-images/issues/668  
**Status**: Closed as "wontfix"  
**Key Findings**:

1. **IPv6 is NOT supported on GitHub runners**: GitHub officially confirmed they cannot support IPv6 due to "infrastructure constraints"
2. **IPv6 module is not loaded**: Even though the kernel supports IPv6, the module is not loaded in runners
3. **Commands that fail**:
   - `curl -6 https://www.google.com` → "Couldn't connect to server"
   - `ping6 ipv6.google.com` → "Network is unreachable"
4. **IPv4 works fine**: `curl -4 https://www.google.com` works normally
5. **Official response**: "Unfortunately we can't support this at this time due to infrastructure constraints"

### Issue #402: IPv6 on GitHub-hosted runners (Original)

**URL**: https://github.com/actions/runner/issues/402  
**Status**: Transferred to runner-images#668  
**Key Technical Details**:

- IPv6 kernel driver is not loaded and cannot be loaded
- `modprobe ipv6` fails silently
- This explains why IPv6 connectivity doesn't work

## Analysis: Why This Affects Our VMs

1. **Direct runners work**: They have IPv4 connectivity and can reach all services
2. **VMs fail**: Our LXD VMs are getting IPv6-only addresses in an environment where IPv6 doesn't work
3. **Network cascade failure**:
   - VM gets IPv6 address only
   - Tries to connect to external services via IPv6
   - GitHub runner environment blocks IPv6 traffic
   - All network operations fail with timeouts

## Root Cause Confirmation

**✅ CONFIRMED**: This is almost certainly our root cause because:

1. **VM has only IPv6**: Our VM status shows no IPv4 address
2. **GitHub blocks IPv6**: Official confirmation that IPv6 is not supported
3. **Symptom match**: Network timeouts match expected behavior when IPv6 traffic is blocked
4. **Direct runner works**: Has IPv4 and doesn't rely on IPv6

## Implementation Plan

### Solution Approach: Force IPv4 Networking in VMs

We need to configure LXD to give our VMs IPv4 addresses instead of (or in addition to) IPv6 addresses.

#### LXD Network Configuration Options

1. **Default bridge modification**: Configure the default LXD bridge to use IPv4
2. **Custom bridge creation**: Create a dedicated IPv4-only bridge
3. **Profile modification**: Modify the VM profile to specify IPv4 networking

#### Technical Steps

1. **Configure LXD for IPv4**:

   ```bash
   # Option 1: Configure default bridge for IPv4
   lxc network set lxdbr0 ipv4.address 10.0.0.1/24
   lxc network set lxdbr0 ipv4.nat true
   lxc network set lxdbr0 ipv6.address none

   # Option 2: Create custom IPv4 bridge
   lxc network create br-ipv4 ipv6.address=none ipv4.address=192.168.100.1/24 ipv4.nat=true
   ```

2. **Launch VM with IPv4 network**:

   ```bash
   # Use custom network
   lxc launch ubuntu:24.04 test-vm --network br-ipv4

   # Or modify existing profile
   lxc profile device set default eth0 network br-ipv4
   ```

## Testing Plan

### Create New Workflow: `test-docker-ipv4-fix.yml`

This workflow will:

1. Configure LXD for IPv4-only networking
2. Create a VM with IPv4 address
3. Verify the VM gets an IPv4 address (not IPv6)
4. Test the same Docker installation that currently fails
5. Compare results with our baseline VM tests

### Success Criteria

- **✅ VM gets IPv4 address**: LXD status shows IPv4 in the table
- **✅ Network operations work**: Package updates, external repos accessible
- **✅ Docker installation succeeds**: Full Docker installation completes
- **✅ Container operations work**: Docker pull and run commands work

### Validation Tests

1. **Network connectivity**: All external services reachable
2. **Package manager**: `apt-get update` completes quickly
3. **Docker installation**: Standard installation workflow succeeds
4. **Container operations**: Docker Hub connectivity and pulls work

## Expected Outcome

If this hypothesis is correct, we should see:

- ✅ Fast network responses (0-4s like direct runner)
- ✅ Successful package installations
- ✅ Working Docker installation
- ✅ Functional container operations

This would definitively prove that IPv6-only networking was our root cause.

## Next Steps

1. **Create IPv4 configuration script** (`scripts/configure-ipv4-networking.sh`)
2. **Update VM launch script** to use IPv4 networking
3. **Create test workflow** (`test-docker-ipv4-fix.yml`)
4. **Run comparative tests** vs baseline IPv6-only results

## Status

🔍 **Active Investigation** - Ready for implementation and testing
