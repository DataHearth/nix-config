{
  home_modules = {
    bat.enable = true;
    direnv.enable = true;

    ssh = {
      enable = true;
      matchBlocks =
        let
          keyNamePrefix = "id_ed25519";
        in
        {
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/${keyNamePrefix}";
            identitiesOnly = true;
          };
          "gitlab.com" = {
            hostname = "gitlab.com";
            user = "git";
            identityFile = "~/.ssh/${keyNamePrefix}";
            identitiesOnly = true;
          };
        };
    };

    zsh = {
      enable = true;
      extraAliases = {
        docker-restart-all = "docker compose -f /mnt/Erebor/War-goats/appdata/docker-compose.yml restart";
      };
      initContent = ''
        cd /mnt/Erebor/War-goats/appdata
      '';
    };

    git = {
      enable = true;
      signingKey = "4DC34E03802B08908F8DA621F4C806AC1E3EBAB6";
    };
  };
}
