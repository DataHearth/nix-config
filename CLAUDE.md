# CLAUDE.md

## Repository Overview

This repository contains NixOS and Home Manager configurations for multiple systems. It uses a flake-based structure with hosts, modules, and secrets management. The flake repository is always stored in `~/.config/nix-config`.

## Systems

- **Khazad-dum**: Arch Linux OS running on a laptop Framework 16". It has Hyprland and GNOME as WM/DE. It uses GDM as display manager.
- **Valinor**: NixOS homelab/production server

## Common Commands

### Build and Switch Commands

The repository uses the `nh` utility for building and switching configurations:

```bash
# Build the current system configuration without switching
nh os build

# Build and switch to the current system configuration
nh os switch

# Build home-manager configuration
home-manager build

# Build and switch home-manager configuration
home-manager switch
```

### Updating Flake Inputs

```bash
# Update all flake inputs
nix flake update

# Update a specific input
nix flake lock --update-input INPUT
```

## Architecture

The repository is organized as follows:

- **flake.nix**: Main entry point defining inputs and outputs
- **hosts/**: Host-specific configurations. Each host has its own directory with configuration
- **modules/**: Shared modules that can be imported by hosts
- **secrets/**: Managed with sops-nix for encrypted secrets
