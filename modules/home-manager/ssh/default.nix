{ config, options, lib, ... }:
with lib;
let
  keyNamePrefix = "id_ed25519";

  cfg = config.hm.ssh;

  enable = mkEnableOption "ssh";
  addKeysToAgent = mkOption {
    type = types.enum [ "yes" "no" "confirm" "ask" ];
    default = "yes";
    description = "Add automatically private SSH keys to ssh-agent";
  };
in
{
  options.hm.ssh = {
    inherit enable addKeysToAgent;
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      addKeysToAgent = cfg.addKeysToAgent;
      matchBlocks = {
        "gitea.antoine-langlois.net" = {
          hostname = "gitea.antoine-langlois.net";
          user = "git";
          identityFile = "~/.ssh/${keyNamePrefix}_git";
          port = 58964;
          identitiesOnly = true;
        };
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/${keyNamePrefix}_git";
          identitiesOnly = true;
        };
        "cronos" = {
          hostname = "10.0.0.2";
          user = "root";
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };
        "cronos-debian" = {
          hostname = "10.0.0.3";
          user = "antoine";
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };

        # BAP
        "bap-dev" = {
          hostname = "dev.app.bienaporter.com";
          user = "service_deploy";
          identityFile =  "~/.ssh/${keyNamePrefix}_bap-dev";
          identitiesOnly = true;
          port = 5022;
        };
        "bap-prod" = {
          hostname = "prod.app.bienaporter.com";
          user = "service_deploy";
          identityFile =  "~/.ssh/${keyNamePrefix}_bap-prod";
          identitiesOnly = true;
          port = 5022;
        };
        "bap-runner" = {
          hostname = "51.91.11.36";
          user = "gitlab-runner";
          identityFile = "~/.ssh/${keyNamePrefix}_bap-runner";
          identitiesOnly = true;
        };
        "bap-gitlab" = {
          hostname = "gitlab.com";
          user = "git";
          identityFile = "~/.ssh/${keyNamePrefix}_git";
          identitiesOnly = true;
        };

        # Wyll
        "github-wyll" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519_wyll";
          identitiesOnly = true;
        };
      };
    };
  };
}
