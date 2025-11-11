#!/usr/bin/env bash

# Read current setting
current=$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null)

if [[ "$current" == "'prefer-dark'" ]] || [[ "$current" == "" ]]; then
  dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
  echo "Switched to light theme"
else
  dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
  echo "Switched to dark theme"
fi

# Verify the change
echo "Current setting:"
dbus-send --session --print-reply \
  --dest=org.freedesktop.portal.Desktop \
  /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings.Read \
  string:'org.freedesktop.appearance' \
  string:'color-scheme' 2>/dev/null | grep -A1 variant
