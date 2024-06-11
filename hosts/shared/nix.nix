{ config, ... }: {
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    nixPath = [
      "nixos-config=$HOME/.config/nix-config/hosts/${config.networking.hostName}/configuration.nix"
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    gc = {
      dates = "weekly";
      automatic = true;
      options = "--delete-older-than 2d";
    };
  };
}
