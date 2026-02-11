# Khazad-dum Arch to NixOS Migration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert khazad-dum (Framework 16" laptop) from Arch Linux + standalone Home Manager to a full NixOS system with integrated Home Manager.

**Architecture:** Add a `nixosConfigurations.Khazad-dum` flake output that wraps the existing Home Manager config inside a NixOS system. System-level concerns (boot, networking, audio, display manager) live in new NixOS host files. Existing Home Manager modules stay unchanged — only the host-level files that reference nixGL get cleaned up. A new `modules/greetd.nix` NixOS module handles display manager config with tuigreet/regreet switching.

**Tech Stack:** NixOS 25.11, nixpkgs-unstable, Home Manager (unstable), nixos-hardware (Framework 16), sops-nix, niri-flake, Hyprland, Gnome, greetd

---

## Task 1: Add nixos-hardware flake input

**Files:**
- Modify: `flake.nix:2-40` (inputs section)

**Step 1: Add the nixos-hardware input**

In `flake.nix`, add to the inputs block:

```nix
nixos-hardware.url = "github:NixOS/nixos-hardware";
```

No `follows` needed — nixos-hardware pins its own nixpkgs for module compatibility.

**Step 2: Verify flake locks**

Run: `nix flake lock --update-input nixos-hardware`
Expected: `flake.lock` updated with nixos-hardware entry.

**Step 3: Commit**

```bash
git add flake.nix flake.lock
git commit -m "chore: add nixos-hardware flake input"
```

---

## Task 2: Create greetd NixOS module

**Files:**
- Create: `modules/greetd.nix`

**Step 1: Create the module**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.greetd;

  enable = lib.mkEnableOption "greetd display manager";
  greeter = lib.mkOption {
    type = lib.types.enum [
      "tuigreet"
      "regreet"
    ];
    default = "tuigreet";
    description = "Greeter to use with greetd";
  };
in
{
  options.nixos_modules.greetd = {
    inherit enable greeter;
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session.command = lib.mkIf (cfg.greeter == "tuigreet") (
        "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
      );
    };

    programs.regreet = lib.mkIf (cfg.greeter == "regreet") {
      enable = true;
    };

    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
  };
}
```

**Step 2: Verify syntax**

Run: `nix-instantiate --parse modules/greetd.nix`
Expected: Parses without error.

**Step 3: Commit**

```bash
git add modules/greetd.nix
git commit -m "feat: add greetd NixOS module with tuigreet/regreet support"
```

---

## Task 3: Create khazad-dum NixOS system configuration

**Files:**
- Create: `hosts/khazad-dum/configuration.nix`
- Create: `hosts/khazad-dum/hardware-configuration.nix` (placeholder)
- Create: `hosts/khazad-dum/users.nix`
- Create: `hosts/khazad-dum/locales.nix`

### Step 1: Create `hosts/khazad-dum/configuration.nix`

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./users.nix
    ./locales.nix
    ./services.nix
    ../../modules/nh.nix
    ../../modules/greetd.nix
  ];

  time.timeZone = "Europe/Paris";
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "datahearth"
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.luks.devices."cryptroot" = {
      device = "/dev/disk/by-partlabel/LUKS";
    };
  };

  networking = {
    hostName = "Khazad-dum";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless.iwd.enable = true;
    nftables.enable = true;
    firewall.enable = true;
  };

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Power management
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Desktop sessions
  programs.hyprland.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Display manager
  nixos_modules.greetd = {
    enable = true;
    greeter = "tuigreet";
  };

  # Docker
  virtualisation.docker.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # nh
  nixos_modules.nh = {
    enable = true;
    settings.flake = "${config.users.users.datahearth.home}/.config/nix-config";
  };
}
```

### Step 2: Create `hosts/khazad-dum/hardware-configuration.nix` (placeholder)

This file will be regenerated with `nixos-generate-config` during installation. Placeholder for now:

```nix
# Placeholder — regenerate during NixOS installation with:
#   nixos-generate-config --root /mnt
# Then copy the generated hardware-configuration.nix here.
{
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  hardware.cpu.amd.updateMicrocode = true;
}
```

### Step 3: Create `hosts/khazad-dum/users.nix`

```nix
{ pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    users.datahearth = {
      useDefaultShell = true;
      isNormalUser = true;
      description = "Antoine Langlois";
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
        "video"
        "input"
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { };
    users.datahearth = import ./home.nix;
  };
}
```

Note: `extraSpecialArgs` will be populated in Task 5 when wiring the flake output (needs `awww` passed through).

### Step 4: Create `hosts/khazad-dum/locales.nix`

```nix
{
  services.xserver.xkb.layout = "fr";
  console.useXkbConfig = true;
  i18n.defaultLocale = "en_US.UTF-8";
}
```

### Step 5: Verify all files parse

Run: `for f in hosts/khazad-dum/{configuration,hardware-configuration,users,locales}.nix; do echo "--- $f ---"; nix-instantiate --parse "$f" > /dev/null && echo "OK"; done`
Expected: All files parse OK.

### Step 6: Commit

```bash
git add hosts/khazad-dum/configuration.nix hosts/khazad-dum/hardware-configuration.nix hosts/khazad-dum/users.nix hosts/khazad-dum/locales.nix
git commit -m "feat(khazad-dum): add NixOS system configuration files"
```

---

## Task 4: Clean up Home Manager files (remove nixGL)

**Files:**
- Modify: `hosts/khazad-dum/home.nix`
- Modify: `hosts/khazad-dum/modules.nix`
- Modify: `hosts/khazad-dum/packages.nix`

### Step 1: Update `hosts/khazad-dum/home.nix`

Remove the `targets.genericLinux` block (nixGL config) and the `/usr/local/go/bin` path (not relevant on NixOS). The file becomes:

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
  ]
  ++ (import ../../modules/home-manager);

  fonts.fontconfig.enable = true;

  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "25.05";
    shell.enableShellIntegration = true;
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.cargo/bin"
      "${config.home.homeDirectory}/.go/bin"
    ];

    sessionVariables = {
      GOPATH = "${config.home.homeDirectory}/.go";
      NIXOS_OZONE_WL = 1;
    };
  };

  xdg = {
    enable = true;
    autostart.enable = true;
  };
}
```

### Step 2: Update `hosts/khazad-dum/modules.nix`

Remove all `config.lib.nixGL.wrap` calls. The `display_manager` option can stay (it controls monitor config sourcing). The file becomes:

```nix
{ config, pkgs, ... }:
{
  home_modules = {
    ssh.enable = true;
    zellij.enable = true;
    yazi.enable = true;
    nushell.enable = true;
    zed-editor.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    hyprland = {
      enable = true;
      display_manager = true;
      status_bar = "waybar";
      window_rules = [
        "workspace 1, match:class Alacritty"
        "workspace 2, match:class zen, match:initial_title Zen Browser"
        "workspace 3, match:class dev.zed.Zed"
        "workspace 3, match:class code, match:initial_title Visual Studio Code"
        "workspace 4, match:class discord"
        "workspace 4, match:class signal"
        "workspace 6, match:class spotify"
      ];
      exec_once = [
        "signal-desktop --password-store=\"gnome-libsecret\""
        "discord"
        "zen-browser"
        "spotify"
      ];

      awww.randomize = {
        enable = true;
        directory = "/run/media/datahearth/proton/medias/wallpapers";
      };
    };

    niri.enable = true;

    alacritty.enable = true;

    git = {
      enable = true;
      signingKey = "B3402BD69AEDB608F67D6E850DBAB694B466214F";
    };
  };
}
```

### Step 3: Update `hosts/khazad-dum/packages.nix`

Remove `nixgl.auto.nixGLDefault` and all `config.lib.nixGL.wrap` wrappers. Remove `podman-compose` (Docker only). Move system-level packages (fonts, brightnessctl) comment for clarity but keep in HM for now. The file becomes:

```nix
{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    dust
    fd
    gh
    hyperfine
    jq
    libnotify
    ripgrep
    sd
    unzip
    wget
    xh
    zip
    git-filter-repo
    nixpkgs-review
    claude-code
    nixfmt
    nixd
    playerctl
    brightnessctl
    wl-clipboard
    proton-vpn-cli
    sops

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.mononoki
    nerd-fonts.fira-code
    noto-fonts-cjk-serif
    noto-fonts-cjk-sans

    # GUI
    obs-studio
    signal-desktop
    discord
    vlc
    obsidian
    spotify
    rquickshare
    qbittorrent
    walker
    virt-manager
    proton-authenticator
  ];

  programs = {
    btop.enable = true;
    eza.enable = true;
    fzf.enable = true;
    gpg.enable = true;
    home-manager.enable = true;
    starship.enable = true;
    zoxide.enable = true;
    mise.enable = true;

    nh = {
      enable = true;
      homeFlake = "${config.xdg.configHome}/nix-config";
      clean = {
        enable = true;
        dates = "monthly";
        extraArgs = "--keep 3 --keep-since 72h --optimise";
      };
    };

    difftastic = {
      enable = true;
      git.enable = config.home_modules.git.enable;
    };

    delta = {
      enable = true;
      enableJujutsuIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        signing = {
          behavior = "own";
          backend = "gpg";
          key = "dev@antoine-langlois.net";
        };
        git.sign-on-push = true;
        user = {
          name = "DataHearth";
          email = "dev@antoine-langlois.net";
        };
      };
    };

    bat = {
      enable = true;
      config.theme = "catppuccin_macchiato";

      themes.catppuccin_macchiato = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
          sha256 = "1g2r6j33f4zys853i1c5gnwcdbwb6xv5w6pazfdslxf69904lrg9";
        };
        file = "Catppuccin-macchiato.tmTheme";
      };
    };

    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      plugins = with pkgs; [
        {
          name = "zsh-autopair";
          src = zsh-autopair;
          file = "share/zsh/zsh-autopair/autopair.zsh";
        }
        {
          name = "zsh-completion-sync";
          src = zsh-completion-sync;
          file = "share/zsh-completion-sync/zsh-completion-sync.plugin.zsh";
        }
      ];
      envExtra = ''
        if [[ -n "$CLAUDECODE" ]]; then
          eval "$(direnv hook zsh)"
        fi
      '';

      shellAliases = {
        cat = "bat";
        cd = "z";
        open = "xdg-open";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    ssh.matchBlocks =
      let
        keyNamePrefix = "id_ed25519";
      in
      {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/${keyNamePrefix}_git";
          identitiesOnly = true;
        };
        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
          identityFile = "~/.ssh/${keyNamePrefix}_git";
          identitiesOnly = true;
        };
        "valinor" = {
          hostname = "valinor";
          user = "datahearth";
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };
        "deeps" = {
          hostname = "192.168.122.101";
          user = "datahearth";
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };
      };
  };
}
```

### Step 4: Commit

```bash
git add hosts/khazad-dum/home.nix hosts/khazad-dum/modules.nix hosts/khazad-dum/packages.nix
git commit -m "refactor(khazad-dum): remove nixGL wrappers for NixOS migration"
```

---

## Task 5: Wire up the NixOS flake output

**Files:**
- Modify: `flake.nix:42-101` (outputs section)

### Step 1: Add Khazad-dum to nixosConfigurations

The new flake output adds `nixosConfigurations.Khazad-dum` while keeping the existing `homeConfigurations` entry for now (backward compatibility during migration). The key changes:

- Add `nixos-hardware` to outputs function args
- Add `Khazad-dum` to `nixosConfigurations`
- Pass `awww` via `home-manager.extraSpecialArgs` (needed by hyprland awww module)
- Include all required NixOS modules: home-manager, sops-nix, nixvim, niri-flake, nixos-hardware Framework 16

Update the outputs function:

```nix
outputs =
  {
    nixpkgs-unstable,
    sops-nix,
    home-manager-unstable,
    nixvim,
    nixGL,
    niri-flake,
    dms,
    elephant,
    awww,
    nixos-hardware,
    ...
  }:
  {
    homeConfigurations."Khazad-dum" =
      let
        pkgs = import nixpkgs-unstable {
          system = "x86_64-linux";
          overlays = [ nixGL.overlay ];
        };
      in
      home-manager-unstable.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit awww;
        };

        modules = [
          { nixpkgs.config.allowUnfree = true; }
          sops-nix.homeManagerModules.sops
          elephant.homeManagerModules.default
          niri-flake.homeModules.niri
          dms.homeModules.dank-material-shell
          ./hosts/khazad-dum/home.nix
        ];
      };

    nixosConfigurations =
      let
        system = "x86_64-linux";
      in
      {
        Khazad-dum = nixpkgs-unstable.lib.nixosSystem {
          inherit system;

          modules = [
            ./hosts/khazad-dum/configuration.nix
            home-manager-unstable.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nixvim.nixosModules.default
            niri-flake.nixosModules.niri
            nixos-hardware.nixosModules.framework-16-7040-amd
            {
              home-manager.sharedModules = [
                sops-nix.homeManagerModules.sops
                elephant.homeManagerModules.default
                niri-flake.homeModules.niri
                dms.homeModules.dank-material-shell
              ];
            }
          ];
        };

        Valinor = nixpkgs-unstable.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit elephant;
          };

          modules = [
            ./hosts/valinor/configuration.nix
            home-manager-unstable.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nixvim.nixosModules.default
          ];
        };
      };
  };
```

### Step 2: Update `hosts/khazad-dum/users.nix` extraSpecialArgs

Now that we know the flake wiring, update `users.nix` to pass `awww`:

In `hosts/khazad-dum/users.nix`, the `home-manager` block is handled by the flake-level `home-manager.sharedModules`, but `extraSpecialArgs` needs `awww`. This is passed via the NixOS module system — update `configuration.nix` or `users.nix` to accept `awww` if needed by any home-manager module.

Actually, the awww module in `hyprland/awww.nix` likely references awww as a flake input. Check if it needs to be passed as a specialArg or if it's accessed differently.

If awww is needed as a specialArg for home-manager, add to the flake nixos module block:

```nix
{
  home-manager.extraSpecialArgs = {
    inherit awww;
  };
  home-manager.sharedModules = [ ... ];
}
```

### Step 3: Build test

Run: `nix build .#nixosConfigurations.Khazad-dum.config.system.build.toplevel --dry-run`
Expected: Dependency resolution succeeds (dry-run). If evaluation errors occur, fix them iteratively.

### Step 4: Commit

```bash
git add flake.nix hosts/khazad-dum/users.nix
git commit -m "feat(khazad-dum): wire NixOS flake output with all modules"
```

---

## Task 6: Fix hyprland polkit path for NixOS

**Files:**
- Modify: `modules/home-manager/hyprland/hyprland.nix:89`

### Step 1: Update the polkit agent path

The current config hardcodes `/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1` (Arch path). On NixOS, use the Nix store path:

Change line 89 from:
```nix
"/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
```
To:
```nix
"${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
```

### Step 2: Commit

```bash
git add modules/home-manager/hyprland/hyprland.nix
git commit -m "fix(hyprland): use nix store path for polkit agent"
```

---

## Task 7: Build verification and iteration

### Step 1: Full evaluation check

Run: `nix build .#nixosConfigurations.Khazad-dum.config.system.build.toplevel --dry-run 2>&1`
Expected: Clean evaluation with no errors.

### Step 2: If errors, fix iteratively

Common issues to watch for:
- Missing module arguments (awww, elephant, etc. not passed through correctly)
- nixGL references remaining somewhere in shared modules (they should be optional/defaulted)
- Conflicting options between system-level Hyprland/Gnome and Home Manager Hyprland
- `programs.nh` conflict between system-level (`modules/nh.nix`) and home-manager level (`packages.nix`)

### Step 3: Full build

Run: `nix build .#nixosConfigurations.Khazad-dum.config.system.build.toplevel`
Expected: Build succeeds, system closure created in `/nix/store/...`

### Step 4: Commit any fixes

```bash
git add -A
git commit -m "fix(khazad-dum): resolve NixOS build evaluation issues"
```

---

## Task 8: Update CLAUDE.md documentation

**Files:**
- Modify: `CLAUDE.md`

### Step 1: Update documentation

Key changes:
- Khazad-dum section: OS is now NixOS (not Arch Linux), add new files (configuration.nix, hardware-configuration.nix, users.nix, locales.nix)
- Remove nixGL references for khazad-dum
- Update build commands section (nh os for both hosts now)
- Add nixos-hardware to flake inputs list
- Add greetd module to module list
- Update directory structure tree
- Note that `homeConfigurations.Khazad-dum` is legacy/deprecated

### Step 2: Commit

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for khazad-dum NixOS migration"
```

---

## Task 9: Clean up legacy homeConfiguration (optional, post-install)

**Files:**
- Modify: `flake.nix` (remove homeConfigurations.Khazad-dum block)
- Modify: `flake.nix` (remove nixGL input if no other consumer)

This task should only be done AFTER the NixOS installation is complete and working. It removes:
- The `homeConfigurations."Khazad-dum"` output
- The `nixGL` flake input (if only used by khazad-dum)
- The nixGL overlay

**Do NOT execute this task until NixOS is installed and booting.**

```bash
git add flake.nix flake.lock
git commit -m "chore: remove legacy homeConfiguration and nixGL for khazad-dum"
```
