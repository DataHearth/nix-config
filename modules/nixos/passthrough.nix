{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.passthrough;
in
{
  options.services.passthrough = {
    enable = lib.mkEnableOption "passthrough";
    ids = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [
        "10de:1b81"
        "10de:10f0"
      ];
      description = "GPU's PCI ids to isolate";
    };
    user = lib.mkOption {
      type = lib.types.str;
      example = "DataHearth";
      description = ''Username to add "libvirtd" group'';
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelParams = [
        "intel_iommu=on"
        "iommu=pt"
      ];
      kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
        "vfio_virqfd"
      ];
      extraModprobeConfig = ''
        options vfio-pci ids=${lib.concatStringsSep "," cfg.ids}
        softdep drm pre: vfio-pci
      '';
    };

    users.users.${cfg.user}.extraGroups = [ "libvirtd" ];
    environment.systemPackages = [
      pkgs.OVMF
      pkgs.qemu
    ];
    programs.virt-manager.enable = true;

    virtualisation = {
      libvirtd = {
        enable = true;
        qemu.verbatimConfig = ''
          nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
        '';
      };
      spiceUSBRedirection.enable = true;
    };
  };
}
