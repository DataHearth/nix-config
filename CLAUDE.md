# CLAUDE.md

## Repository Overview

This repository contains NixOS and Home Manager configurations for multiple systems. It uses a flake-based structure with hosts, modules, and secrets management. The flake repository is always stored in `~/.config/nix-config`.

## Systems

### Khazad-dum
- **OS**: NixOS (migrated from Arch Linux)
- **Hardware**: Framework 16" laptop (AMD 7040, nixos-hardware module)
- **WM/DE**: Hyprland, Niri, GNOME
- **Display Manager**: greetd with tuigreet (regreet available)
- **Configuration**: Full NixOS system with Home Manager integration
- **Package Channel**: nixpkgs-unstable
- **Disk**: LUKS + ext4
- **Networking**: NetworkManager with iwd backend, nftables firewall
- **Host Files**:
  - `configuration.nix` - Main NixOS configuration
  - `hardware-configuration.nix` - Hardware-specific settings
  - `users.nix` - User account definitions
  - `locales.nix` - Locale settings
  - `home-manager/home.nix` - Main Home Manager configuration
  - `home-manager/modules.nix` - Enabled Home Manager modules
  - `home-manager/packages.nix` - Package list
  - `home-manager/services.nix` - User services configuration

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
# For Khazad-dum (NixOS system)
nh os build    # Build without switching
nh os switch   # Build and switch system

# For Valinor (NixOS system)
nh os build    # Build without switching
nh os switch   # Build and switch system

# Dry-run build verification (no root needed)
nix build .#nixosConfigurations.Khazad-dum.config.system.build.toplevel --dry-run
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
│   ├── khazad-dum/       # Framework laptop (NixOS)
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── users.nix
│   │   ├── locales.nix
│   │   └── home-manager/
│   │       ├── home.nix
│   │       ├── modules.nix
│   │       ├── packages.nix
│   │       └── services.nix
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
│   │   ├── hyprland/
│   │   ├── niri/
│   │   ├── nushell.nix
│   │   ├── ssh.nix
│   │   ├── swaync/
│   │   ├── waybar/
│   │   ├── yazi.nix
│   │   ├── zed-editor.nix
│   │   └── zellij/
│   ├── greetd.nix       # greetd display manager (tuigreet/regreet)
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
- **nixGL**: OpenGL wrapper for non-NixOS systems (legacy)
- **zjstatus**: Zellij status bar plugin
- **niri-flake**: Niri scrollable-tiling Wayland compositor
- **dms**: DankMaterialShell (niri status bar)
- **elephant**: Elephant Home Manager module
- **awww**: Awww wallpaper tool
- **nixos-hardware**: Hardware-specific NixOS modules

### NixOS Modules

Available modules in `modules/`:
- **greetd.nix**: Display manager with tuigreet/regreet switching, gnome-keyring PAM integration
- **nh.nix**: nh build/switch utility
- **nvidia.nix**: NVIDIA GPU configuration
- **passthrough.nix**: GPU passthrough for VMs

### Home Manager Modules

Available modules in `modules/home-manager/`:
- **alacritty.nix**: Terminal emulator configuration
- **ashell.nix**: Ashell status bar for niri
- **git.nix**: Git configuration
- **hyprland/**: Hyprland window manager with keybinds, autostart, etc.
- **niri/**: Niri scrollable-tiling compositor (NixOS/standalone HM compatible)
- **nushell.nix**: Nushell with carapace completions
- **ssh.nix**: SSH client configuration
- **swaync/**: Notification daemon
- **waybar/**: Waybar status bar
- **yazi.nix**: Yazi file manager
- **zed-editor.nix**: Zed editor with LSPs and extensions
- **zellij/**: Terminal multiplexer

## Development Workflow

1. Make changes to configuration files
2. Test build: `nh os build`
3. Review changes before applying
4. Switch configuration: `nh os switch`
5. Commit changes to git
6. If updating flake: `nix flake update` then rebuild

## Secrets Management

Secrets are managed using sops-nix:
- Configuration: `.sops.yaml`
- Encrypted secrets stored in `secrets/`
- Keys should be configured per host
- Secrets are decrypted at build time

## Notes

- Both systems use unstable channels for latest packages
- Custom nixvim configuration is maintained in separate repository
- The repository follows a modular structure for easy maintenance
- Khazad-dum uses nixos-hardware `framework-16-7040-amd` module for hardware support
- The niri module uses `isStandalone` detection (`options.programs.niri ? enable`) to be compatible with both NixOS and standalone Home Manager
- A legacy `homeConfigurations.Khazad-dum` output exists for standalone HM mode (pre-NixOS migration)
