{ config, ... }:
{
  # Desktop sessions
  programs.hyprland.enable = true;

  # GNOME desktop session is not used; keep only the supporting plumbing the
  # Hyprland session relies on. (gnome-keyring is enabled in greetd.nix,
  # udisks2 in services.nix, and the xdg portals come from programs.hyprland.)
  programs.dconf.enable = true; # GTK app settings + catppuccin dconf theming
  security.polkit.enable = true; # for the polkit-gnome agent (systemd.nix)
  services.gvfs.enable = true; # nautilus trash/mounts, GTK file chooser
  services.upower.enable = true; # battery status for the bar / notifications

  nixos_modules = {
    # F5 VPN (Airbus): client, split-tunnel routing/DNS, firewall, tailnet fix
    f5.enable = true;

    # Display manager
    greetd = {
      enable = true;
      greeter = "regreet";
      defaultSession = "Hyprland";
    };

    nh = {
      enable = true;
      settings.flake = "${config.users.users.datahearth.home}/.config/nix-config";
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
