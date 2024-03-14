let
  keyNamePrefix = "id_ed25519";
in
{
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
}
