# Project Plan: Simple and Interactive Setup Procedure

This document outlines the plan to refactor the bootstrap and reset scripts for the home lab cluster, ensuring a dynamic, interactive, and robust installation process.

## Objectives

1. **Interactive Bootstrap Script (`tools/bootstrap.sh`)**
   - Automatically detect the Git repository remote URL from the local configuration.
   - Attempt to auto-detect the control plane IP address of the node.
   - Provide interactive prompts for all configuration parameters, with detected values as default options.
   - Add verification checks for required dependencies (`kubectl`, `curl`, `git`).

2. **Interactive Reset Script (`tools/reset-argo.sh`)**
   - Resolve all identified syntax and logical errors.
   - Enhance command-line interface output formatting and readability.
   - Ensure the fallback values for namespace inputs are correctly utilized.

3. **README.md Documentation**
   - Update the installation guide to reflect the new interactive procedure.
   - Add a deployment section for non-Raspberry Pi devices, such as Ubuntu virtual machines.

---

## Detailed Tasks

### Task 1: Refactor `tools/bootstrap.sh`
- **Detection Logic**:
  - Detect repository URL: Use `git remote get-url origin` with a fallback to `https://github.com/phantomsloth-io/home-lab.git`.
  - Detect Host IP: Implement a method to extract the default route IP address (for example, `ip route get 1.1.1.1` or `hostname -I`).
- **Prompts**:
  - Request Control Plane IP (default to detected host IP).
  - Request Argo CD LoadBalancer IP (default to a predicted IP in the same subnet, or a default value such as `10.0.0.238`).
  - Request Git Repository URL (default to detected URL).
- **Validation**:
  - Verify that required commands (`curl`, `kubectl`, `git`) are installed.

### Task 2: Fix and Optimize `tools/reset-argo.sh`
- Correct the syntax error on line 12: `base64 -d echo` to `base64 -d; echo`.
- Correct the line 15 `read` command to use the `-p` parameter.
- Correct the line 16 condition spacing: `if [ "$resetPass" = "y" ]; then`.
- Correct lines 20 and 21 to use `read -s -p`.
- Fix the `jq` parsing errors on lines 34 and 35.
- Fix namespace variable inconsistency on line 55 and line 60.

### Task 3: Update `README.md`
- Clarify that the bootstrap script is now interactive and will prompt for the necessary configuration.
- Add installation guidelines for Ubuntu virtual machines, noting that manual cgroups configuration is not required for these platforms.

### Task 4: Resolve Merge Conflicts
- Merge conflicting sections in `README.md` by combining the quick-start and VM deployment documentation with the detailed technology stacks and external links added to the `main` branch.

### Task 5: Resolve Helm Template Nil Pointer Index Errors
- Declare all optional infrastructure keys in `argocd/infra/values.yaml` to ensure Helm can render templates safely without throwing nil pointer index exceptions.

---

## Verification Plan

- Perform shell syntax checks (`bash -n`) on the modified scripts.
- Present the modifications to the user for final review.
