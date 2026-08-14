# CLAUDE.md

## Repository Overview

This repository contains the NixOS and Home Manager configuration for a single machine. It uses a flake-based structure with hosts, modules, and secrets management. The flake repository is always stored in `~/.config/nix-config`.

## Systems

### khazad-dum
- **OS**: NixOS (migrated from Arch Linux)
- **Hardware**: Framework 16" laptop (AMD 7040, nixos-hardware module)
- **WM/DE**: Hyprland, GNOME
- **Display Manager**: greetd running ReGreet, hosted under a throwaway Hyprland so the greeter can be pinned to the internal panel
- **Configuration**: Full NixOS system with Home Manager integration
- **Package Channel**: nixpkgs-unstable
- **Disk**: LUKS + ext4
- **Networking**: NetworkManager with iwd backend, nftables firewall
- **Host Files**:
  - `configuration.nix` - Main NixOS configuration
  - `hardware-configuration.nix` - Hardware-specific settings
  - `disko.nix` - Declarative disk layout
  - `lanzaboote.nix` - Secure Boot
  - `network.nix` - NetworkManager/iwd, DNS, wlan0 operstate workaround
  - `modules.nix` - Enabled NixOS modules (`nixos_modules.*`)
  - `packages.nix` - System packages and `programs.*` toggles
  - `services.nix` - System services
  - `systemd.nix` - Systemd units
  - `users.nix` - User account definitions
  - `locales.nix` - Locale settings
  - `home-manager/home.nix` - Main Home Manager configuration
  - `home-manager/modules.nix` - Enabled Home Manager modules
  - `home-manager/packages.nix` - Package list
  - `home-manager/services.nix` - User services configuration
  - `home-manager/root.nix` - Home Manager config for the root user

## Common Commands

### Build and Switch Commands

The repository uses the `nh` utility for building and switching configurations:

```bash
nh os build    # Build without switching
nh os test     # Build and switch, but don't persist across reboots
nh os switch   # Build and switch system

# Dry-run build verification (no root needed)
nix build .#nixosConfigurations.khazad-dum.config.system.build.toplevel --dry-run

# Evaluate a single option without a full build
nix eval .#nixosConfigurations.khazad-dum.config.programs.steam.enable
```

### Updating Flake Inputs

```bash
# Update all flake inputs
nix flake update

# Update a specific input
nix flake update nixpkgs
nix flake update home-manager
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
│   └── khazad-dum/       # Framework laptop (NixOS)
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       ├── disko.nix, lanzaboote.nix, network.nix
│       ├── modules.nix, packages.nix, services.nix, systemd.nix
│       ├── users.nix, locales.nix
│       └── home-manager/
│           ├── home.nix
│           ├── modules.nix
│           ├── packages.nix
│           ├── services.nix
│           └── root.nix
├── modules/              # Shared modules
│   ├── home-manager/    # Home Manager modules (options under home_modules.<name>)
│   │   ├── alacritty.nix, atuin.nix, bat.nix, battery-notify.nix
│   │   ├── chromium.nix, direnv.nix, elephant.nix, git.nix
│   │   ├── jujutsu.nix, okular.nix, ssh.nix, starship.nix
│   │   ├── theme.nix, walker.nix, yazi.nix, zen-browser.nix, zsh.nix
│   │   ├── claude-code/, hyprland/, neovim/, swaync/, waybar/, zellij/
│   │   └── default.nix  # Module aggregator
│   └── nixos/           # NixOS system modules
│       ├── claude-desktop-cowork.nix, f5.nix, greetd.nix
│       ├── nautilus.nix, nh.nix
│       └── default.nix
├── packages/             # Custom package derivations
└── secrets/             # Encrypted secrets (sops-nix)
```

### Flake Inputs

- **nixpkgs** (nixos-unstable): NixOS packages
- **home-manager**: Home Manager (follows nixpkgs)
- **catppuccin**: Catppuccin theming module (system + HM)
- **sops-nix**: Secrets management
- **nixos-hardware**: Hardware-specific NixOS modules
- **zen-browser**: Zen Browser flake
- **nix-index-database**: Prebuilt nix-index database
- **disko**: Declarative disk partitioning
- **lanzaboote**: Secure Boot support
- **jj-lsp**: Jujutsu LSP server (overlay)

### NixOS Modules

Available modules in `modules/nixos/` (options under `nixos_modules.<name>`):
- **claude-desktop-cowork.nix**: Claude Desktop Cowork support (nix-ld, libglvnd)
- **f5.nix**: F5 VPN client and split-tunnel setup
- **greetd.nix**: Display manager running ReGreet on the internal panel, gnome-keyring PAM integration
- **nautilus.nix**: Nautilus file manager
- **nh.nix**: nh build/switch utility

### Home Manager Modules

Available modules in `modules/home-manager/`:
- **alacritty.nix**: Terminal emulator configuration
- **atuin.nix**: Atuin shell history
- **bat.nix**: Bat (cat replacement) with theme
- **battery-notify.nix**: Battery level notifications
- **chromium.nix**: Chromium browser
- **claude-code/**: Claude Code CLI with plugins, skills, and security defaults
- **direnv.nix**: Direnv environment management
- **elephant.nix**: Elephant data provider for Walker
- **git.nix**: Git configuration
- **hyprland/**: Hyprland window manager with keybinds, autostart, etc.
- **jujutsu.nix**: Jujutsu VCS configuration
- **neovim/**: Neovim editor
- **okular.nix**: Okular document viewer
- **ssh.nix**: SSH client configuration
- **starship.nix**: Starship shell prompt
- **swaync/**: Notification daemon
- **theme.nix**: Catppuccin Macchiato theme (centralized via catppuccin/nix)
- **walker.nix**: Walker application launcher
- **waybar/**: Waybar status bar
- **yazi.nix**: Yazi file manager
- **zellij/**: Terminal multiplexer
- **zen-browser.nix**: Zen Browser
- **zsh.nix**: Zsh shell with plugins

## Development Workflow

1. Make changes to configuration files
2. Test build: `nh os build`
3. Review changes before applying
4. Switch configuration: `nh os switch`
5. Seal the change with `jj describe` (this repo uses Jujutsu, not git)
6. If updating flake: `nix flake update` then rebuild

## Secrets Management

Secrets are managed using sops-nix:
- Configuration: `.sops.yaml`
- Encrypted secrets stored in `secrets/`
- Keys should be configured per host
- Secrets are decrypted at build time

## Notes

- Home Manager modules define options under `home_modules.<name>` namespace (e.g., `home_modules.claude-code.enable`), not directly under `programs`
- NixOS modules define options under the `nixos_modules.<name>` namespace
- The nixosConfiguration key is lowercase and matches the directory name: `nixosConfigurations.khazad-dum`
- There is exactly one host; this repo is not currently multi-machine
- The system uses the nixos-unstable channel for latest packages
- The repository follows a modular structure for easy maintenance
- khazad-dum uses nixos-hardware `framework-16-7040-amd` module for hardware support
