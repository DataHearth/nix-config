{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.home_modules.chromium;

  # Chrome Web Store ID of the "Claude in Chrome" extension.
  claudeExtensionId = "fcoeoabgfenejglbffodgkkbkcdhcgfn";
in
{
  options.home_modules.chromium = {
    enable = lib.mkEnableOption "chromium";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.chromium;
      defaultText = lib.literalExpression "pkgs.chromium";
      description = "The Chromium package to use.";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ]; # uBlock Origin
      description = ''
        Chrome Web Store extension IDs to force-install via managed policy. The
        Claude extension is appended automatically when claudeInChrome is set.
      '';
    };

    commandLineArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra Chromium command-line flags. Wayland is already handled by the
        global NIXOS_OZONE_WL=1 (home.nix), so no ozone flag is needed here.
      '';
    };

    claudeInChrome = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Force-install the "Claude in Chrome" extension and write the
        native-messaging-host manifest so Claude Code's /chrome integration can
        drive Chromium. The manifest points at the host binary Claude Code drops
        at ~/.claude/chrome/chrome-native-host on first `/chrome`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = cfg.package;
      commandLineArgs = cfg.commandLineArgs;
      extensions = cfg.extensions ++ lib.optional cfg.claudeInChrome claudeExtensionId;
    };

    # Chrome/Edge get this manifest auto-installed by Claude Code on first
    # `/chrome`; Chromium does not, so declare it at the per-user location
    # (~/.config/chromium/NativeMessagingHosts) Chromium reads on startup.
    xdg.configFile."chromium/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json" =
      lib.mkIf cfg.claudeInChrome {
        text = builtins.toJSON {
          name = "com.anthropic.claude_code_browser_extension";
          description = "Claude Code browser extension native messaging host";
          path = "${config.home.homeDirectory}/.claude/chrome/chrome-native-host";
          type = "stdio";
          allowed_origins = [ "chrome-extension://${claudeExtensionId}/" ];
        };
      };
  };
}
