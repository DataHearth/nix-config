{ pkgs, lib, inputs, ... }: {
  imports = let
    shared = ../shared;
    modules = ../../modules;
  in [
    "${modules}/neovim"

    "${shared}/i18n.nix"
    "${shared}/nix.nix"
    "${shared}/options.nix"
    "${shared}/services.nix"
    "${shared}/security.nix"

    ./hardware-configuration.nix
    ./services.nix
  ];
  system.stateVersion = "24.05";

  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    # https://community.frame.work/t/solved-fw16-not-powering-down/52659/4
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = { hostName = "antoine-framework"; };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.datahearth = {
      isNormalUser = true;
      description = "Antoine Langlois";
      extraGroups = [ "networkmanager" "wheel" "docker" "wireshark" ];
    };
  };

  environment = { systemPackages = with pkgs; [ sbctl ]; };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users = { "datahearth" = import ./home-manager/home.nix; };
  };
}
