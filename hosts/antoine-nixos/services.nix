{ ... }: {
  services = {
    blueman.enable = false;
    tlp = {
      enable = true;
      settings = {
        TLP_DEFAULT_MODE = "AC";
        TLP_PERSISTENT_DEFAULT = 1;
        CPU_DRIVER_OPMODE_ON_AC = "active";
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      };
    };

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
