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

    fprintd.enable = true;
    tlp.enable = true;
    deluge.enable = true;
    gnome.gnome-keyring.enable = true;
    tailscale.enable = true;
    blueman.enable = true;
  };
}
