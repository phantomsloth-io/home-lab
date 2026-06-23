# Home Lab Cluster

A modernized GitOps-based home lab configuration for a Raspberry Pi 4 K3s cluster.

## Hardware
- 3x Raspberry Pi 4b (8GB) with POE Hats
- TP-Link POE Switch
- Storage: High-end SD cards or USB SSDs recommended

## Quick Start (Bootstrap)

1. **Prepare Nodes**: Ensure all nodes are running a modern OS (such as Ubuntu 24.04 or Raspberry Pi OS 64-bit).
   - **Raspberry Pi**: Enable cgroups by adding `cgroup_memory=1 cgroup_enable=memory` to `/boot/firmware/cmdline.txt`.
   - **Ubuntu VMs / x86_64 Hardware**: No manual cgroups configuration is required.
2. **Bootstrap**: Run the bootstrap script on your primary node. The script is fully interactive and will prompt you for configuration parameters, using auto-detected values as defaults:
   ```bash
   chmod +x tools/bootstrap.sh
   ./tools/bootstrap.sh
   ```
3. **Repository Configuration**: Since this is a public repository, you can use the HTTPS URL to avoid configuring SSH keys.
4. **Access UI**: Navigate to the Argo CD LoadBalancer IP address that you specified during configuration, and log in using the initial admin credentials printed at the end of the bootstrap script.

### Virtual Machine / Alternative Hardware Deployment
You can deploy this configuration on standard x86_64 Ubuntu virtual machines. Clone this repository directly onto your virtual machine:
```bash
git clone https://github.com/phantomsloth-io/home-lab.git
cd home-lab
chmod +x tools/bootstrap.sh
./tools/bootstrap.sh
```
The script will auto-detect the virtual machine network settings and use the correct binaries for your CPU architecture.

## Architecture

### Core Components
- **K3s**: Lightweight Kubernetes distribution.
- **Argo CD**: GitOps controller (v2.13+).
- **MetalLB**: Layer 2 LoadBalancer (v0.14+).

### GitOps Structure
- `argocd/infra`: Infrastructure components (MetalLB, Monitoring, etc.).
- `argocd/apps`: User applications (Plex, Discord Bot, etc.).
- `tools/`: Utility scripts for installation and cluster management.

## Technologies Used

### CI/CD
- Argo CD (v2.13+)
- GitHub Actions
- Helm

### Infrastructure
- MetalLB (v0.14+)

### Monitoring & Observability
- Vector
- Datadog (Optional)
- New Relic (Optional)
- Prometheus / Grafana (Planned/Template)

## Applications
- [Discord Bot](https://github.com/phantomsloth-io/discord-bot): Custom bot.
- **Plex**: Media Server.
- **Nginx**: Basic web server.
