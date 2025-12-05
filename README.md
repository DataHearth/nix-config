# nix-config

Personal NixOS and Home Manager configurations for multiple systems, managed with Nix flakes.

## Overview

This repository contains declarative configurations for my development environments and systems:

- **Khazad-dum**: Framework 16" laptop running Arch Linux with Home Manager, featuring Hyprland and GNOME
- **Valinor**: NixOS homelab server with full system configuration

## Features

- Flake-based configuration for reproducibility
- Modular design with reusable components
- Home Manager integration for user environment management
- Secrets management with sops-nix
- Custom Neovim configuration via nixvim
- Hyprland window manager setup with hyprlock
- Terminal multiplexer (Zellij) and emulator (Alacritty) configurations
- Shell environment with custom tooling (ashell)

## Quick Start

### Prerequisites

- Nix with flakes enabled
- For Home Manager configurations: `nh` utility (Nix Helper)
- For secrets: sops-nix setup with appropriate keys

### Building Configurations

#### Khazad-dum (Home Manager)

```bash
# Build configuration
nh home build -c Khazad-dum

# Build and activate
nh home switch -c Khazad-dum
```

#### Valinor (NixOS)

```bash
# Build system configuration
nh os build

# Build and activate
nh os switch
```

### Updating Dependencies

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
```

### Cleaning Up

```bash
# Clean old generations and optimize Nix store
nh clean all

# Clean only user profile
nh clean user

# Clean only system profile
nh clean system
```

## Directory Structure

```
nix-config/
├── flake.nix                 # Main flake configuration
├── flake.lock                # Locked dependency versions
├── .sops.yaml                # Secrets configuration
├── hosts/                    # Host-specific configurations
│   ├── khazad-dum/          # Framework laptop
│   │   ├── home.nix         # Home Manager entry point
│   │   ├── modules.nix      # Enabled modules
│   │   ├── packages.nix     # User packages
│   │   └── services.nix     # User services
│   └── valinor/             # NixOS server
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       ├── packages.nix
│       ├── services.nix
│       ├── systemd.nix
│       ├── users.nix
│       ├── locales.nix
│       └── home-manager/
├── modules/                  # Shared modules
│   ├── home-manager/        # Home Manager modules
│   │   ├── alacritty.nix   # Terminal emulator
│   │   ├── ashell.nix      # Shell environment
│   │   ├── git.nix         # Git configuration
│   │   ├── hyprland.nix    # Hyprland WM
│   │   ├── hyprlock.nix    # Lockscreen
│   │   ├── ssh.nix         # SSH client
│   │   ├── swaync/         # Notifications
│   │   └── zellij/         # Terminal multiplexer
│   ├── nh.nix              # nh utility
│   ├── nvidia.nix          # NVIDIA drivers
│   └── passthrough.nix     # GPU passthrough
└── secrets/                 # Encrypted secrets
```

## System Configurations

### Khazad-dum

Framework 16" laptop configuration running on Arch Linux (non-NixOS) with Home Manager.

**Environment:**
- OS: Arch Linux
- WM: Hyprland (primary) / GNOME
- Display Manager: GDM or hyprlock
- Terminal: Alacritty
- Shell: Custom ashell configuration
- Multiplexer: Zellij
- Editor: Neovim (nixvim)

**Special Features:**
- nixGL for OpenGL support on non-NixOS
- Hyprland keybinds including suspend/hibernate
- Notification system with swaync

### Valinor

NixOS server configuration for homelab/production use.

**Environment:**
- OS: NixOS
- Purpose: Server/homelab
- Configuration: Full system + Home Manager

## Flake Inputs

| Input | Version | Description |
|-------|---------|-------------|
| nixpkgs | 25.05 | Stable NixOS packages |
| nixpkgs-unstable | unstable | Latest packages |
| home-manager | 25.05 | Stable Home Manager |
| home-manager-unstable | unstable | Latest Home Manager |
| sops-nix | latest | Secrets management |
| nixvim | custom | Personal Neovim config |
| nixGL | latest | OpenGL for non-NixOS |
| zjstatus | latest | Zellij status bar |

## Secrets Management

Secrets are encrypted using sops-nix:

1. Configure age keys in `.sops.yaml`
2. Store encrypted secrets in `secrets/`
3. Reference secrets in configurations
4. Secrets are automatically decrypted at build time

## Development

### Making Changes

1. Edit configuration files
2. Test build without activating:
   ```bash
   nh home build -c Khazad-dum  # or nh os build
   ```
3. Review changes
4. Activate configuration:
   ```bash
   nh home switch -c Khazad-dum  # or nh os switch
   ```
5. Commit to version control

### Adding Modules

1. Create module in `modules/home-manager/` or `modules/`
2. Import module in host configuration
3. Configure module options as needed

### Managing Secrets

1. Create/edit secret file
2. Encrypt with sops:
   ```bash
   sops secrets/filename.yaml
   ```
3. Reference in configuration
4. Rebuild system

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [sops-nix](https://github.com/Mic92/sops-nix)

## License

See [LICENSE](LICENSE) file for details.