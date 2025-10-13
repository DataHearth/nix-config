{
  pkgs,
  lib,
  ...
}:
{
  services = {
    fprintd.enable = true;
    deluge.enable = true;

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "datahearth";
      group = "users";
    };

    tailscale = {
      enable = true;
      extraUpFlags = [
        "--accept-dns"
        "--accept-routes"
      ];
    };

    xserver = {
      enable = true;
      xkb = {
        layout = "fr,us";
        variant = ",intl";
        options = "grp:win_space_toggle";
      };
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
      enable = lib.mkDefault true;
      vt = 9; # Fix lines on screen

      settings.default_session = {
        command = ''${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --time --greeting "Speak Friend and Enter" --remember --remember-user-session --asterisks --cmd Hyprland'';
        user = "datahearth";
      };
    };
  };
}
