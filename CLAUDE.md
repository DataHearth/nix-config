# CLAUDE.md

## Repository Overview

This repository contains NixOS and Home Manager configurations for multiple systems. It uses a flake-based structure with hosts, modules, and secrets management. The flake repository is always stored in `~/.config/nix-config`.

## Systems

### Khazad-dum
- **OS**: Arch Linux (non-NixOS)
- **Hardware**: Framework 16" laptop
- **WM/DE**: Hyprland (primary) and GNOME
- **Display Manager**: GDM or hyprlock (lockscreen)
- **Configuration**: Home Manager only (no NixOS)
- **Package Channel**: nixpkgs-unstable
- **Host Files**:
  - `home.nix` - Main Home Manager configuration
  - `modules.nix` - Enabled Home Manager modules
  - `packages.nix` - Package list
  - `services.nix` - User services configuration

### Valinor
- **OS**: NixOS
- **Purpose**: Homelab/production server
- **Configuration**: Full NixOS system with Home Manager integration
- **Package Channel**: nixpkgs-unstable
- **Host Files**:
  - `configuration.nix` - Main NixOS configuration
  - `hardware-configuration.nix` - Hardware-specific settings
  - `packages.nix` - System packages
  - `services.nix` - System services
  - `systemd.nix` - Systemd units configuration
  - `users.nix` - User account definitions
  - `locales.nix` - Locale settings
  - `home-manager/` - Home Manager configuration for users

## Common Commands

### Build and Switch Commands

The repository uses the `nh` utility for building and switching configurations:

```bash
# For Khazad-dum (Home Manager only)
nh home build -c Khazad-dum
nh home switch -c Khazad-dum

# For Valinor (NixOS system)
nh os build    # Build without switching
nh os switch   # Build and switch system
```

### Updating Flake Inputs

```bash
# Update all flake inputs
nix flake update

# Update a specific input
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager
```

### Cleaning Up

```bash
# Clean old generations and optimize store
nh clean all

# Clean user profile (Home Manager)
nh clean user

# Clean system profile (NixOS)
nh clean system
```

## Architecture

### Directory Structure

```
nix-config/
├── flake.nix              # Main flake definition
├── flake.lock             # Locked dependency versions
├── .sops.yaml             # SOPS configuration for secrets
├── hosts/                 # Host-specific configurations
│   ├── khazad-dum/       # Framework laptop (Home Manager)
│   │   ├── home.nix
│   │   ├── modules.nix
│   │   ├── packages.nix
│   │   └── services.nix
│   └── valinor/          # NixOS server
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       ├── packages.nix
│       ├── services.nix
│       ├── systemd.nix
│       ├── users.nix
│       ├── locales.nix
│       └── home-manager/
├── modules/              # Shared modules
│   ├── home-manager/    # Home Manager modules
│   │   ├── alacritty.nix
│   │   ├── ashell.nix
│   │   ├── git.nix
│   │   ├── hyprland.nix
│   │   ├── hyprlock.nix
│   │   ├── ssh.nix
│   │   ├── swaync/
│   │   └── zellij/
│   ├── nh.nix           # nh utility module
│   ├── nvidia.nix       # NVIDIA configuration
│   └── passthrough.nix  # GPU passthrough
└── secrets/             # Encrypted secrets (sops-nix)
```

### Flake Inputs

- **nixpkgs** (25.05): Stable NixOS packages
- **nixpkgs-unstable**: Latest packages
- **home-manager** (25.05): Stable Home Manager
- **home-manager-unstable**: Latest Home Manager
- **sops-nix**: Secrets management
- **nixvim**: Custom Neovim configuration
- **nixGL**: OpenGL wrapper for non-NixOS systems
- **zjstatus**: Zellij status bar plugin

### Home Manager Modules

Available modules in `modules/home-manager/`:
- **alacritty.nix**: Terminal emulator configuration
- **ashell.nix**: Shell environment (likely atuin-based shell)
- **git.nix**: Git configuration
- **hyprland.nix**: Hyprland window manager with keybinds, autostart, etc.
- **hyprlock.nix**: Hyprland lockscreen
- **ssh.nix**: SSH client configuration
- **swaync/**: Notification daemon
- **zellij/**: Terminal multiplexer

## Development Workflow

1. Make changes to configuration files
2. Test build: `nh home build -c Khazad-dum` or `nh os build`
3. Review changes before applying
4. Switch configuration: `nh home switch -c Khazad-dum` or `nh os switch`
5. Commit changes to git
6. If updating flake: `nix flake update` then rebuild

## Secrets Management

Secrets are managed using sops-nix:
- Configuration: `.sops.yaml`
- Encrypted secrets stored in `secrets/`
- Keys should be configured per host
- Secrets are decrypted at build time

## Notes

- Khazad-dum uses nixGL for OpenGL support on non-NixOS Arch Linux
- Both systems use unstable channels for latest packages
- Custom nixvim configuration is maintained in separate repository
- The repository follows a modular structure for easy maintenance
