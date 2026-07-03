{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.greetd;

  enable = lib.mkEnableOption "greetd display manager";
  internalMonitor = lib.mkOption {
    type = lib.types.str;
    default = "eDP-1";
    description = ''
      Connector name of the built-in panel. The greeter renders ReGreet on this
      output and mirrors it onto every other connected monitor, so the login box
      is correctly centred on each screen regardless of how many are attached.
    '';
  };

  # ReGreet centres its login form inside its own window. cage (the regreet
  # module's default greeter) has no way to target a named output, and in its
  # `extend` mode it sizes ReGreet's window to the *union* of every output, so
  # with mismatched monitors the form lands in the gap between them — off-screen
  # on the internal panel. cage 0.3.0 can neither mirror nor pick a named output,
  # so instead we host the greeter under a throwaway Hyprland: ReGreet fills the
  # internal panel (correctly centred) and every other output mirrors it.
  regreetBin = lib.getExe config.programs.regreet.package;
  hyprctlBin = lib.getExe' pkgs.hyprland "hyprctl";

  greeterSession = pkgs.writeShellScript "regreet-session" ''
    ${regreetBin}
    # ReGreet only returns here if login was cancelled/failed; tear the greeter
    # compositor down so greetd restarts it cleanly.
    ${hyprctlBin} dispatch exit
  '';

  greeterConfig = pkgs.writeText "greetd-hyprland.conf" ''
    monitor = ${cfg.internalMonitor}, preferred, 0x0, 1
    monitor = , preferred, auto, 1, mirror, ${cfg.internalMonitor}

    exec-once = ${greeterSession}

    ecosystem {
      no_update_news = true
    }
    general {
      gaps_in = 0
      gaps_out = 0
      border_size = 0
    }
    decoration {
      rounding = 0
    }
    animations {
      enabled = false
    }
    misc {
      disable_hyprland_logo = true
      force_default_wallpaper = 0
      background_color = 0xff24273a
    }
  '';
in
{
  options.nixos_modules.greetd = {
    inherit enable internalMonitor;
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    programs.regreet = {
      enable = true;
      theme = {
        name = "catppuccin-macchiato-mauve-standard";
        package = pkgs.catppuccin-gtk.override {
          variant = "macchiato";
          accents = [ "mauve" ];
        };
      };
      cursorTheme = {
        name = "catppuccin-macchiato-mauve-cursors";
        package = pkgs.catppuccin-cursors.macchiatoMauve;
      };
    };

    # Replace the regreet module's cage-based session (set with mkDefault) with
    # the mirrored Hyprland greeter above. dbus-run-session gives ReGreet's GTK a
    # session bus, matching what the upstream cage command provided.
    services.greetd.settings.default_session.command =
      "${lib.getExe' pkgs.dbus "dbus-run-session"} ${lib.getExe pkgs.hyprland} --config ${greeterConfig}";
  };
}
