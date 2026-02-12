{ config, ... }:
{
  # Desktop sessions
  programs.hyprland.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Display manager
  nixos_modules.greetd = {
    enable = true;
    greeter = "tuigreet";
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

  # nh
  nixos_modules.nh = {
    enable = true;
    settings.flake = "${config.users.users.datahearth.home}/.config/nix-config";
  };
}
