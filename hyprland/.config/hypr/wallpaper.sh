#!/bin/bash
pkill hyprpaper
hyprpaper & disown
sleep 0.5
hyprctl hyprpaper wallpaper "DP-1,/home/jorisgriaud/Images/Wallpapers/background_main.jpg"
hyprctl hyprpaper wallpaper "HDMI-A-1,/home/jorisgriaud/Images/Wallpapers/background_main.jpg"
