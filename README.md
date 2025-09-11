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
│   └── test-docker-standard-apt.yml   # Baseline: Standard Docker apt installation
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

- **Baseline test workflow**: Reproduces standard Docker installation failures
- **Reusable scripts**: Modular components for testing different approaches
- **Network issue documentation**: Detailed analysis of connectivity failures
- **Diagnostic tooling**: Comprehensive logging and troubleshooting scripts

### 🔄 In Progress

- Testing alternative Docker installation methods
- Developing workarounds for network connectivity issues

### 📋 Planned

- Additional workflows testing different installation approaches:
  - Retry mechanisms with exponential backoff
  - IPv4-only configuration
  - Snap package installation
  - Docker convenience script installation
  - Pre-cached dependency installation

## Documented Issues

We have documented specific network connectivity failures:

1. **Ubuntu Repository Connectivity** (HTTP): Package manager cannot reach `archive.ubuntu.com` and `security.ubuntu.com`
2. **Docker Registry Connectivity** (HTTPS): Cannot download GPG keys from `download.docker.com`

Both issues show consistent network timeouts and "Network is unreachable" errors, confirming the GitHub Actions networking infrastructure problems.

See [docs/network-connectivity-issues.md](docs/network-connectivity-issues.md) for detailed analysis.

## How to Use This Repository

### Running the Baseline Test

The repository includes a baseline workflow that demonstrates the Docker installation failure:

```bash
# The workflow runs automatically on push/PR, or you can trigger it manually
# View results at: https://github.com/josecelano/test-docker-install-inside-vm-in-runner/actions
```

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
