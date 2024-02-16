{ pkgs, ... }:
{
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;

    displayManager = {
      autoLogin.enable = false;
      gdm.enable = true;

      autoLogin.user = "datahearth";
    };
    xkb.layout = "fr";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;

    alsa.support32Bit = true;
  };

  services.tlp = {
    enable = true;
    settings = {
      TLP_DEFAULT_MODE = "AC";
      TLP_PERSISTENT_DEFAULT = 1;
      INTEL_GPU_MIN_FREQ_ON_AC = 500;
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
    };
  };

  services.power-profiles-daemon.enable = false;
  services.printing.enable = true;
  services.deluge.enable = true;

  # Custom services
  services.passthrough = {
    enable = false;
    ids = [ "10de:1b81" "10de:10f0" ];
    user = "datahearth";
  };
  services.nvidia.enable = true;
  services.nvidia.sleepIssue = true;
}
