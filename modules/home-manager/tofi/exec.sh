#!/usr/bin/env bash

config_dir="$HOME/.config/tofi"

function confirm {
  action=$1

  confirm=$(echo -e "Yes\nNo" | tofi -c $config_dir/confirm.conf)

  if [ "$confirm" = "Yes" ]; then
    eval $action
  fi
}

function powermenu {
  poweroff=" Poweroff"
  reboot=" Reboot"
  lock=" Lock"
  suspend=" Suspend"
  logout=" Logout"

  action=$(echo -e "$poweroff\n$reboot\n$lock\n$suspend\n$logout" |\
    tofi -c $config_dir/powermenu.conf)

  case $action in
    $poweroff)
      confirm "systemctl poweroff"
      ;;

    $reboot)
      confirm "systemctl reboot"
      ;;

    $lock)
      sleep 0.5s; swaylock & disown
      ;;

    $suspend)
      sleep 0.5s; swaylock & disown
      systemctl suspend
      ;;

    $logout)
      confirm "hyprctl dispatch exit"
      ;;
  esac
}

function launcher {
  tofi-drun -c $config_dir/launcher.conf |\
    xargs hyprctl dispatch exec --
}

function screenshot {
  annotate=" Annotate"
  fullscreen=" Fullscreen"
  region="󰞤 Region"
  window="󰣆 Window"

  action=$(echo -e "$annotate\n$fullscreen\n$window\n$region" | \
    tofi -c $config_dir/screenshot.conf)

  out_dir="$HOME/Pictures/screenshots"
  filename=$(date '+%Y%m%d-%H:%M:%S').png
  case $action in
    $annotate)
      grim -g "$(slurp -o -r -c '#ff0000ff')" - | satty --filename - --output-filename $out_dir/$filename
      ;;

    $fullscreen)
      HYPRSHOT_DIR=$out_dir hyprshot --mode output --filename $filename
      ;;

    $window)
      HYPRSHOT_DIR=$out_dir hyprshot --mode window --filename $filename
      ;;

    $region)
      HYPRSHOT_DIR=$out_dir hyprshot --mode region --filename $filename
      ;;
  esac
}

function clipboard {
  cliphist list | sed -E "s/(.{40}).*$/\1.../" |\
    tofi -c "$config_dir/clipboard.conf" |\
    cliphist decode |\
    wl-copy
}

function run {
  tofi-run -c $config_dir/launcher.conf |\
    xargs hyprctl dispatch exec --
}

case $1 in
  powermenu)
    powermenu
    ;;

  launcher)
    launcher
    ;;

  screenshot)
    screenshot
    ;;

  clipboard)
    clipboard
    ;;

  run)
    run
    ;;
esac
