{ config, lib, pkgs, ... }:
let
  cfg = config.services.nvidia;
in
with lib;
{
  options.services.nvidia = {
    enable = mkEnableOption "nvidia";
    sleepIssue = mkEnableOption "nvidia-sleep";
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = ["nvidia"];
    boot.kernelParams = mkIf (cfg.sleepIssue) [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };
      nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement.enable = mkIf (cfg.sleepIssue) true;
      };
    };
  };
}
