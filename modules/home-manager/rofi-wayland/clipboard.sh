#!/usr/bin/env bash

theme="$HOME/.config/rofi/clipboard.rasi"

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p "Clipboard" \
    -theme "$theme"
}

cliphist list | sed -E "s/(.{40}).*$/\1.../" |
  rofi_cmd |
  cliphist decode |
  wl-copy
