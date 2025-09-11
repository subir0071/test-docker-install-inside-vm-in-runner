# VM Network Connectivity Issues on GitHub Shared Runners

## Workflow Status

### ✅ Working Solutions

[![Test Docker-in-Docker](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-in-docker.yml/badge.svg)](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-in-docker.yml) [![Test Docker Runtime Install](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-runtime-install.yml/badge.svg)](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-runtime-install.yml)

### 🔍 Investigation Tests

[![Test Docker IPv4 Fix](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-ipv4-fix.yml/badge.svg)](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-ipv4-fix.yml) [![Test Docker Standard APT](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-standard-apt.yml/badge.svg)](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-docker-standard-apt.yml)

### 📊 Baseline & Control Tests

[![Test Ping Limitation](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-ping-limitation.yml/badge.svg)](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-ping-limitation.yml) [![Test Runner Connectivity](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-runner-connectivity.yml/badge.svg)](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/workflows/test-runner-connectivity.yml)

## 🎉 **SOLUTION FOUND**: Docker-in-Docker Alternative

**Status**: ✅ **SOLVED** - Docker-in-Docker provides full functionality without network restrictions!

## Overview

This repository investigated **network connectivity failures** when running virtual machines inside GitHub shared runners and **discovered a working solution**: **Docker-in-Docker containers work perfectly** while VMs are blocked by infrastructure limitations.

## 🔍 **Key Discovery**: Different Network Policies for VMs vs Containers

**Successful Tests**:

- [Docker-in-Docker Build-time Installation](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/runs/17651858372/job/50164731103) ✅
- [Docker-in-Docker Runtime Installation](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/runs/17652148460/job/50165698210) ✅

### ✅ **What Works**: Docker-in-Docker (Both Installation Methods)

- **Full network connectivity** from inside containers
- **Package manager operations** (apt-get update/install work perfectly)
- **Docker Hub access** (pull/push operations successful)
- **Container building** inside Docker-in-Docker
- **All standard development workflows** function normally
- **Multiple installation approaches** validated (build-time + runtime)

### ❌ **What Doesn't Work**: Virtual Machines (LXD)

- All outbound HTTP/HTTPS connections timeout
- Package managers cannot reach repositories
- Software installation fails due to network unreachability

## Root Cause Analysis

**GitHub-hosted runners use Azure infrastructure** with different network policies for containers vs VMs:

- **Container traffic**: ✅ Allowed and properly routed
- **VM traffic**: ❌ Blocked by security groups and network policies

**Key Evidence**:

- GitHub's [official documentation](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) mentions nested-virtualization limitations
- Network policies are designed for runner processes and containers, not nested VMs
- Azure infrastructure treats container networking differently than VM networking

## 🛠️ **Working Solution**: Docker-in-Docker (Multiple Methods)

Instead of using virtual machines, use **Docker-in-Docker** for containerized development environments:

### **Method 1: Build-time Installation (Faster)**

```bash
# Build Docker-in-Docker image (Docker pre-installed)
docker build -f docker/Dockerfile.dind -t dev-environment docker/

# Run privileged container with Docker daemon
docker run -d --privileged --name dev-container dev-environment

# Use immediately - Docker is ready
docker exec dev-container docker pull ubuntu:24.04
docker exec dev-container docker run --rm ubuntu:24.04 echo "It works!"
```

### **Method 2: Runtime Installation (More Flexible)**

```bash
# Build base Ubuntu image
docker build -f docker/Dockerfile.runtime -t ubuntu-base docker/

# Run container and install Docker at runtime
docker run -d --privileged --name dev-container ubuntu-base sleep infinity
docker cp docker/install-docker-runtime.sh dev-container:/usr/local/bin/
docker exec dev-container /usr/local/bin/install-docker-runtime.sh

# Use after installation completes
docker exec dev-container docker pull ubuntu:24.04
```

**Both methods provide identical functionality** - choose based on your needs:

- **Build-time**: Faster startup, production CI/CD
- **Runtime**: Dynamic configuration, debugging visibility

## Project Goals

1. **Document the Architectural Limitation**: Provide clear evidence that GitHub runners don't support nested VM networking
2. **Investigate Alternative Approaches**: Test whether container-based solutions work differently
3. **Research Workarounds**: Explore larger runners, self-hosted runners, or different virtualization approaches
4. **Share Findings**: Help the community understand these infrastructure constraints

## Key Findings Summary

### ❌ What Doesn't Work

- **LXD VMs with outbound connectivity**: Network connections fail despite proper IP configuration
- **IPv4/IPv6 configuration fixes**: The problem is deeper than address family issues
- **Standard networking troubleshooting**: Traditional network debugging doesn't apply here

### ✅ What We've Learned

- **VMs can be created successfully**: LXD virtualization itself works on GitHub runners
- **Local networking functions**: VM-to-VM and VM-to-host communication works
- **DNS resolution works**: Likely proxied/handled at the runner level
- **Root cause is architectural**: GitHub/Azure infrastructure design limitation

### 🧪 Potential Alternatives to Test

1. **Container-based approaches**: Docker-in-Docker instead of VMs
2. **Larger runners**: Different networking capabilities mentioned in GitHub docs
3. **Self-hosted runners**: Full control over virtualization and networking
4. **Different virtualization tools**: Test if other VM technologies behave differently

## Repository Structure

```text
├── README.md                            # This documentation
├── .github/workflows/                   # Test workflows for different installation methods
│   ├── test-docker-standard-apt.yml    # Baseline: Standard Docker apt installation in VM
│   ├── test-runner-connectivity.yml    # Control: Network tests directly on runner
│   ├── test-ping-limitation.yml        # Platform test: Demonstrates ICMP blocking
│   ├── test-docker-ipv4-fix.yml        # Solution test: IPv4 networking fix for VMs
│   ├── test-docker-in-docker.yml       # ✅ Working: Docker-in-Docker build-time installation
│   └── test-docker-runtime-install.yml # ✅ Working: Docker-in-Docker runtime installation
├── docker/                             # Docker-in-Docker solution files
│   ├── Dockerfile.dind                 # ✅ Build-time Docker installation
│   ├── Dockerfile.runtime              # ✅ Base Ubuntu for runtime installation
│   ├── install-docker-runtime.sh       # ✅ Runtime Docker installation script
│   └── supervisord.conf                # Docker daemon configuration
├── scripts/                            # Reusable installation and diagnostic scripts
│   ├── install-lxd.sh                  # LXD installation and configuration
│   ├── configure-ipv4-networking.sh    # IPv4-only network configuration for VMs
│   ├── launch-vm.sh                    # VM creation with configurable parameters
│   ├── wait-for-vm.sh                  # VM readiness checking with timeout
│   ├── test-vm-basic.sh                # Basic VM functionality tests
│   ├── network-diagnostics.sh          # Network connectivity diagnostics
│   ├── verify-docker.sh                # Docker installation verification
│   ├── docker-diagnostics.sh           # Docker troubleshooting diagnostics
│   ├── cleanup-vm.sh                   # VM cleanup and resource management
│   └── README.md                       # Scripts documentation and usage
└── docs/                               # Detailed documentation and findings
    ├── network-connectivity-issues.md  # Documented network failures and analysis
    ├── solution-docker-in-docker.md    # ✅ Complete Docker-in-Docker solution guide
    ├── runtime-installation-test.md    # ✅ Runtime installation test results
    └── architectural-findings.md        # Root cause analysis and conclusions
    └── solutions/                     # Solution research and implementation
        ├── README.md                  # Solutions documentation overview
        └── 01-ipv6-connectivity-fix.md # IPv6/IPv4 networking investigation
```

## Current Status

### ✅ Completed

- **Baseline test workflow**: Reproduces standard Docker installation failures in VMs
- **Control test workflow**: Tests network connectivity directly on GitHub runner
- **✅ Root cause identified**: Network issues are **VM-specific**, not runner infrastructure problems
- **Control test results**: Direct runner connectivity tests **ALL PASSED** (September 11, 2025)
- **🔍 IPv6 root cause discovered**: VMs get IPv6-only addresses, but GitHub runners block IPv6 traffic
- **✅ Ping limitation confirmed**: Test workflow verified ICMP is blocked in GitHub runners (Azure design)
- **Platform limitation results**: Ping tests failed (12-14s timeouts), HTTP tests passed (0-4s)
- **Refactored connectivity tests**: All workflows use HTTP-based connectivity testing only
- **Reusable scripts**: Modular components for testing different approaches
- **Network issue documentation**: Detailed analysis of connectivity failures
- **Diagnostic tooling**: Comprehensive logging and troubleshooting scripts

### � In Active Testing

- **IPv4 networking solution**: Testing hypothesis that IPv6-only VMs cause connectivity failures
- **Solution workflow**: `test-docker-ipv4-fix.yml` validates IPv4 networking fix
- **Expected outcome**: Docker installation should succeed with IPv4 addresses

### 📋 Planned

- VM networking fix workflows:
  - LXD bridge configuration optimization
  - VM network interface debugging
  - Alternative VM networking approaches
- Specialized VM installation workflows:
  - Retry mechanisms with exponential backoff
  - IPv4-only configuration for VMs
  - Snap package installation
  - Pre-cached dependency installation
  - Docker convenience script installation

## Summary of Findings: Direct Runner vs VM Environment

Our comprehensive testing has revealed significant differences between running operations directly on GitHub shared runners versus inside VMs created within those runners (double virtualization):

| Operation/Feature                  | Direct GitHub Runner               | VM Inside Runner (LXD)         | Status                      |
| ---------------------------------- | ---------------------------------- | ------------------------------ | --------------------------- |
| **Network Operations**             |                                    |                                |                             |
| Package manager (`apt-get update`) | ✅ Works perfectly                 | ❌ Fails with timeouts         | **VM-specific issue**       |
| External repository access         | ✅ Works (Docker, Microsoft repos) | ❌ Connection timeouts         | **VM-specific issue**       |
| HTTP connectivity                  | ✅ Fast (0-4s responses)           | ❌ Slow/timeout                | **VM-specific issue**       |
| HTTPS connectivity                 | ✅ Fast (0-4s responses)           | ❌ Slow/timeout                | **VM-specific issue**       |
| DNS resolution                     | ✅ Works correctly                 | ✅ Works correctly             | **Both work**               |
| **Docker Operations**              |                                    |                                |                             |
| Docker Hub connectivity            | ✅ Works perfectly                 | ❌ Registry timeouts           | **VM-specific issue**       |
| Container pulls                    | ✅ Fast downloads                  | ❌ Network failures            | **VM-specific issue**       |
| Docker daemon                      | ✅ Pre-installed & working         | ❌ Installation fails          | **VM-specific issue**       |
| **Platform Limitations**           |                                    |                                |                             |
| ICMP/Ping support                  | ❌ Blocked (Azure design)          | ❌ Blocked (Azure design)      | **Both blocked**            |
| Ping timeout behavior              | 12-14s timeouts                    | 12-14s timeouts                | **Same limitation**         |
| **Performance**                    |                                    |                                |                             |
| Network latency                    | Fast (0-4s)                        | Slow/timeout (30s+)            | **VM degrades performance** |
| Package installation               | Fast                               | Fails due to network           | **VM blocks operations**    |
| Resource usage                     | Direct access                      | Nested virtualization overhead | **VM adds overhead**        |

### Key Insights

- **✅ Direct runners work perfectly**: All network operations, Docker functionality, and package management work as expected
- **❌ VM environments fail consistently**: Network connectivity issues prevent most operations from completing
- **🔍 Root cause confirmed**: Issues are specific to nested virtualization (LXD VMs), not GitHub runner infrastructure
- **🎯 Solution focus**: Fix VM networking configuration, not runner-level workarounds

### Test Evidence

| Test Type               | Workflow                       | Results                    | Documentation                                                                                                                      |
| ----------------------- | ------------------------------ | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Direct Runner Control   | `test-runner-connectivity.yml` | ✅ ALL PASSED              | [Run #17649598526](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/runs/17649598526/job/50156726426) |
| VM Environment Baseline | `test-docker-standard-apt.yml` | ❌ Network failures        | [Documented issues](docs/network-connectivity-issues.md)                                                                           |
| Platform Limitation     | `test-ping-limitation.yml`     | ✅ Confirmed ICMP blocking | [Run #17649572799](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/runs/17649572799/job/50156646312) |

## Documented Issues

We have documented specific network connectivity failures in VM environments:

1. **Ubuntu Repository Connectivity** (HTTP): Package manager cannot reach `archive.ubuntu.com` and `security.ubuntu.com`
2. **Docker Registry Connectivity** (HTTPS): Cannot download GPG keys from `download.docker.com`

Both issues show consistent network timeouts and "Network is unreachable" errors in VMs. We're now testing if these same issues occur directly on GitHub runners to isolate whether this is VM-specific or runner-wide.

See [docs/network-connectivity-issues.md](docs/network-connectivity-issues.md) for detailed analysis.

## How to Use This Repository

### Running the Test Workflows

The repository includes two complementary workflows:

```bash
# VM-based test (reproduces Docker installation failures)
# Workflow: test-docker-standard-apt.yml

# Direct runner test (control test for comparison)
# Workflow: test-runner-connectivity.yml

# Ping limitation demonstration (shows ICMP blocking)
# Workflow: test-ping-limitation.yml

# All workflows run automatically on push/PR, or trigger manually
# View results at: https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions
```

### Important Platform Limitations

**⚠️ ICMP/Ping Limitation**: GitHub shared runners (hosted on Azure) do not support ICMP packets by design. This means:

- `ping` commands will always fail with 100% packet loss (confirmed with 12-14s timeouts)
- This is NOT a connectivity issue - HTTP/HTTPS traffic works normally (0-4s response times)
- Our network diagnostics use HTTP requests instead of ping
- ✅ **Confirmed by test**: [Ping Limitation Workflow Run](https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions/runs/17649572799/job/50156646312)
- Reference: [GitHub Actions Issue #1519](https://github.com/actions/runner-images/issues/1519#issuecomment-683790054)

### Understanding the Test Strategy

1. **Baseline VM Test**: Documents Docker installation failures in LXD VMs
2. **Control Runner Test**: Tests same operations directly on GitHub runner
3. **Comparison**: Isolates whether issues are VM-specific or runner-wide

### ✅ Key Discovery: Issues Are VM-Specific

Our comparative testing revealed that:

- **✅ Direct runner tests**: ALL network operations work perfectly
- **❌ VM-based tests**: Network connectivity failures for same operations
- **Conclusion**: Issues are caused by VM networking, not GitHub runner infrastructure

This means the solution focus should be on:

- LXD networking configuration
- VM network routing optimization
- Alternative VM networking approaches

### Using the Scripts Independently

Each script can be used standalone for testing:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run individual components
./scripts/install-lxd.sh
./scripts/launch-vm.sh my-test-vm ubuntu:24.04
./scripts/network-diagnostics.sh my-test-vm
./scripts/cleanup-vm.sh my-test-vm
```

See [scripts/README.md](scripts/README.md) for detailed script documentation.

### Creating New Test Workflows

To test different Docker installation approaches:

1. Copy the baseline workflow: `test-docker-standard-apt.yml`
2. Rename it descriptively (e.g., `test-docker-with-retries.yml`)
3. Modify only the Docker installation step
4. Keep all diagnostic and setup scripts unchanged for consistency

This ensures all approaches are tested under identical conditions.

## Related Issues and Resources

- [torrust-tracker-deploy-rust-poc](https://github.com/torrust/torrust-tracker-deploy-rust-poc) - Original project where issues were encountered
- [github-actions-virtualization-support](https://github.com/josecelano/github-actions-virtualization-support) - Documentation of available virtualization tools for GitHub Actions
- [GitHub Actions Runner Images #1187](https://github.com/actions/runner-images/issues/1187) - Networking flakiness on GitHub hosted runners
- [Docker in Docker on GitHub Actions](https://docs.github.com/en/actions/using-containerized-services/about-service-containers) - Official documentation

## Common Error Patterns

Based on initial research, common issues include:

1. **Network Timeouts**: Docker installation scripts timing out during package downloads
2. **DNS Resolution**: Problems resolving package repository URLs
3. **Service Startup**: Docker daemon failing to start properly in VM environments
4. **Resource Constraints**: Insufficient memory or disk space in nested VM setups
5. **Permission Issues**: Docker socket permissions in virtualized environments

## Contributing

If you're experiencing similar issues or have found solutions, please:

1. **Open an issue** describing your specific problem and environment
2. **Share workflow configurations** that reproduce the issue
3. **Submit pull requests** with working solutions or additional test cases
4. **Add documentation** for new approaches or findings

## Status

✅ **Problem Documentation Phase Complete**

We have successfully:

- Reproduced and documented specific network connectivity issues
- Created comprehensive diagnostic tooling
- Established a baseline test case for comparison
- Built reusable components for testing solutions

🔄 **Next Phase: Solution Development**

Now testing various approaches to overcome the documented network issues.

## License

This project is open source and available under the [MIT License](LICENSE).

## Maintainers

- [@josecelano](https://github.com/josecelano)

---

_This repository is part of the ongoing effort to improve CI/CD reliability when working with containerized applications on GitHub Actions._
