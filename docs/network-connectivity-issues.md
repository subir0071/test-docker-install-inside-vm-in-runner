# Network Connectivity Issues in GitHub Runners

## Overview

This document captures specific network connectivity issues encountered when running Docker installations inside virtual machines on GitHub shared runners.

## Issue #2: Docker Registry HTTPS Connectivity Timeout

**Date**: September 11, 2025  
**Workflow**: `test-lxd.yml` (Docker diagnostics step)  
**VM Environment**: Ubuntu 24.04 LXD VM on GitHub Ubuntu runner

### Error Description

During Docker installation diagnostics, attempts to connect to Docker's official registry for GPG key download resulted in extended timeouts.

### Error Messages

```text
curl: (28) Failed to connect to download.docker.com port 443 after 300935 ms: Timeout was reached
```

### Analysis

1. **HTTPS Connectivity Failure**: Complete inability to connect to Docker's official download server

   - Target: `download.docker.com:443` (HTTPS)
   - Timeout after: 300935 ms (~5 minutes)
   - Error type: Connection timeout (not DNS resolution failure)

2. **Diagnostic Context**:
   - **Docker Service Status**: No Docker service logs found (`-- No entries --`)
   - **System Resources**: VM had adequate resources
     - Memory: 955Mi total, 666Mi available
     - Disk: 8.7G total, 7.1G available (19% used)
   - **Docker Process**: No Docker daemon processes running (installation failed earlier)

### Impact

- Docker GPG key download fails completely
- Prevents adding Docker's official repository
- Makes standard Docker installation impossible
- Confirms that network issues extend beyond Ubuntu repositories to external HTTPS services

### Root Cause

This demonstrates the same networking flakiness affecting both:

- HTTP connections (Ubuntu repositories on port 80)
- HTTPS connections (Docker registry on port 443)

The issue affects multiple external services, confirming this is a GitHub runner network infrastructure problem rather than a service-specific issue.

## Issue #1: Ubuntu Package Repository Connectivity Failure

**Date**: September 11, 2025  
**Workflow**: `test-lxd.yml`  
**VM Environment**: Ubuntu 24.04 LXD VM on GitHub Ubuntu runner

### Error Description

During the Docker installation process, the VM failed to connect to Ubuntu package repositories with the following errors:

### Error Messages

```text
Ign:1 http://archive.ubuntu.com/ubuntu noble InRelease
Ign:2 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Ign:3 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Ign:4 http://security.ubuntu.com/ubuntu noble-security InRelease

Err:1 http://archive.ubuntu.com/ubuntu noble InRelease
  Could not connect to archive.ubuntu.com:80 (2620:2d:4000:1::102). - connect (101: Network is unreachable)
  Could not connect to archive.ubuntu.com:80 (91.189.91.82), connection timed out
  Could not connect to archive.ubuntu.com:80 (185.125.190.83), connection timed out
```

### Analysis

1. **IPv6 Connectivity Issues**: Multiple IPv6 addresses show "Network is unreachable" errors

   - `2620:2d:4000:1::102`
   - `2620:2d:4002:1::101`
   - `2620:2d:4002:1::102`
   - And several others

2. **IPv4 Connectivity Issues**: IPv4 addresses show connection timeouts

   - `91.189.91.82` - connection timed out
   - `185.125.190.83` - connection timed out

3. **Affected Services**:
   - `archive.ubuntu.com` (main Ubuntu packages)
   - `security.ubuntu.com` (security updates)
   - Both HTTP (port 80) connections

### Impact

- `apt-get update` fails to refresh package lists
- Docker installation cannot proceed normally
- Package manager falls back to cached/old package information
- System appears to work partially (cached packages install successfully)

### Root Cause

This aligns with the documented networking flakiness in GitHub shared runners reported in [GitHub Actions Runner Images #1187](https://github.com/actions/runner-images/issues/1187).

## Potential Solutions Implemented

### 1. Retry Logic

Added retry mechanisms for network operations:

```bash
retry_command() {
  local max_attempts=3
  local delay=10
  local count=0

  while [ $count -lt $max_attempts ]; do
    if sudo lxc exec test-vm -- bash -c "$1"; then
      return 0
    else
      count=$((count + 1))
      sleep $delay
    fi
  done
  return 1
}
```

### 2. IPv4 Preference

Force IPv4 for package manager:

```bash
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
```

### 3. Alternative Installation Methods

- Snap package installation
- Docker convenience script installation
- Static binary installation

### 4. Enhanced Diagnostics

Added comprehensive network diagnostics:

- Network interface information
- Routing table
- DNS configuration and resolution tests
- Connectivity tests to key hosts

## Recommendations

Based on the documented network connectivity issues:

1. **Use aggressive connection timeouts** (much shorter than the default 5+ minutes)

   - Set curl timeouts to 30-60 seconds: `curl --connect-timeout 30 --max-time 60`
   - Avoid hanging workflows that consume runner minutes unnecessarily

2. **Always implement retry logic** for network operations in GitHub Actions workflows

   - Retry 3-5 times with exponential backoff
   - Log each retry attempt for debugging

3. **Add comprehensive network diagnostics** before installation attempts

   - Test connectivity to target hosts before starting
   - Capture routing and DNS information
   - Include diagnostic steps that run even on failure

4. **Provide multiple installation fallback methods**:

   - Standard package manager installation (apt)
   - Snap package installation
   - Docker convenience script (`get.docker.com`)
   - Static binary installation
   - Cached/pre-downloaded packages

5. **Consider IPv4-only configuration** if IPv6 connectivity is consistently problematic

   - `echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4`

6. **Use GitHub Actions caching** to reduce network dependency

   - Cache downloaded packages and dependencies
   - Pre-build images with Docker pre-installed when possible

7. **Monitor and document failure patterns**
   - Track which hosts fail most frequently
   - Note time-of-day patterns (runner load correlation)
   - Document specific error types and their frequency

## Key Findings Summary

- **Network timeouts affect multiple services**: Ubuntu repositories (HTTP), Docker registry (HTTPS)
- **Default timeouts are too long**: 5+ minute timeouts waste runner resources
- **Both IPv4 and IPv6 connectivity affected**: Comprehensive networking infrastructure issue
- **Issue is consistent and reproducible**: Not intermittent, but consistently failing
- **VM resources are adequate**: Network issues are not caused by resource constraints

## Related Issues

- [GitHub Actions Runner Images #1187](https://github.com/actions/runner-images/issues/1187) - Networking is Flaky on GitHub Hosted Runners
- [Docker Installation Issues in VMs](../README.md) - Main project documentation

---

_This document will be updated as more network connectivity issues are discovered and documented._
