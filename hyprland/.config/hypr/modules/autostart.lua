-------------------
---- AUTOSTART ----
-------------------;

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
   -- hl.exec_cmd("sh /home/jorisgriaud/.config/waybar/scripts/launch.sh")
   hl.exec_cmd("quickshell -d")
   hl.exec_cmd("sh /home/jorisgriaud/.config/hypr/wallpaper.sh")
   hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
   hl.exec_cmd("set EDITOR /usr/bin/nvim")
end)
