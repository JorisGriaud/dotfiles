#!/bin/bash
# Les fonds d'écran sont définis dans hyprpaper.conf
pkill -x hyprpaper
hyprpaper & disown
