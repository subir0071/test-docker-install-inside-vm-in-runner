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
├── README.md                    # This documentation
├── .github/workflows/           # Test workflows to reproduce issues
├── scripts/                     # Installation and diagnostic scripts
├── docs/                        # Detailed documentation and findings
├── examples/                    # Working examples and workarounds
└── tests/                       # Test cases and validation scripts
```

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

1. Open an issue describing your specific problem
2. Share your workflow configurations that reproduce the issue
3. Submit pull requests with working solutions or improvements
4. Share diagnostic information and logs

## Status

🚧 **This project is in active development** 🚧

We are currently in the initial documentation and problem reproduction phase. Test cases and solutions will be added as we investigate further.

## License

This project is open source and available under the [MIT License](LICENSE).

## Maintainers

- [@josecelano](https://github.com/josecelano)

---

_This repository is part of the ongoing effort to improve CI/CD reliability when working with containerized applications on GitHub Actions._
