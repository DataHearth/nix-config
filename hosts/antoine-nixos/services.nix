{ pkgs, ... }: {
  services = {
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
    };

    deluge.enable = true;
    gnome.gnome-keyring.enable = true;
    tailscale.enable = true;

    # Custom services
    passthrough = {
      enable = false;
      ids = [ "10de:1b81" "10de:10f0" ];
      user = "datahearth";
    };
    nvidia = {
      enable = true;
      sleepIssue = true;
    };
  };
}
