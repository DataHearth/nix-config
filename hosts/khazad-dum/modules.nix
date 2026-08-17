{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.hyprland.enable = true;

  # GNOME desktop session is not used; keep only the supporting plumbing the
  # Hyprland session relies on. (gnome-keyring is enabled in greetd.nix,
  # udisks2 in services.nix, and the xdg portals come from programs.hyprland.)
  programs.dconf.enable = true; # GTK app settings + catppuccin dconf theming
  security.polkit.enable = true; # for the polkit-gnome agent (systemd.nix)
  services.upower.enable = true; # battery status for the bar / notifications

  nixos_modules = {
    # F5 VPN (Airbus): client, split-tunnel routing/DNS, firewall, tailnet fix
    f5.enable = true;

    greetd.enable = true;

    # Also owns services.gvfs for trash/mounts and the GTK file chooser.
    nautilus = {
      enable = true;
      users = [ "datahearth" ];
    };

    nh = {
      enable = true;
      settings.flake = "${config.users.users.datahearth.home}/.config/nix-config";
    };

    # Host-side support for the Claude Desktop "Cowork" agent VM (OVMF firmware
    # at the app's hardcoded path, vhost-vsock, kvm device access).
    claude-desktop-cowork = {
      enable = true;
      users = [ "datahearth" ];
    };
  };

  # Framework 16 fan control. nixpkgs' hardware.fw-fanctrl owns the systemd
  # service (fw-ectool drives the EC) and the suspend hook; our config is merged
  # onto fw-fanctrl's shipped defaults, so every stock strategy (lazy, medium,
  # agile, deaf…) stays selectable at runtime with `fw-fanctrl use <name>`.
  # Every curve here holds a flat floor and only ramps above it: anything past
  # ~25% duty is clearly audible on this chassis, and idle temps sit in that range
  # most of the time. Both power states deliberately select "quiet", so the AC
  # check fw-fanctrl runs every cycle is a no-op — plugging in no longer buys
  # cooling at the cost of noise. "lap-cool" and "stand" remain as manual
  # escalation steps for when quiet heat-soaks too far: `fw-fanctrl use lap-cool`
  # (or `stand`) overrides the selection until `fw-fanctrl reset`.
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "quiet"; # on AC
      strategyOnDischarging = "quiet"; # on battery
      strategies.lap-cool = {
        fanSpeedUpdateFrequency = 5; # seconds between duty updates
        movingAverageInterval = 20; # temperature averaging window (seconds)
        speedCurve = [
          {
            temp = 0;
            speed = 15;
          }
          {
            temp = 45;
            speed = 15;
          }
          {
            temp = 50;
            speed = 22;
          }
          {
            temp = 60;
            speed = 45;
          }
          {
            temp = 70;
            speed = 60;
          }
          {
            temp = 80;
            speed = 85;
          }
          {
            temp = 85;
            speed = 100;
          }
        ];
      };
      # Docked / on a stand: airflow is unobstructed and fan noise matters less,
      # so ramp harder above the quiet floor to keep the chips (and chassis)
      # cooler. Not the default — switch to it when docked with
      # `fw-fanctrl use stand` (and back with `fw-fanctrl use lap-cool`).
      strategies.stand = {
        fanSpeedUpdateFrequency = 5;
        movingAverageInterval = 15; # snappier than lap-cool
        speedCurve = [
          {
            temp = 0;
            speed = 20;
          }
          {
            temp = 40;
            speed = 20;
          }
          {
            temp = 50;
            speed = 35;
          }
          {
            temp = 60;
            speed = 70;
          }
          {
            temp = 70;
            speed = 90;
          }
          {
            temp = 80;
            speed = 100;
          }
        ];
      };
      # Silence over thermals: fans fully off below 50 °C and inaudible to ~65 °C,
      # accepting that sustained load heat-soaks the chassis and clocks down
      # sooner than lap-cool would. The long averaging window matters as much as
      # the low duty here — audible ramping up and down draws more attention than
      # a steady speed does, so smooth the response rather than tracking every
      # spike. Above 72 °C it ramps hard, because by then quiet has lost.
      strategies.quiet = {
        fanSpeedUpdateFrequency = 5;
        movingAverageInterval = 40;
        speedCurve = [
          {
            temp = 0;
            speed = 0;
          }
          {
            temp = 50;
            speed = 0;
          }
          {
            temp = 65;
            speed = 15;
          }
          {
            temp = 72;
            speed = 30;
          }
          {
            temp = 80;
            speed = 55;
          }
          {
            temp = 85;
            speed = 75;
          }
          {
            temp = 90;
            speed = 100;
          }
        ];
      };
    };
  };

  # The fw-fanctrl CLI reads /etc/fw-fanctrl/config.json when no --config is
  # given (DEFAULT_CONFIGURATION_FILE_PATH), but the nixpkgs module only hands
  # its generated file to the daemon via --config and never populates /etc, so
  # every ad-hoc `fw-fanctrl` invocation fails on the missing path.
  #
  # The module builds that file in a `let` inside its `config` block, so there is
  # no option to reference — the merge below has to mirror hardware/fw-fanctrl.nix
  # by hand. Keeping the derivation name "custom.json" identical to the module's
  # makes the two evaluate to the same store path, so this symlink resolves to the
  # exact file the running daemon has open rather than a copy that could drift.
  environment.etc."fw-fanctrl/config.json".source =
    (pkgs.formats.json { }).generate "custom.json" (
      lib.recursiveUpdate (builtins.fromJSON (
        builtins.readFile "${config.hardware.fw-fanctrl.package}/share/fw-fanctrl/config.json"
      )) config.hardware.fw-fanctrl.config
    );

  programs.zsh.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [
        "--all"
        "--filter=until=336h"
      ];
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;
}
