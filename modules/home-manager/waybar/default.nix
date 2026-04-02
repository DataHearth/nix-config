{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.waybar;
  kbLayouts = config.wayland.windowManager.hyprland.settings.input.kb_layout or "";
  hasMultipleLayouts = builtins.length (lib.splitString "," kbLayouts) > 1;

  enable = lib.mkEnableOption "waybar";
in
{
  options.home_modules.waybar = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = false;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 34;
          spacing = 4;

          modules-left = [
            "hyprland/workspaces"
            "group/system"
          ];

          modules-center = [
            "clock"
          ];

          modules-right = [
            "group/hardware"
            "group/info"
            "tray"
          ];

          "group/system" = {
            orientation = "horizontal";
            modules = [
              "cpu"
              "memory"
              "temperature"
            ];
          };

          "group/hardware" = {
            orientation = "horizontal";
            modules = [
              "backlight"
              "pulseaudio"
              "network"
              "bluetooth"
              "battery"
            ];
          };

          "group/info" = {
            orientation = "horizontal";
            modules = [
              "custom/hypridle"
            ] ++ lib.optionals hasMultipleLayouts [
              "hyprland/language"
            ] ++ [
              "custom/notification"
            ];
          };

          "custom/hypridle" = {
            tooltip = true;
            format = "{icon}";
            format-icons = {
              enabled = "󰒲";
              disabled = "󰒳";
            };
            return-type = "json";
            exec = lib.getExe config.home_modules.hyprland.hypridle.statusScript;
            on-click = lib.getExe config.home_modules.hyprland.hypridle.toggleScript;
            interval = "once";
            signal = 8;
          };

          "hyprland/workspaces" = {
            format = "{name}";
            on-click = "activate";
            on-scroll-up = "hyprctl dispatch workspace e-1";
            on-scroll-down = "hyprctl dispatch workspace e+1";
          };

          "hyprland/window" = {
            format = "{}";
            max-length = 50;
            separate-outputs = true;
          };

          clock = {
            format = "{:%a %d %b %H:%M}";
            tooltip-format = "<tt>{calendar}</tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 4;
              weeks-pos = "right";
              format = {
                months = "<span color='#f4dbd6'><b>{}</b></span>";
                days = "<span color='#cad3f5'>{}</span>";
                weeks = "<span color='#c6a0f6'>W{}</span>";
                weekdays = "<span color='#a6da95'>{}</span>";
                today = "<span color='#ed8796'><b><u>{}</u></b></span>";
              };
            };
          };

          cpu = {
            format = "󰔂 {usage}%";
            tooltip = true;
            interval = 2;
          };

          memory = {
            format = " {}%";
            tooltip-format = "{used:0.1f}GB / {total:0.1f}GB";
            interval = 2;
          };

          temperature = {
            format = "󰔏 {temperatureC}°C";
            tooltip = true;
            interval = 2;
            critical-threshold = 80;
            format-critical = "󰸁 {temperatureC}°C";
          };

          backlight = {
            format = "{icon} {percent}%";
            format-icons = [ "󰃞" "󰃟" "󰃠" ];
            scroll-step = 5;
            on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%+";
            on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%-";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-bluetooth = "󰂱 {volume}%";
            format-muted = "󰸈 muted";
            format-icons = {
              headphone = "󰋋";
              hands-free = "󰋎";
              headset = "󰋎";
              phone = "󰏲";
              portable = "󰏲";
              car = "󰄋";
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
            };
            on-click = "${pkgs.pwmenu}/bin/pwmenu -l custom --launcher-command 'walker -d' -s 3";
            on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            scroll-step = 5;
          };

          network = {
            format-wifi = "󰤨 {signalStrength}%";
            format-ethernet = "󰈀 {ipaddr}";
            format-disconnected = "󰤭";
            tooltip-format-wifi = "{essid} ({signalStrength}%)";
            tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
            on-click = "${pkgs.iwmenu}/bin/iwmenu -l custom --launcher-command 'walker -d' -s 3";
          };

          bluetooth = {
            format = "󰂯 {status}";
            format-connected = "󰂱 {device_alias}";
            format-connected-battery = "󰂱 {device_alias} {device_battery_percentage}%";
            tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
            on-click = "${pkgs.bzmenu}/bin/bzmenu -l custom --launcher-command 'walker -d' -s 3";
          };

          battery = {
            bat = "BAT1";
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰂄 {capacity}%";
            format-icons = [
              "󰂃"
              "󰁼"
              "󰁾"
              "󰂀"
              "󰁹"
            ];
            tooltip-format = "{timeTo} ({power} W)";
            on-click = let
              script = pkgs.writeShellScript "power-profile-menu" ''
                choice=$(printf "󰌪 power-saver\n󰛲 balanced\n󰓅 performance" | walker -d)
                [ -z "$choice" ] && exit 0
                profile=$(echo "$choice" | sed 's/^[^ ]* //')
                powerprofilesctl set "$profile"
              '';
            in "${script}";
          };

          "hyprland/language" = lib.mkIf hasMultipleLayouts {
            format = "{}";
            format-en = "🇺🇸";
            format-fr = "🇫🇷";
            on-click = "hyprctl switchxkblayout all next";
          };

          "custom/notification" = {
            tooltip = false;
            format = "{icon}";
            format-icons = {
              notification = "󰂚";
              none = "󰂜";
              dnd-notification = "󰂛";
              dnd-none = "󰪑";
            };
            return-type = "json";
            exec = "swaync-client -swb";
            on-click = "swaync-client -t -sw";
            on-click-right = "swaync-client -d -sw";
            escape = true;
          };

          tray = {
            spacing = 10;
          };
        };
      };

      style = builtins.readFile ./style.css;
    };
  };
}
