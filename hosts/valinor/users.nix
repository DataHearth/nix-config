{ pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    motd = ''
       __     __    _ _                  
       \ \   / /_ _| (_)_ __   ___  _ __ 
        \ \ / / _` | | | '_ \ / _ \| '__|
         \ V / (_| | | | | | | (_) | |   
          \_/ \__,_|_|_|_| |_|\___/|_|   

      Bienvenue à Valinor,
      où la lumière des Deux Arbres brille éternellement,
      et les échos des chants anciens emplissent l'air.

      Ici, sous les étoiles scintillantes,
      que votre chemin soit guidé par la sagesse et la paix.

      « Dans ce royaume de beauté,
      chaque voyage est un nouveau récit en attente d'être raconté. »

      ----------------------------------------------------
    '';

    groups = {
      actinium = { };
    };

    users = {
      datahearth = {
        isNormalUser = true;
        description = "Antoine Langlois";
        extraGroups = [
          "wheel"
          "docker"
          "libvirtd"
          "networkmanager"
        ];
      };

      actinium = {
        description = "Actinium service account for managing deployed apps";
        group = "actinium";
        extraGroups = [ "docker" ];
        isNormalUser = true;
        openssh.authorizedKeys.keys = [ ];
      };
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { };
    users.datahearth = import ./home-manager/home.nix;
  };
}
