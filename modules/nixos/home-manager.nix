{
  inputs,
  config,
  pkgs,
  lib,
  nixosProfile ? "full",
  ...
}:

let
  user = "edattore";
  browser = if pkgs.stdenv.hostPlatform.isAarch64 then "chromium" else "google-chrome-stable";
  shared-programs = import ../shared/home-manager.nix {
    inherit
      inputs
      config
      pkgs
      lib
      ;
    profile = nixosProfile;
  };
  shared-files = import ../shared/files.nix {
    inherit config pkgs;
    profile = nixosProfile;
  };

  hyprlandSettings = {
    "$mod" = "SUPER";
    "$terminal" = "ghostty";
    "$launcher" = "walker";
    "$browser" = browser;
    "$fileManager" = "pcmanfm";

    monitor = ",preferred,auto,2";

    env = [
      "XCURSOR_SIZE,24"
      "HYPRCURSOR_SIZE,24"
      "NIXOS_OZONE_WL,1"
    ];

    exec-once = [
      "hyprpanel"
      "hypridle"
      "mako"
      "wl-paste --watch cliphist store"
    ];

    input = {
      kb_layout = "us";
      kb_options = "ctrl:nocaps";
      follow_mouse = 1;
      touchpad = {
        natural_scroll = true;
        tap-to-click = true;
      };
    };

    general = {
      gaps_in = 5;
      gaps_out = 16;
      border_size = 2;
      layout = "dwindle";
    };

    decoration = {
      rounding = 12;
      shadow = {
        enabled = true;
        range = 8;
        render_power = 3;
      };
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
      };
    };

    animations = {
      enabled = true;
      bezier = "easeOutQuint,0.23,1,0.32,1";
      animation = [
        "windows,1,4,easeOutQuint"
        "border,1,6,default"
        "fade,1,4,default"
        "workspaces,1,4,easeOutQuint"
      ];
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    misc = {
      disable_hyprland_logo = true;
      force_default_wallpaper = 0;
    };

    bind = [
      "$mod, Return, exec, $terminal"
      "$mod, Space, exec, $launcher"
      "$mod SHIFT, X, exec, keepassxc"
      "CTRL ALT, Return, exec, $browser"
      "$mod SHIFT, Space, exec, $fileManager"
      "$mod, Q, killactive,"
      "ALT, F4, killactive,"
      "$mod, F, fullscreen,"
      "$mod, D, togglefloating,"
      "$mod, G, togglegroup,"
      "$mod SHIFT, G, changegroupactive, f"
      "$mod, Tab, workspace, previous"
      "CTRL ALT, BackSpace, exec, hyprlock"
      "$mod, H, movefocus, l"
      "$mod, J, movefocus, d"
      "$mod, K, movefocus, u"
      "$mod, L, movefocus, r"
      "$mod SHIFT, H, movewindow, l"
      "$mod SHIFT, J, movewindow, d"
      "$mod SHIFT, K, movewindow, u"
      "$mod SHIFT, L, movewindow, r"
      "$mod, T, workspace, 2"
      "$mod, B, workspace, 1"
      "$mod, W, workspace, 4"
      "$mod, Left, workspace, e-1"
      "$mod, Right, workspace, e+1"
      "$mod, Up, workspace, e-1"
      "$mod, Down, workspace, e+1"
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"
      "$mod, 8, workspace, 8"
      "$mod, 9, workspace, 9"
      "$mod, 0, workspace, 10"
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"
      "$mod SHIFT, 8, movetoworkspace, 8"
      "$mod SHIFT, 9, movetoworkspace, 9"
      "$mod SHIFT, 0, movetoworkspace, 10"
      '', Print, exec, grim -g "$(slurp)" - | wl-copy''
      "SHIFT, Print, exec, grim - | wl-copy"
    ];

    bindel = [
      ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
      ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
    ];

    bindl = [
      ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
    ];

    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
  };

in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix { profile = nixosProfile; };
    file = shared-files // import ./files.nix { profile = nixosProfile; };
    stateVersion = "25.11";
  };

  # Use a dark theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    gtk4.theme = config.gtk.theme;
  };

  services = {
    # Auto mount devices
    udiskie.enable = true;
  };

  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant application launcher backend";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = lib.getExe pkgs.elephant;
      Restart = "always";
      RestartSec = 10;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = true;
    settings = hyprlandSettings;
  };

  programs = shared-programs // {
    gpg.enable = true;
  };

}
