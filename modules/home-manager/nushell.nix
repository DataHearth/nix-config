{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.nushell;

  enable = lib.mkEnableOption "nushell";
in
{
  options.home_modules.nushell = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    programs.carapace = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.nushell = {
      enable = true;

      environmentVariables = {
        EDITOR = "nvim";
      };

      extraConfig = ''
        $env.config = ($env.config | merge {
          show_banner: false

          ls: {
            use_ls_colors: true
            clickable_links: true
          }

          table: {
            mode: rounded
            index_mode: auto
            trim: {
              methodology: wrapping
              wrapping_try_keep_words: true
            }
          }

          completions: {
            case_sensitive: false
            quick: true
            partial: true
            algorithm: "fuzzy"
          }

          history: {
            max_size: 50_000
            sync_on_enter: true
            file_format: "sqlite"
            isolation: false
          }

          cursor_shape: {
            emacs: line
            vi_insert: line
            vi_normal: block
          }

          rm: {
            always_trash: true
          }

          error_style: "fancy"
        })
      '';
    };
  };
}
