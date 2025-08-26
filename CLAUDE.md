# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains NixOS and Home Manager configurations for multiple systems. It uses a flake-based structure with hosts, modules, and secrets management.

## Systems

- **Khazad-dum**: Desktop/workstation with Hyprland and GNOME
- **Valinor**: Server configuration

## Common Commands

### Build and Switch Commands

The repository uses the `nh` utility for building and switching configurations:

```bash
# Build and switch to the current system configuration
nh os switch

# Build the current system configuration without switching
nh os build

# Build and switch to a specific host
nh os switch --hostname Khazad-dum

# Build and switch only home-manager configuration
nh home switch

# Show the diff between the current and new generations
nh diff
```

### Testing Configuration

To check if a configuration builds correctly:

```bash
# Test the system configuration
nh os build

# Test home-manager configuration
nh home build
```

### Updating Flake Inputs

```bash
# Update all flake inputs
nix flake update

# Update a specific input
nix flake lock --update-input nixpkgs
```

## Architecture

The repository is organized as follows:

- **flake.nix**: Main entry point defining inputs and outputs
- **hosts/**: Host-specific configurations
  - Each host has its own directory with configuration.nix and home-manager/
  - Home manager configurations include modules, packages, and services
- **modules/**: Shared modules that can be imported by hosts
  - Contains configurations for desktop environments, programs, and services
  - home-manager/ contains shared home-manager modules
- **secrets/**: Managed with sops-nix for encrypted secrets

## Key Features

- Uses Home Manager for user-specific configurations
- Supports multiple desktop environments (Hyprland, GNOME)
- Manages secrets with sops-nix
- Custom NixOS modules for reusability across hosts
- Uses secure boot with lanzaboote