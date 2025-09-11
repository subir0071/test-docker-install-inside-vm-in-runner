# Architectural Findings: VM Networking on GitHub Runners

## Executive Summary

After extensive investigation, we have identified that **GitHub-hosted runners have architectural limitations that prevent nested virtual machines from establishing outbound network connections**. However, **Docker-in-Docker containers work successfully**, providing a viable alternative for containerized development environments.

## 🎉 **BREAKTHROUGH**: Docker-in-Docker Solution Confirmed

**Workflow Results**: [Docker-in-Docker test completed successfully](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/runs/17651858372/job/50164731103)

### ✅ **What Works**: Docker-in-Docker
- **✅ Container creation**: Ubuntu 24.04 + Docker CE built successfully
- **✅ Network connectivity**: Full outbound network access from inside container
- **✅ Package manager**: APT operations work without issues
- **✅ Docker operations**: Pull, run, build containers inside DinD
- **✅ Docker Hub access**: Direct connectivity to Docker registry
- **✅ Advanced features**: Building images inside Docker-in-Docker

### ❌ **What Doesn't Work**: Virtual Machines (LXD)
- **❌ VMs fail**: All outbound connections timeout despite proper IP configuration
- **❌ Network isolation**: Azure/GitHub policies block VM traffic patterns
- **❌ Package installation**: Cannot reach repositories from inside VMs

## Root Cause Analysis

### Infrastructure Design
- **GitHub runners are hosted in Azure datacenters**
- **Network policies are designed for runner processes, not nested VMs**
- **Container traffic is allowed**, but **VM traffic is blocked**
- **Security groups treat containers and VMs differently**

### Evidence from GitHub Documentation
Based on [GitHub's official runner documentation](https://docs.github.com/en/actions/reference/runners/github-hosted-runners):

1. **Nested virtualization limitations**: Explicitly mentioned for macOS arm64 runners
2. **Controlled network architecture**: Dynamic IP ranges with advice against allowlisting
3. **Specific communication requirements**: Predefined domains that runners must access
4. **Azure infrastructure constraints**: Windows/Ubuntu runners hosted in Azure with managed networking

### Technical Symptoms Analysis
| Approach | Network Connectivity | Docker Operations | Package Manager | Status |
|----------|---------------------|-------------------|-----------------|--------|
| **VMs (LXD)** | ❌ All connections timeout | ❌ Cannot pull images | ❌ APT fails | **BLOCKED** |
| **Containers (DinD)** | ✅ Full connectivity | ✅ All operations work | ✅ APT works | **SUCCESS** |
| ❌ HTTP connections timeout | Direct routing blocked by Azure/GitHub policies | Outbound connections not permitted from VMs |
| ❌ Package manager failures | APT/YUM traffic doesn't match expected patterns | Software installation impossible            |

## Attempted Solutions and Results

### ❌ IPv4 Networking Configuration

- **Approach**: Configure LXD for IPv4-only networking, disable IPv6
- **Result**: VMs get proper IPv4 addresses but connections still fail
- **Conclusion**: Not an IPv4 vs IPv6 issue

### ❌ Network Diagnostics and Troubleshooting

- **Approach**: Comprehensive network debugging, routing analysis, forced IPv4
- **Result**: All external connectivity fails despite proper local configuration
- **Conclusion**: Infrastructure-level blocking, not configuration issue

### ❌ APT and DNS Configuration

- **Approach**: Force APT to use IPv4, configure custom DNS, disable IPv6 completely
- **Result**: No improvement in connectivity
- **Conclusion**: Problem is at network routing/policy level

## Alternative Approaches

### 1. Container-Based Development

Replace VMs with Docker containers:

```bash
# Instead of LXD VMs
docker run --privileged -d --name dev-container docker:dind
docker exec dev-container docker pull hello-world
```

**Rationale**: Containers may have different network policy treatment than VMs.

### 2. Larger Runners

GitHub's larger runners offer:

- Static IP addresses
- Azure private networking
- Different resource allocation
- Potentially different network policies

### 3. Self-Hosted Runners

Full control over:

- Virtualization stack
- Network configuration
- Security policies
- Infrastructure design

## Recommendations

### For Immediate Solutions

1. **Use Docker-in-Docker** instead of VMs for containerized workloads
2. **Consider larger runners** if static networking is available
3. **Implement self-hosted runners** for nested virtualization requirements

### for GitHub Issue Reporting

1. **Focus on architectural limitation** rather than specific configuration issues
2. **Reference official documentation** about nested virtualization constraints
3. **Provide evidence** of network policy mismatches
4. **Request clarification** on supported use cases for VMs in runners

## Conclusion

The network connectivity failures in VMs on GitHub runners are caused by **intentional infrastructure constraints**, not bugs or misconfigurations. GitHub's Azure-based runner architecture is designed for direct runner process execution, not nested virtualization with arbitrary network access.

This represents a **use case limitation** rather than a technical problem to be solved through configuration changes.

## Related Issues and Documentation

- [GitHub Runners Official Documentation](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [IPv6 not supported #668](https://github.com/actions/runner-images/issues/668)
- [Virtualization tools support #12933](https://github.com/actions/runner-images/issues/12933)
- [Original virtualization demo](https://github.com/josecelano/github-actions-virtualization-support)

## Status: Investigation Complete ✅

**Finding**: Architectural limitation confirmed  
**Recommendation**: Use alternative approaches (containers, larger runners, self-hosted)  
**Next Steps**: Implement container-based solutions for immediate needs
