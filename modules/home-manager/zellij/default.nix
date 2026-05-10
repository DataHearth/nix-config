{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.zellij;

  enable = lib.mkEnableOption "zellij";

  # Stable, rebuild-invariant path for the zjstatus wasm. zellij keys plugin
  # permission grants by the location string, so pointing layouts straight at
  # the Nix store path would break grants on every `nh os switch` (the store
  # hash changes). Instead we symlink the wasm to this fixed path (below) and
  # patch layouts to reference it, so the permission grant persists forever.
  zjstatusPath = "${config.home.homeDirectory}/.config/zellij/plugins/zjstatus.wasm";

  # Copy the layouts dir verbatim, then patch the @zjstatus@ placeholder in
  # every layout to the stable path. --replace-quiet keeps layouts without the
  # placeholder happy.
  layouts = pkgs.runCommandLocal "zellij-layouts" { } ''
    cp -r ${./layouts} $out
    chmod -R +w $out
    for f in $out/*.kdl; do
      substituteInPlace "$f" \
        --replace-quiet '@zjstatus@' '${zjstatusPath}'
    done
  '';
in
{
  options.home_modules.zellij = {
    inherit cfg enable;
  };

  config = lib.mkIf cfg.enable {
    # Due to KDL format, it is very hard and not completely accurate to transform
    # Nix -> KDL. So most "advanced" configuration won't work
    xdg.configFile = {
      "zellij/layouts" = {
        recursive = true;
        source = layouts;
      };
      "zellij/config.kdl".source = ./config.kdl;
      # Symlink the wasm to a fixed path (target changes per rebuild, the path
      # string does not) so zellij's permission grant survives `nh os switch`.
      "zellij/plugins/zjstatus.wasm".source = "${pkgs.zjstatus}/bin/zjstatus.wasm";
    };

    programs.zellij.enable = true;
  };
}
