{ ... }:
{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    matchBlocks = {
      "gitea.antoine-langlois.net" = {
        hostname = "gitea.antoine-langlois.net";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        port = 58964;
        identitiesOnly = true;
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "github-wyll" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_wyll";
        identitiesOnly = true;
      };
      "cronos" = {
        hostname = "10.0.0.2";
        user = "root";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "cronos-debian" = {
        hostname = "10.0.0.3";
        user = "antoine";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };
}
