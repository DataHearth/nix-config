{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./lanzaboote.nix
    ./users.nix
    ./locales.nix
    ./modules.nix
    ./packages.nix
    ./services.nix
    ./systemd.nix
  ]
  ++ (import ../../modules/nixos);

  sops = {
    defaultSopsFile = ../../secrets/secrets.yml;
    age.keyFile = "${config.users.users.datahearth.home}/.config/sops/age/keys.txt";
    secrets = {
      "rclone/protondrive/username" = {
        owner = config.users.users.datahearth.name;
      };
      "rclone/protondrive/password" = {
        owner = config.users.users.datahearth.name;
      };
      "rclone/protondrive/totp-secret" = {
        owner = config.users.users.datahearth.name;
      };
      "claude-code/github-mcp" = {
        owner = config.users.users.datahearth.name;
      };
      "claude-code/context7-mcp" = {
        owner = config.users.users.datahearth.name;
      };
    };
  };

  time.timeZone = "Europe/Paris";
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "datahearth"
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # systemd-resolved provides split-DNS: it routes queries to the right
  # DNS server based on the interface/domain (e.g. corporate domains go
  # through VPN DNS, everything else through the default interface).
  # The F5 VPN client overwrites /etc/resolv.conf with corporate-only
  # nameservers that return NXDOMAIN for public domains (like github.com).
  # Tools using glibc/NSS (curl, xh) bypass this via systemd-resolved's
  # stub listener, but Nix reads /etc/resolv.conf directly and fails.
  # The activation script below makes /etc/resolv.conf immutable so the
  # VPN can't overwrite it, forcing all DNS through the resolved stub.
  services.resolved.enable = true;

  system.activationScripts.immutable-resolv-conf = lib.stringAfter [ "etc" ] ''
    ${pkgs.e2fsprogs}/bin/chattr -i /etc/resolv.conf 2>/dev/null || true
    cat > /etc/resolv.conf <<EOF
    nameserver 127.0.0.53
    search airbus.corp lan
    EOF
    ${pkgs.e2fsprogs}/bin/chattr +i /etc/resolv.conf
  '';

  networking = {
    hostName = "khazad-dum";
    wireless.iwd.enable = true;
    nftables.enable = true;
    firewall.enable = true;
    extraHosts = ''
      127.0.0.1 etlm.cluster.local
    '';

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.backend = "iwd";
      unmanaged = [ "interface-name:tun*" ];
    };
  };
}
