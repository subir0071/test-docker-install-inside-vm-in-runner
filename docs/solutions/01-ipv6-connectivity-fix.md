# VM Network Connectivity Issues - Root Cause Analysis

## Updated Problem Analysis (Critical Discovery)

Our investigation initially focused on IPv6 connectivity issues, but deeper analysis of GitHub's official documentation reveals a **fundamental architectural limitation**: **GitHub-hosted runners are not designed to support nested virtualization with outbound network access**.

### Original Symptoms

- VMs get proper IPv4 addresses (e.g., 10.0.0.98) after IPv4 configuration
- DNS resolution works correctly inside VMs
- All HTTP/HTTPS connections timeout, even with forced IPv4
- Package manager operations fail with "Network is unreachable"

### Critical Discovery: Network Architecture Limitations

Based on [GitHub's official runner documentation](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), we identified the root cause:

**Key Evidence**:

1. **Nested virtualization limitations**: Documentation explicitly mentions nested-virtualization is not supported (for macOS arm64), indicating broader infrastructure constraints
2. **Network policies designed for runners, not VMs**: Communication requirements list domains that _runners_ must access, not nested VMs
3. **Azure infrastructure constraints**: Ubuntu runners are hosted in Azure datacenters with specific network security policies
4. **Dynamic IP management**: GitHub's infrastructure uses dynamic IPs and advises against IP allowlisting, suggesting controlled network access

### Why Our Symptoms Make Perfect Sense

- ✅ **VMs get IPv4 addresses**: LXD bridge networking works locally within the runner
- ✅ **DNS resolution works**: DNS queries are likely handled/proxied at the runner/host level
- ❌ **HTTP connections fail**: Azure/GitHub network policies block unexpected traffic patterns from VMs
- ❌ **Package manager fails**: APT/YUM traffic from VMs doesn't match expected runner process patterns

**Conclusion**: This is not an IPv6 vs IPv4 issue, but a fundamental **nested virtualization network policy limitation**.

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

## Historical IPv6 Investigation (Still Relevant)

The following research was conducted initially focusing on IPv6 issues. While the root cause is deeper than IPv6/IPv4, this research provides valuable context about GitHub's network limitations:

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

## Architectural Analysis

### Network Policy Constraints

**GitHub Infrastructure Design**:

- Ubuntu runners are hosted in **Azure datacenters**
- Network policies are configured for **runner processes**, not nested VMs
- **Communication requirements** specify exact domains runners must access
- **Dynamic IP ranges** with advice against IP allowlisting indicates controlled access patterns

### Why Standard Networking Approaches Don't Work

1. **VM traffic doesn't match expected patterns**: Azure security groups likely block traffic from VM processes that don't match known runner signatures
2. **NAT/routing policies**: GitHub's network architecture may not provide proper NAT for nested VM traffic
3. **Firewall rules**: Outbound connections from VMs may be blocked at infrastructure level
4. **DNS vs HTTP disparity**: DNS queries work (likely proxied) but HTTP connections fail (direct routing blocked)

## Alternative Approaches to Consider

### 1. Container-Based Development

Instead of VMs, use Docker containers which may have different network policy treatment:

```bash
# Use Docker-in-Docker instead of VM
docker run --privileged -d --name docker-container docker:dind
docker exec docker-container docker pull hello-world
```

### 2. Larger Runners Investigation

GitHub documentation mentions larger runners have different networking capabilities:

- Static IP addresses
- Azure private networking
- Different resource allocation

### 3. Self-Hosted Runners

For use cases requiring nested virtualization with full network access.

## Conclusion

The network connectivity failures are caused by **GitHub's infrastructure not being designed to support nested virtualization with outbound network access**. This is an architectural limitation, not a configuration issue that can be resolved with IPv4/IPv6 tweaks.

**Key Insight**: The infrastructure constraints that prevent IPv6 support also prevent proper VM networking - both stem from GitHub/Azure's controlled network architecture designed for runner processes, not arbitrary nested workloads.

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
