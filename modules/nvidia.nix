{ config, lib, ... }:
let
  cfg = config.services.nvidia;
  enable = lib.mkEnableOption "nvidia";
  sleepIssue = lib.mkEnableOption "nvidia-sleep";
in
{
  options.services.nvidia = {
    inherit enable sleepIssue;
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    boot.kernelParams =
      [ ] ++ (if cfg.sleepIssue then [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ] else [ ]);
    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };
      nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement.enable = cfg.sleepIssue;
      };
    };
  };
}
