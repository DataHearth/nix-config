#!/usr/bin/env bash

# Current Theme
dir="$HOME/.config/rofi"

# CMDs
uptime=$(awk '{printf("%d days, %d hours, %d minutes\n",($1/60/60/24),($1/60/60%24),($1/60%60))}' /proc/uptime)

# Options
shutdown='  Shutdown'
reboot='󰑐  Reboot'
lock='  Lock'
suspend='󰤄  Sleep'
logout='  Logout'
yes=''
no=''

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p "Goodbye ${USER}" \
    -mesg "Uptime: $uptime" \
    -theme "${dir}/powermenu.rasi"
}

# Confirmation CMD
confirm_cmd() {
  rofi -dmenu \
    -p 'Confirmation' \
    -mesg 'Are you Sure?' \
    -theme "${dir}/confirm.rasi"
}

# Ask for confirmation
confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

# Actions
chosen=$(echo -e "$suspend\n$lock\n$logout\n$reboot\n$shutdown" | rofi_cmd)
case ${chosen} in
"$shutdown")
  if [[ $(confirm_exit) == "$yes" ]]; then
    systemctl poweroff
  fi
  ;;
"$reboot")
  if [[ $(confirm_exit) == "$yes" ]]; then
    systemctl reboot
  fi
  ;;
"$lock")
  sleep 0.5s
  hyprlock &
  disown
  ;;
"$suspend")
  playerctl pause
  sleep 0.5s
  hyprlock &
  disown
  systemctl suspend
  ;;
"$logout")
  if [[ $(confirm_exit) == "$yes" ]]; then
    hyprctl dispatch exit
  fi
  ;;
esac
