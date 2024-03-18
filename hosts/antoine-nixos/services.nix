{ pkgs, ... }:
{
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

    tlp = {
      enable = true;
      settings = {
        TLP_DEFAULT_MODE = "AC";
        TLP_PERSISTENT_DEFAULT = 1;
        INTEL_GPU_MIN_FREQ_ON_AC = 500;
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
      };
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --user-menu --time --greeting \"Speak Friend and Enter\" --remember --remember-user-session --asterisks --cmd Hyprland";
          user = "datahearth";
        };
      };
    };

    power-profiles-daemon.enable = false;
    deluge.enable = true;
    gnome.gnome-keyring.enable = true;

    # Custom services
    passthrough = {
      enable = false;
      ids = [ "10de:1b81" "10de:10f0" ];
      user = "datahearth";
    };
    nvidia.enable = true;
    nvidia.sleepIssue = false;
  };
}
