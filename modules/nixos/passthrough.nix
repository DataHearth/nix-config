{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.passthrough;
in
{
  options.nixos_modules.passthrough = {
    enable = lib.mkEnableOption "GPU passthrough with VFIO";
    ids = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [
        "1002:7480"
        "1002:ab30"
      ];
      description = "GPU PCI IDs to isolate for passthrough";
    };
    cpu = lib.mkOption {
      type = lib.types.enum [
        "amd"
        "intel"
      ];
      description = "CPU vendor for IOMMU kernel parameter";
    };
    user = lib.mkOption {
      type = lib.types.str;
      example = "datahearth";
      description = "Username to add to the libvirtd group";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelParams = [
        "${cfg.cpu}_iommu=on"
        "iommu=pt"
      ];
      kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];
      extraModprobeConfig = ''
        options vfio-pci ids=${lib.concatStringsSep "," cfg.ids}
        softdep drm pre: vfio-pci
      '';
    };

    users.users.${cfg.user}.extraGroups = [ "libvirtd" ];

    virtualisation = {
      libvirtd = {
        enable = true;
        qemu.swtpm.enable = true;
      };
      spiceUSBRedirection.enable = true;
    };
  };
}
