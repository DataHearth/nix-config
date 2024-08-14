{ pkgs, lib, config, ... }: {
  services = {
    deluge.enable = true;
    gnome.gnome-keyring.enable = true;
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = "${config.users.users.datahearth.home}/.tskey";
      extraUpFlags =
        [ "--exit-node-allow-lan-access" "--exit-node" "100.65.209.18" ];
    };
    blueman.enable = lib.mkDefault true;

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
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --time --greeting "Speak Friend and Enter" --remember --remember-user-session --asterisks --cmd Hyprland'';
          user = "datahearth";
        };
      };
      vt = 9; # Fix lines on screen
    };
  };
}
