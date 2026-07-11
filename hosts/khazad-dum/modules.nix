{ config, ... }:
{
  # Desktop sessions
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

    # Display manager
    greetd.enable = true;

    # File manager (owns services.gvfs for trash/mounts + the GTK file chooser).
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
  # "lap-cool" ramps far earlier than the stock "lazy" default (which idles at
  # 15% until 50 °C) so the underside stays cooler on a lap; "stand" ramps harder
  # still for when it's docked. fw-fanctrl re-checks AC state every update cycle
  # and auto-selects defaultStrategy on AC / strategyOnDischarging on battery, so
  # plugging in switches to "stand" and unplugging drops back to "lap-cool"
  # within one cycle (~5 s) — power state stands in for docked-vs-lap. A manual
  # `fw-fanctrl use <name>` overrides both until `fw-fanctrl reset`.
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "stand"; # on AC / plugged in (docked)
      strategyOnDischarging = "lap-cool"; # on battery (lap)
      strategies.lap-cool = {
        fanSpeedUpdateFrequency = 5; # seconds between duty updates
        movingAverageInterval = 20; # temperature averaging window (seconds)
        speedCurve = [
          {
            temp = 0;
            speed = 20;
          }
          {
            temp = 30;
            speed = 20;
          }
          {
            temp = 50;
            speed = 35;
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
      # so ramp harder across the whole range to keep the chips (and chassis)
      # cooler. Not the default — switch to it when docked with
      # `fw-fanctrl use stand` (and back with `fw-fanctrl use lap-cool`).
      strategies.stand = {
        fanSpeedUpdateFrequency = 5;
        movingAverageInterval = 15; # snappier than lap-cool
        speedCurve = [
          {
            temp = 0;
            speed = 30;
          }
          {
            temp = 30;
            speed = 35;
          }
          {
            temp = 50;
            speed = 55;
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
    };
  };

  # Shell
  programs.zsh.enable = true;

  # Docker
  virtualisation.docker.enable = true;

  # Libvirt / QEMU
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;
}
