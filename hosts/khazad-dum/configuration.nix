{
  config,
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
    ./network.nix
    ./packages.nix
    ./services.nix
    ./systemd.nix
  ]
  ++ (import ../../modules/nixos);

  # For cross-building and running ARM targets on this x86 laptop.
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  hardware.enableAllFirmware = true;
  hardware.enableAllHardware = true;

  sops = {
    defaultSopsFile = ../../secrets/secrets.yml;
    age.keyFile = "${config.users.users.datahearth.home}/.config/sops/age/keys.txt";
    secrets = {
      "wifi/cirdan" = { };
      "wifi/la-maison-du-bonheur" = { };
      "attic/builder" = { };
    };
    templates = {
      # nix's default netrc-file; the daemon reads it as root.
      "nix-netrc" = {
        path = "/etc/nix/netrc";
        content = ''
          machine nix.nerds.casa
          password ${config.sops.placeholder."attic/builder"}
        '';
      };
      "wifi-cirdan-env".content = "WIFI_CIRDAN_PSK=${config.sops.placeholder."wifi/cirdan"}";
      "la-maison-du-bonheur-env".content = "WIFI_LA_MAISON_DU_BONHEUR_PSK=${
        config.sops.placeholder."wifi/la-maison-du-bonheur"
      }";
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

    # extra-* because setting `substituters` would drop the cache.nixos.org
    # default. These are forwarded to the remote builder too, where
    # nix.nerds.casa is blocked by its egress policy; the short timeout lets it
    # give up on that cache quickly instead of stalling each build.
    extra-substituters = [ "https://nix.nerds.casa/builder" ];
    extra-trusted-public-keys = [ "builder:QmlzOq6fo2gPZ6Vt++ulIK+FCc0r86e8ydE60L9DBys=" ];
    connect-timeout = 5;
  };

  boot = {
    # Tracks mainline rather than the nixpkgs default. This follows the newest
    # series, so `nix flake update` can cross a major bump (6.18 -> 7.1) with no
    # warning; framework-laptop-kmod is out-of-tree and has to build against
    # whatever lands, so check it after an update before switching.
    #
    # framework-laptop-kmod installs its .ko by hand, skipping Kbuild's
    # modules_install, which since NixOS/nixpkgs#571181 is what signs the
    # module and writes its .ko.cer; aggregating the modules tree then fails
    # on `cat: extra/framework_laptop.ko.cer`. This mirrors the upstream fix
    # (nixpkgs e81ffa28fd, see #575192), on master but not yet on
    # nixos-unstable. Drop the extend once the channel has it: the package
    # will already list modules_install in installTargets.
    kernelPackages = pkgs.linuxPackages_latest.extend (
      _: prev: {
        framework-laptop-kmod = prev.framework-laptop-kmod.overrideAttrs (old: {
          makeFlags = old.makeFlags ++ [
            "INSTALL_MOD_PATH=${placeholder "out"}"
            "INSTALL_MOD_DIR=extra"
            "DEPMOD=true"
          ];
          installTargets = [ "modules_install" ];
          installPhase = null;
        });
      }
    );

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
