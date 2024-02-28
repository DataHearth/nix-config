{ pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;

      displayManager = {
        autoLogin.enable = false;
        gdm.enable = true;

        autoLogin.user = "datahearth";
      };
      xkb.layout = "fr";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;

      alsa.support32Bit = true;
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

    power-profiles-daemon.enable = false;
    printing.enable = true;
    deluge.enable = true;
    gnome.gnome-keyring.enable = true;

    # Custom services
    passthrough = {
      enable = false;
      ids = [ "10de:1b81" "10de:10f0" ];
      user = "datahearth";
    };
    nvidia.enable = true;
    nvidia.sleepIssue = true;
  };
}
