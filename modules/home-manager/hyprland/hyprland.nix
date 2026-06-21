{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  enable = lib.mkEnableOption "Hyprland window manager";
  exec_once = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Additional programs to execute once on startup";
  };
  additional_envs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Additional environment variables in format 'VAR,value'";
  };
  window_rules = lib.mkOption {
    type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
    default = [ ];
    description = ''
      Window rules as Lua tables, one per `hl.window_rule(...)` call.
      Each entry is an attrset, e.g. `{ workspace = 1; match.class = "Alacritty"; }`.
    '';
  };
  package = lib.mkPackageOption pkgs "hyprland" { };
  display_manager = lib.mkEnableOption "display_manager";
  status_bar = lib.mkOption {
    type = lib.types.enum [
      "waybar"
      "none"
    ];
    default = "waybar";
    description = "Status bar to use";
  };

  terminal = "${config.programs.alacritty.package}/bin/alacritty";
  mainMod = "SUPER";

  inline = lib.generators.mkLuaInline;

  # Catppuccin Macchiato palette. catppuccin/nix has no Lua support for Hyprland
  # (it only injects hyprlang `source` + $vars, which Hyprland's Lua config can
  # neither source nor resolve), so the colours used below are inlined here.
  ctp = {
    lavender = "rgb(b7bdf8)";
    mauve = "rgb(c6a0f6)";
    overlay0 = "rgb(6e738d)";
    crustAlpha = "181926";
    mauveAlpha = "c6a0f6";
    surface0Alpha = "363a4f";
  };

  # home-manager renders `{ _args = [...]; }` entries as `hl.bind(a, b, ...)`.
  execCmd = cmd: ''hl.dsp.exec_cmd("${cmd}")'';
  mkBind = keys: dispatcher: { _args = [ keys (inline dispatcher) ]; };
  mkBindO = keys: dispatcher: opts: { _args = [ keys (inline dispatcher) opts ]; };

  lockedRepeat = {
    locked = true;
    repeating = true;
  };
  locked = {
    locked = true;
  };
  mouse = {
    mouse = true;
  };

  hyprshot_bin = "${pkgs.hyprshot}/bin/hyprshot";
  wpctl_bin = "${pkgs.wireplumber}/bin/wpctl";
  brightnessctl_bin = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl_bin = "${pkgs.playerctl}/bin/playerctl";

  # SUPER + 1..0 -> focus workspace; SUPER + SHIFT + 1..0 -> move window there.
  # Keycodes (code:10..code:19) keep the binds layout-independent.
  workspaceBinds = lib.concatMap (
    i:
    let
      code = "code:${toString (9 + i)}";
    in
    [
      (mkBind "${mainMod} + ${code}" "hl.dsp.focus({ workspace = ${toString i} })")
      (mkBind "${mainMod} + SHIFT + ${code}" "hl.dsp.window.move({ workspace = ${toString i} })")
    ]
  ) (lib.range 1 10);

  # exec_once equivalent: a `hl.on("hyprland.start", ...)` autostart hook.
  startupCmds = [
    "${pkgs.hyprland}/bin/hyprctl hyprpaper"
    terminal
  ]
  ++ lib.optional (cfg.status_bar == "waybar") "waybar"
  ++ cfg.exec_once;

  startHook = inline (
    "function()\n"
    + lib.concatMapStringsSep "\n" (c: ''hl.exec_cmd("${c}")'') startupCmds
    + "\nend"
  );

  # "VAR,value" -> hl.env("VAR", "value")
  mkEnv =
    s:
    let
      parts = lib.splitString "," s;
    in
    {
      _args = [
        (builtins.head parts)
        (lib.concatStringsSep "," (builtins.tail parts))
      ];
    };
in
{
  options.home_modules.hyprland = {
    inherit
      enable
      window_rules
      exec_once
      additional_envs
      package
      display_manager
      status_bar
      ;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # nwg-displays 0.4.3 is the first release that writes monitors.lua /
      # workspaces.lua (loaded below via require); nixpkgs is still on 0.4.1.
      (lib.mkIf cfg.display_manager (
        pkgs.nwg-displays.overrideAttrs (old: {
          version = "0.4.3";
          src = pkgs.fetchFromGitHub {
            owner = "nwg-piotr";
            repo = "nwg-displays";
            tag = "v0.4.3";
            hash = "sha256-f7x6PTsND0eprhqvIdkZdHujcCbkJnqoXIKeE0O/YPE=";
          };
        })
      ))
    ];

    programs.elephant = {
      enable = true;
      installService = true;
    };

    services.cliphist.enable = lib.mkDefault true;

    home_modules = {
      walker.enable = lib.mkDefault true;
      swaync.enable = lib.mkDefault true;
      hyprland.awww.enable = lib.mkDefault true;
      waybar.enable = cfg.status_bar == "waybar";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = cfg.package;

      configType = "lua";

      # catppuccin/nix unconditionally injects a hyprlang `source` for its
      # palette; under Lua that would render as a non-existent `hl.source(...)`.
      # Neutralise it (its cursor env vars are kept) and inline colours instead.
      settings.source = lib.mkForce [ ];

      settings = {
        monitor = {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "auto";
        };

        env = map mkEnv (
          [
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
            "NIXOS_OZONE_WL,1"
          ]
          ++ cfg.additional_envs
        );

        config = {
          ecosystem.no_update_news = true;

          general = {
            gaps_in = 4;
            gaps_out = 4;
            border_size = 2;
            col = {
              active_border = {
                colors = [
                  ctp.lavender
                  ctp.mauve
                ];
                angle = 45;
              };
              inactive_border = ctp.overlay0;
            };
            resize_on_border = true;
            allow_tearing = false;
            layout = "dwindle";
          };

          decoration = {
            rounding = 8;
            rounding_power = 2;
            active_opacity = 0.95;
            inactive_opacity = 0.88;
            fullscreen_opacity = 1.0;

            shadow = {
              enabled = true;
              range = 8;
              render_power = 3;
              color = "rgba(${ctp.crustAlpha}cc)";
            };

            blur = {
              enabled = true;
              size = 6;
              passes = 3;
              new_optimizations = true;
              ignore_opacity = true;
              vibrancy = 0.2;
              noise = 0.02;
            };
          };

          animations.enabled = true;

          # `dwindle.pseudotile` was removed in 0.55; pseudotiling is now a
          # per-window action via the `pseudo` dispatcher (SUPER + P below).
          dwindle.preserve_split = true;

          master.new_status = "master";

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };

          input = {
            kb_layout = "us";
            kb_variant = "altgr-intl";
            kb_model = "pc105";
            kb_options = "grp:alt_space_toggle";
            kb_rules = "";
            resolve_binds_by_sym = true;
            follow_mouse = 1;
            sensitivity = 0;

            touchpad.natural_scroll = false;
          };

          group = {
            col = {
              border_active = ctp.lavender;
              border_inactive = ctp.overlay0;
            };
            groupbar = {
              font_size = 11;
              height = 20;
              render_titles = true;
              gradients = true;
              col = {
                active = "rgba(${ctp.mauveAlpha}ff)";
                inactive = "rgba(${ctp.surface0Alpha}ff)";
              };
              text_color = "rgba(${ctp.crustAlpha}ff)";
            };
          };
        };

        curve = [
          {
            _args = [
              "easeOutQuint"
              {
                type = "bezier";
                points = [
                  [ 0.23 1 ]
                  [ 0.32 1 ]
                ];
              }
            ];
          }
          {
            _args = [
              "easeInOutCubic"
              {
                type = "bezier";
                points = [
                  [ 0.65 0.05 ]
                  [ 0.36 1 ]
                ];
              }
            ];
          }
          {
            _args = [
              "linear"
              {
                type = "bezier";
                points = [
                  [ 0 0 ]
                  [ 1 1 ]
                ];
              }
            ];
          }
          {
            _args = [
              "almostLinear"
              {
                type = "bezier";
                points = [
                  [ 0.5 0.5 ]
                  [ 0.75 1 ]
                ];
              }
            ];
          }
          {
            _args = [
              "quick"
              {
                type = "bezier";
                points = [
                  [ 0.15 0 ]
                  [ 0.1 1 ]
                ];
              }
            ];
          }
        ];

        animation = [
          {
            leaf = "global";
            enabled = true;
            speed = 10;
            bezier = "default";
          }
          {
            leaf = "border";
            enabled = true;
            speed = 5.39;
            bezier = "easeOutQuint";
          }
          {
            leaf = "windows";
            enabled = true;
            speed = 4.79;
            bezier = "easeOutQuint";
          }
          {
            leaf = "windowsIn";
            enabled = true;
            speed = 4.1;
            bezier = "easeOutQuint";
            style = "popin 87%";
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 1.49;
            bezier = "linear";
            style = "popin 87%";
          }
          {
            leaf = "fadeIn";
            enabled = true;
            speed = 1.73;
            bezier = "almostLinear";
          }
          {
            leaf = "fadeOut";
            enabled = true;
            speed = 1.46;
            bezier = "almostLinear";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 3.03;
            bezier = "quick";
          }
          {
            leaf = "layers";
            enabled = true;
            speed = 3.81;
            bezier = "easeOutQuint";
          }
          {
            leaf = "layersIn";
            enabled = true;
            speed = 4;
            bezier = "easeOutQuint";
            style = "fade";
          }
          {
            leaf = "layersOut";
            enabled = true;
            speed = 1.5;
            bezier = "linear";
            style = "fade";
          }
          {
            leaf = "fadeLayersIn";
            enabled = true;
            speed = 1.79;
            bezier = "almostLinear";
          }
          {
            leaf = "fadeLayersOut";
            enabled = true;
            speed = 1.39;
            bezier = "almostLinear";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 1.94;
            bezier = "almostLinear";
            style = "fade";
          }
          {
            leaf = "workspacesIn";
            enabled = true;
            speed = 1.21;
            bezier = "almostLinear";
            style = "fade";
          }
          {
            leaf = "workspacesOut";
            enabled = true;
            speed = 1.94;
            bezier = "almostLinear";
            style = "fade";
          }
          {
            leaf = "zoomFactor";
            enabled = true;
            speed = 7;
            bezier = "quick";
          }
        ];

        gesture = {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        };

        device = {
          name = "epic-mouse-v1";
          sensitivity = -0.5;
        };

        bind = [
          (mkBind "${mainMod} + Return" (execCmd terminal))
          (mkBind "${mainMod} + Q" "hl.dsp.window.close()")
          (mkBind "${mainMod} + E" (execCmd "${pkgs.nautilus}/bin/nautilus"))
          (mkBind "${mainMod} + V" ''hl.dsp.window.float({ action = "toggle" })'')
          (mkBind "${mainMod} + C" (execCmd "${pkgs.cliphist}/bin/cliphist list | ${pkgs.walker}/bin/walker --dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"))
          (mkBind "${mainMod} + Space" (execCmd "${config.services.walker.package}/bin/walker"))
          (mkBind "${mainMod} + P" "hl.dsp.window.pseudo()")
          (mkBind "${mainMod} + J" ''hl.dsp.layout("togglesplit")'')

          (mkBind "${mainMod} + left" ''hl.dsp.focus({ direction = "left" })'')
          (mkBind "${mainMod} + right" ''hl.dsp.focus({ direction = "right" })'')
          (mkBind "${mainMod} + up" ''hl.dsp.focus({ direction = "up" })'')
          (mkBind "${mainMod} + down" ''hl.dsp.focus({ direction = "down" })'')

          (mkBind "${mainMod} + SHIFT + left" ''hl.dsp.window.move({ direction = "left" })'')
          (mkBind "${mainMod} + SHIFT + right" ''hl.dsp.window.move({ direction = "right" })'')
          (mkBind "${mainMod} + SHIFT + up" ''hl.dsp.window.move({ direction = "up" })'')
          (mkBind "${mainMod} + SHIFT + down" ''hl.dsp.window.move({ direction = "down" })'')

          (mkBind "${mainMod} + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
          (mkBind "${mainMod} + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')

          (mkBind "${mainMod} + F" "hl.dsp.group.toggle()")
          (mkBind "${mainMod} + TAB" "hl.dsp.group.next()")
          (mkBind "${mainMod} + SHIFT + TAB" "hl.dsp.group.prev()")
          (mkBind "${mainMod} + SHIFT + F" "hl.dsp.window.fullscreen()")
          (mkBind "${mainMod} + L" (execCmd "loginctl lock-session"))
          (mkBind "${mainMod} + SHIFT + L" "hl.dsp.exit()")
          (mkBind "${mainMod} + I" (execCmd "${lib.getExe config.home_modules.hyprland.hypridle.toggleScript}"))
          (mkBind "${mainMod} + S" (execCmd "${lib.getExe config.home_modules.hyprland.hypridle.sleepScript}"))
          (mkBind "${mainMod} + SHIFT + S" (execCmd "systemctl poweroff"))
          (mkBind "${mainMod} + SHIFT + R" (execCmd "systemctl reboot"))

          (mkBind "${mainMod} + PRINT" (execCmd "${hyprshot_bin} -m window"))
          (mkBind "PRINT" (execCmd "${hyprshot_bin} -m output"))
          (mkBind "${mainMod} + SHIFT + PRINT" (execCmd "${hyprshot_bin} -m region"))
        ]
        ++ workspaceBinds
        ++ [
          # bindel: locked + repeating (volume / brightness)
          (mkBindO "XF86AudioRaiseVolume" (execCmd "${wpctl_bin} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") lockedRepeat)
          (mkBindO "XF86AudioLowerVolume" (execCmd "${wpctl_bin} set-volume @DEFAULT_AUDIO_SINK@ 5%-") lockedRepeat)
          (mkBindO "XF86AudioMute" (execCmd "${wpctl_bin} set-mute @DEFAULT_AUDIO_SINK@ toggle") lockedRepeat)
          (mkBindO "XF86AudioMicMute" (execCmd "${wpctl_bin} set-mute @DEFAULT_AUDIO_SOURCE@ toggle") lockedRepeat)
          (mkBindO "XF86MonBrightnessUp" (execCmd "${brightnessctl_bin} -e4 -n2 set 5%+") lockedRepeat)
          (mkBindO "XF86MonBrightnessDown" (execCmd "${brightnessctl_bin} -e4 -n2 set 5%-") lockedRepeat)

          # bindl: locked (media keys)
          (mkBindO "XF86AudioNext" (execCmd "${playerctl_bin} next") locked)
          (mkBindO "XF86AudioPause" (execCmd "${playerctl_bin} play-pause") locked)
          (mkBindO "XF86AudioPlay" (execCmd "${playerctl_bin} play-pause") locked)
          (mkBindO "XF86AudioPrev" (execCmd "${playerctl_bin} previous") locked)

          # bindm: mouse drag bindings
          (mkBindO "${mainMod} + mouse:272" "hl.dsp.window.drag()" mouse)
          (mkBindO "${mainMod} + mouse:273" "hl.dsp.window.resize()" mouse)
        ];

        window_rule = [
          {
            match.class = ".*";
            suppress_event = "maximize";
          }
          {
            match = {
              class = "^$";
              title = "^$";
              xwayland = true;
              float = true;
              fullscreen = false;
              pin = false;
            };
            no_focus = true;
          }
        ]
        ++ cfg.window_rules;

        on = {
          _args = [
            "hyprland.start"
            startHook
          ];
        };
      };

      # nwg-displays (0.4.3+) writes these Lua files; pcall keeps startup safe
      # if they don't exist yet (e.g. before the GUI is first run).
      extraConfig = lib.mkIf cfg.display_manager ''
        pcall(require, "monitors")
        pcall(require, "workspaces")
      '';
    };
  };
}
