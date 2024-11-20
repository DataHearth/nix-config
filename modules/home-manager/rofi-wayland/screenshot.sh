#!/usr/bin/env bash

theme="$HOME/.config/rofi/screenshot.rasi"
out_dir="$HOME/Pictures/screenshots"
filename=$(date '+%Y%m%d-%H:%M:%S').png
prompt='Screenshot'
mesg="File: $out_dir/$filename"

# Options
option_1=" "
option_2=" "
option_3="󰣆 "
option_4="󰞤 "

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -theme "$theme"
}

# Actions
chosen="$(echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd)"
case $chosen in
"$option_1")
  grim -g "$(slurp -o -r -c '#ff0000ff')" - | satty --filename - --output-filename "$out_dir/$filename"
  ;;

"$option_2")
  HYPRSHOT_DIR=$out_dir hyprshot --mode output --filename "$filename"
  ;;

"$option_3")
  HYPRSHOT_DIR=$out_dir hyprshot --mode window --filename "$filename"
  ;;

"$option_4")
  HYPRSHOT_DIR=$out_dir hyprshot --mode region --filename "$filename"
  ;;
esac
