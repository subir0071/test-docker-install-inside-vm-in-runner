# Scripts Directory

This directory contains reusable bash scripts for testing Docker installation in VMs on GitHub runners. These scripts are extracted from workflow steps to make them easily reusable across different workflows that test various approaches to solving Docker installation issues.

## Available Scripts

### Core VM Management Scripts

#### `install-lxd.sh`

Installs and configures LXD for testing.

- Installs LXD via snap
- Initializes LXD with default settings
- Configures permissions for CI environment
- Tests basic LXD functionality

**Usage:**

```bash
./scripts/install-lxd.sh
```

#### `launch-vm.sh`

Launches an LXD VM for testing.

**Usage:**

```bash
./scripts/launch-vm.sh [VM_NAME] [VM_IMAGE]
# Default: ./scripts/launch-vm.sh test-vm ubuntu:24.04
```

**Parameters:**

- `VM_NAME` (optional): Name for the VM (default: `test-vm`)
- `VM_IMAGE` (optional): LXD image to use (default: `ubuntu:24.04`)

#### `wait-for-vm.sh`

Waits for VM to be ready with comprehensive readiness checks.

**Usage:**

```bash
./scripts/wait-for-vm.sh [VM_NAME] [TIMEOUT]
# Default: ./scripts/wait-for-vm.sh test-vm 300
```

**Parameters:**

- `VM_NAME` (optional): Name of the VM to wait for (default: `test-vm`)
- `TIMEOUT` (optional): Timeout in seconds (default: `300`)

#### `cleanup-vm.sh`

Cleans up VM resources (stops and deletes VM).

**Usage:**

```bash
./scripts/cleanup-vm.sh [VM_NAME]
# Default: ./scripts/cleanup-vm.sh test-vm
```

**Parameters:**

- `VM_NAME` (optional): Name of the VM to cleanup (default: `test-vm`)

### Testing and Diagnostic Scripts

#### `test-vm-basic.sh`

Tests basic VM functionality (connectivity, OS info).

**Usage:**

```bash
./scripts/test-vm-basic.sh [VM_NAME]
# Default: ./scripts/test-vm-basic.sh test-vm
```

#### `network-diagnostics.sh`

Runs comprehensive network connectivity diagnostics inside the VM.

- Tests network interfaces and routing
- Checks DNS configuration and resolution
- Tests connectivity to key hosts (Ubuntu repos, Docker registry)

**Usage:**

```bash
./scripts/network-diagnostics.sh [VM_NAME]
# Default: ./scripts/network-diagnostics.sh test-vm
```

#### `verify-docker.sh`

Verifies Docker installation and functionality.

- Checks Docker version and service status
- Tests Docker functionality with hello-world container

**Usage:**

```bash
./scripts/verify-docker.sh [VM_NAME]
# Default: ./scripts/verify-docker.sh test-vm
```

#### `docker-diagnostics.sh`

Runs Docker installation diagnostics (useful when installation fails).

- Shows Docker daemon status and logs
- Displays system resources (disk, memory)
- Tests network connectivity to Docker repositories

**Usage:**

```bash
./scripts/docker-diagnostics.sh [VM_NAME]
# Default: ./scripts/docker-diagnostics.sh test-vm
```

## Example Workflow Usage

Here's how to use these scripts in a GitHub Actions workflow:

```yaml
name: Test Docker Installation
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install LXD
        run: ./scripts/install-lxd.sh

      - name: Launch VM
        run: ./scripts/launch-vm.sh

      - name: Wait for VM
        run: ./scripts/wait-for-vm.sh

      - name: Network diagnostics
        run: ./scripts/network-diagnostics.sh

      - name: Install Docker (your custom approach)
        run: |
          # Your custom Docker installation logic here
          sudo lxc exec test-vm -- bash -c "your-docker-install-commands"

      - name: Verify Docker
        run: ./scripts/verify-docker.sh

      - name: Docker diagnostics (on failure)
        if: always()
        run: ./scripts/docker-diagnostics.sh

      - name: Cleanup
        if: always()
        run: ./scripts/cleanup-vm.sh
```

## Creating New Workflows

When creating new workflows to test different Docker installation approaches:

1. **Copy the base workflow structure** using the scripts above
2. **Replace only the Docker installation step** with your approach
3. **Keep all other scripts unchanged** for consistency
4. **Use descriptive workflow names** like:
   - `test-docker-with-retries.yml`
   - `test-docker-ipv4-only.yml`
   - `test-docker-snap.yml`
   - `test-docker-static-binaries.yml`

This approach ensures all workflows are comparable and only differ in the Docker installation method being tested.

## Script Requirements

All scripts:

- Use `set -e` for fail-fast behavior
- Accept VM name as first parameter (defaults to `test-vm`)
- Include comprehensive error handling with `|| true` where appropriate
- Provide verbose output for debugging
- Are executable (`chmod +x scripts/*.sh`)

## Troubleshooting

If scripts fail to execute, ensure they are executable:

```bash
chmod +x scripts/*.sh
```

For debugging, you can run scripts individually with verbose output:

```bash
bash -x ./scripts/script-name.sh
```
