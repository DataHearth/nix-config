{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.nautilus;
in
{
  options.nixos_modules.nautilus = {
    enable = lib.mkEnableOption "nautilus";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nautilus;
      defaultText = lib.literalExpression "pkgs.nautilus";
      description = "The Nautilus (GNOME Files) package to install.";
    };

    preview = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GNOME Sushi for spacebar quick-preview in Nautilus.";
    };

    terminal = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "alacritty";
      example = "alacritty";
      description = ''
        Terminal wired into Nautilus' right-click "Open Terminal" entry via the
        nautilus-open-any-terminal extension. The upstream module also sets
        NAUTILUS_4_EXTENSION_DIR (needed outside a GNOME session) so the
        extension is actually discovered. null disables the extension.
      '';
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "datahearth" ];
      description = ''
        Users for whom Nautilus is registered (via their Home Manager config) as
        the default handler for directories, so `xdg-open <dir>` opens Nautilus.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Trash, removable-device mounts, network shares, GTK file-chooser sidebar.
    services.gvfs.enable = true;

    # Spacebar quick-preview (D-Bus activated, no extension wiring needed).
    services.gnome.sushi.enable = cfg.preview;

    # "Open Terminal" context entry. This upstream module installs the
    # extension, points NAUTILUS_4_EXTENSION_DIR at it, and writes the terminal
    # choice to a locked system dconf profile.
    programs.nautilus-open-any-terminal = lib.mkIf (cfg.terminal != null) {
      enable = true;
      terminal = cfg.terminal;
    };

    # Per-user default file-manager association.
    home-manager.users = lib.genAttrs cfg.users (_: {
      xdg.mimeApps = {
        enable = true;
        defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";
      };
    });
  };
}
