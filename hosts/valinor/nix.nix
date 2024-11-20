{ ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "datahearth"
      ];
    };
    gc = {
      dates = "weekly";
      automatic = true;
      options = "--delete-older-than 2d";
    };
  };

}
