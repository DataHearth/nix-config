{ ... }: {
  services = {
    blueman.enable = false;

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
