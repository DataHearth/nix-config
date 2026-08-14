# nix-config

Personal NixOS and Home Manager configuration, managed with Nix flakes.

## Overview

This repository holds the declarative configuration for a single machine:

- **khazad-dum**: Framework 16" laptop (AMD 7040) running NixOS with integrated Home Manager, on the `nixos-unstable` channel

## Features

- Flake-based configuration for reproducibility
- Modular design: NixOS modules under `nixos_modules.<name>`, Home Manager modules under `home_modules.<name>`
- Home Manager wired into the NixOS system (no standalone HM profile)
- Declarative disk layout with disko (LUKS + ext4)
- Secure Boot via lanzaboote
- Secrets management with sops-nix
- Hyprland window manager with hypridle, hyprlock and hyprshot
- Catppuccin Macchiato theming, centralised through catppuccin/nix
- Terminal multiplexer (Zellij) and emulator (Alacritty) configurations

## Quick Start

### Prerequisites

- Nix with flakes enabled
- `nh` (Nix Helper) for building and switching
- For secrets: sops-nix set up with the appropriate age keys

### Building

```bash
nh os build    # Build without switching
nh os test     # Build and switch, but don't persist across reboots
nh os switch   # Build and switch the system

# Dry-run build verification (no root needed)
nix build .#nixosConfigurations.khazad-dum.config.system.build.toplevel --dry-run

# Evaluate a single option without a full build
nix eval .#nixosConfigurations.khazad-dum.config.programs.steam.enable
```

### Updating Dependencies

```bash
# Update all flake inputs
nix flake update

# Update a specific input
nix flake update nixpkgs
```

### Cleaning Up

```bash
# Clean old generations and optimize the Nix store
nh clean all

# Clean only the user profile
nh clean user

# Clean only the system profile
nh clean system
```

## Directory Structure

```
nix-config/
├── flake.nix                      # Main flake configuration
├── flake.lock                     # Locked dependency versions
├── .sops.yaml                     # Secrets configuration
├── hosts/
│   └── khazad-dum/                # Framework 16" laptop
│       ├── configuration.nix      # Main NixOS configuration
│       ├── hardware-configuration.nix
│       ├── disko.nix              # Declarative disk layout
│       ├── lanzaboote.nix         # Secure Boot
│       ├── network.nix            # NetworkManager/iwd, DNS
│       ├── modules.nix            # Enabled NixOS modules
│       ├── packages.nix           # System packages
│       ├── services.nix           # System services
│       ├── systemd.nix            # Systemd units
│       ├── users.nix              # User accounts
│       ├── locales.nix            # Locale settings
│       └── home-manager/
│           ├── home.nix           # Home Manager entry point
│           ├── modules.nix        # Enabled Home Manager modules
│           ├── packages.nix       # User packages
│           ├── services.nix       # User services
│           └── root.nix           # Home Manager config for root
├── modules/
│   ├── home-manager/              # Options under home_modules.<name>
│   │   ├── alacritty.nix          # Terminal emulator
│   │   ├── claude-code/           # Claude Code CLI
│   │   ├── hyprland/              # Hyprland, hypridle, hyprlock, hyprshot
│   │   ├── neovim/                # Editor
│   │   ├── swaync/                # Notifications
│   │   ├── waybar/                # Status bar
│   │   ├── zellij/                # Terminal multiplexer
│   │   └── …                      # git, jujutsu, ssh, starship, zsh, …
│   └── nixos/                     # Options under nixos_modules.<name>
│       ├── claude-desktop-cowork.nix
│       ├── f5.nix                 # F5 VPN client and split tunnel
│       ├── greetd.nix             # Display manager
│       ├── nautilus.nix           # File manager
│       └── nh.nix                 # nh utility
├── packages/                      # Custom package derivations
│   ├── claude-desktop.nix
│   ├── f5epi.nix, f5vpn.nix
│   └── update.sh                  # Refreshes pinned versions/checksums
├── docs/plans/                    # Design and migration notes
└── secrets/                       # Encrypted secrets
```

## System Configuration

### khazad-dum

Framework 16" laptop (AMD 7040) running NixOS, using the nixos-hardware
`framework-16-7040-amd` module.

**Environment:**
- OS: NixOS (`nixos-unstable`)
- WM: Hyprland (primary) / GNOME
- Display Manager: greetd running ReGreet
- Terminal: Alacritty
- Shell: zsh with starship
- Multiplexer: Zellij
- Editor: Neovim
- Launcher: Walker, backed by elephant
- Status bar: Waybar
- Notifications: swaync

**Storage and boot:**
- LUKS + ext4, partitioned declaratively with disko
- systemd-boot with Secure Boot via lanzaboote

**Networking:**
- NetworkManager with the iwd backend
- nftables firewall

## Flake Inputs

| Input | Description |
|-------|-------------|
| nixpkgs | NixOS packages (`nixos-unstable`) |
| home-manager | Home Manager (follows nixpkgs) |
| catppuccin | Catppuccin theming for both system and Home Manager |
| sops-nix | Secrets management |
| nixos-hardware | Hardware-specific NixOS modules |
| zen-browser | Zen Browser |
| nix-index-database | Prebuilt nix-index database |
| disko | Declarative disk partitioning |
| lanzaboote | Secure Boot support |
| jj-lsp | Jujutsu LSP server (applied as an overlay) |

## Secrets Management

Secrets are encrypted using sops-nix:

1. Configure age keys in `.sops.yaml`
2. Store encrypted secrets in `secrets/`
3. Reference secrets in configurations
4. Secrets are decrypted at build time

## Development

### Making Changes

1. Edit configuration files
2. Test build without activating:
   ```bash
   nh os build
   ```
3. Review changes
4. Activate the configuration:
   ```bash
   nh os switch
   ```
5. Commit to version control

### Adding Modules

1. Create the module in `modules/home-manager/` or `modules/nixos/`
2. Add it to the matching `default.nix` aggregator
3. Enable it from `hosts/khazad-dum/modules.nix` or
   `hosts/khazad-dum/home-manager/modules.nix`

### Managing Secrets

1. Create or edit the secret file
2. Encrypt it with sops:
   ```bash
   sops secrets/filename.yaml
   ```
3. Reference it in the configuration
4. Rebuild the system

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [sops-nix](https://github.com/Mic92/sops-nix)

## License

See [LICENSE](LICENSE) file for details.
