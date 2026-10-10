{ config, lib, ... }:
let
  cfg = config.nixos_modules.nix-builder;

  enable = lib.mkEnableOption "offloading nix builds to a remote builder";

  sshKey = lib.mkOption {
    type = lib.types.str;
    default = "${config.users.users.datahearth.home}/.ssh/id_ed25519";
    description = ''
      Private key used to reach the builder. The nix daemon opens this
      connection as root rather than as the calling user, so it has to be a
      path root can read, and the matching public half has to be installed on
      the builder.
    '';
  };

  maxJobs = lib.mkOption {
    type = lib.types.int;
    default = 4;
    description = ''
      Derivations dispatched to the builder at once. The builder caps the
      cores each one gets, so this multiplied by that cap is the CPU ceiling
      asked of a machine that has other work to do. Raising it here alone
      does not make builds faster.
    '';
  };
in
{
  options.nixos_modules.nix-builder = {
    inherit enable sshKey maxJobs;
  };

  config = lib.mkIf cfg.enable {
    nix = {
      distributedBuilds = true;

      buildMachines = [
        {
          hostName = "nix-builder.nerds.casa";
          sshUser = "builder";
          protocol = "ssh-ng";
          system = "x86_64-linux";
          speedFactor = 4;
          # The builder pod has no /dev/kvm, so VM tests (`kvm`, `nixos-test`)
          # must stay local; advertising them would send those builds there.
          supportedFeatures = [ "big-parallel" ];
          inherit (cfg) maxJobs sshKey;
        }
      ];

      # Without this the builder pulls every dependency through this laptop's
      # uplink instead of substituting them itself.
      settings.builders-use-substitutes = true;
    };

    programs.ssh = {
      # Pinned rather than left to TOFU: the daemon connects as root with no
      # terminal, so an unknown host key fails the build instead of prompting.
      knownHosts."nix-builder.nerds.casa".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBK0AD9BS0GmSgoEVseK4d8cvkoBML+uCyxeMcOjSeN+";

      # The name resolves everywhere: to a LAN or tailnet address at home, to
      # the public edge's port 22 elsewhere. If the builder is down, the bound
      # keeps each build from stalling on the TCP timeout before nix falls
      # back to building locally.
      extraConfig = ''
        Host nix-builder.nerds.casa
          ConnectTimeout 5
          ServerAliveInterval 15
          ServerAliveCountMax 3
      '';
    };
  };
}
