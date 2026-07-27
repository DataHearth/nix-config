{ pkgs, ... }:
{
  services = {
    udiskie.enable = true;

    # ProtonMail Bridge is run via the Qt GUI (protonmail-bridge-gui in
    # packages.nix), not the headless service — both take the same single
    # instance lock, so only one can run. Autostart is wired via Hyprland's
    # exec_once below (the GUI's "Open on startup" toggle writes an XDG
    # autostart entry, which Hyprland doesn't read). Enable "Start minimized
    # to tray" in the GUI once so it comes up hidden.

    ssh-agent.enable = true;

    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };
  };
}
