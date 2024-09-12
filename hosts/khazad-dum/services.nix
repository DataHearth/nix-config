{ config, pkgs, ... }:
{
  services = {
    fprintd.enable = true;
    power-profiles-daemon.enable = true;
    deluge.enable = true;
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = "${config.users.users.datahearth.home}/.tskey";
      extraUpFlags = [ "--accept-dns" ];
    };

    xserver = {
      enable = true;
      xkb.layout = "fr";
    };

    pipewire = {
      enable = true;
      pulse.enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };
    };

    greetd = {
      enable = true;

      settings = {
        default_session = {
          command = ''${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --time --greeting "Speak Friend and Enter" --remember --remember-user-session --asterisks --cmd Hyprland'';
          user = "datahearth";
        };
      };
      vt = 9; # Fix lines on screen
    };
  };
}
