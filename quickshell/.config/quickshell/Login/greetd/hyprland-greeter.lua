-- Hyprland minimal qui ne sert qu'à afficher le greeter Quickshell.
-- Installé dans /etc/greetd/hyprland-greeter.lua par install.sh.

hl.monitor({ output = "DP-1",     mode = "3840x2160@144", position = "0x0",     scale = "1.5" })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@165", position = "-1920x0", scale = "1" })

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.config({
    input = {
        kb_layout    = "fr",
        follow_mouse = 1,
        sensitivity  = -0.3,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})

-- le greeter ; quand il quitte (session lancée), on ferme ce Hyprland
-- pour que greetd démarre la vraie session
hl.on("hyprland.start", function ()
    hl.exec_cmd("sh -c 'qs -p /etc/greetd/quickshell/greeter.qml > /tmp/quickshell-greeter.log 2>&1; hyprctl dispatch \"hl.dsp.exit()\" || hyprctl dispatch exit'")
end)
