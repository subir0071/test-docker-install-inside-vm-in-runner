# Docker Installation Issues in VMs on GitHub Shared Runners

## Overview

This repository documents and investigates problems encountered when installing Docker inside virtual machines that are created within GitHub shared runners. This project was created to address specific issues found while working on the [torrust-tracker-deploy-rust-poc](https://github.com/torrust/torrust-tracker-deploy-rust-poc) project.

## Problem Statement

When running CI/CD workflows on GitHub shared runners that involve:

- Creating virtual machines (VMs) inside the runner environment
- Installing Docker within those VMs
- Using Docker for containerized deployments or testing

We encounter flaky network behavior and installation failures that make the CI/CD pipeline unreliable.

## Background

GitHub shared runners are known to have networking issues that can cause flaky behavior. This is a documented problem that has been reported in the GitHub Actions community:

- **Primary Issue**: [Networking is Flaky on GitHub Hosted Runners #1187](https://github.com/actions/runner-images/issues/1187)
- **Symptoms**:
  - Spurious timeouts when downloading files using `curl`
  - Network connectivity issues to localhost services
  - Intermittent failures that are difficult to reproduce locally
  - Higher failure rates during periods of heavy runner load

## Project Goals

1. **Document the Problem**: Create reproducible test cases that demonstrate Docker installation failures in VMs on GitHub runners
2. **Investigate Root Causes**: Analyze whether issues are due to:
   - Network connectivity problems
   - Resource constraints in nested virtualization
   - GitHub runner infrastructure limitations
   - Docker daemon startup issues in VM environments
3. **Develop Workarounds**: Find reliable solutions and best practices for Docker installation in GitHub runner VMs
4. **Share Solutions**: Provide the community with tested approaches to overcome these challenges

## Repository Structure

```text
├── README.md                           # This documentation
├── .github/workflows/                  # Test workflows for different installation methods
│   ├── test-docker-standard-apt.yml   # Baseline: Standard Docker apt installation in VM
│   ├── test-runner-connectivity.yml   # Control: Network tests directly on runner
│   └── test-ping-limitation.yml       # Platform test: Demonstrates ICMP blocking
├── scripts/                            # Reusable installation and diagnostic scripts
│   ├── install-lxd.sh                 # LXD installation and configuration
│   ├── launch-vm.sh                   # VM creation with configurable parameters
│   ├── wait-for-vm.sh                 # VM readiness checking with timeout
│   ├── test-vm-basic.sh               # Basic VM functionality tests
│   ├── network-diagnostics.sh         # Network connectivity diagnostics
│   ├── verify-docker.sh               # Docker installation verification
│   ├── docker-diagnostics.sh          # Docker troubleshooting diagnostics
│   ├── cleanup-vm.sh                  # VM cleanup and resource management
│   └── README.md                      # Scripts documentation and usage
└── docs/                              # Detailed documentation and findings
    └── network-connectivity-issues.md # Documented network failures and analysis
```

## Current Status

### ✅ Completed

- **Baseline test workflow**: Reproduces standard Docker installation failures in VMs
- **Control test workflow**: Tests network connectivity directly on GitHub runner
- **✅ Root cause identified**: Network issues are **VM-specific**, not runner infrastructure problems
- **Control test results**: Direct runner connectivity tests **ALL PASSED** (September 11, 2025)
- **✅ Ping limitation confirmed**: Test workflow verified ICMP is blocked in GitHub runners (Azure design)
- **Platform limitation results**: Ping tests failed (12-14s timeouts), HTTP tests passed (0-4s)
- **Refactored connectivity tests**: All workflows use HTTP-based connectivity testing only
- **Reusable scripts**: Modular components for testing different approaches
- **Network issue documentation**: Detailed analysis of connectivity failures
- **Diagnostic tooling**: Comprehensive logging and troubleshooting scripts

### 🔄 In Progress

- Developing VM networking solutions (LXD configuration, network routing)
- Testing alternative Docker installation methods for VM environments
- Creating workarounds for VM-specific network limitations

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
