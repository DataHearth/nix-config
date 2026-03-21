{
  config,
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
      "wifi/cirdan" = { };
    };
    templates."wifi-cirdan-env" = {
      content = "WIFI_CIRDAN_PSK=${config.sops.placeholder."wifi/cirdan"}";
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
}
