{
  pkgs,
  user,
  profile ? "full",
  ...
}:

let
  browser = if pkgs.stdenv.hostPlatform.isAarch64 then "chromium" else "google-chrome-stable";
  xdg_configHome = ".config";
  isVm = profile == "vm";
  vmHyprpanelConfig = builtins.toJSON {
    "theme.bar.scaling" = 85;
    "theme.bar.margin_sides" = "0.2em";
    "theme.bar.outer_spacing" = "0.6em";
    "theme.bar.label_spacing" = "0.25em";
    "bar.windowtitle.truncation" = true;
    "bar.windowtitle.truncation_size" = 20;
    "bar.layouts" = {
      "0" = {
        left = [
          "dashboard"
          "workspaces"
        ];
        middle = [ "clock" ];
        right = [
          "volume"
          "notifications"
        ];
      };
      "1" = {
        left = [
          "dashboard"
          "workspaces"
        ];
        middle = [ "clock" ];
        right = [
          "volume"
          "notifications"
        ];
      };
      "2" = {
        left = [
          "dashboard"
          "workspaces"
        ];
        middle = [ "clock" ];
        right = [
          "volume"
          "notifications"
        ];
      };
    };
  };
in
{
  "${xdg_configHome}/hypr/hyprland.conf" = {
    text = ''
      $mod = SUPER
      $terminal = ghostty
      $launcher = walker
      $browser = ${browser}
      $fileManager = pcmanfm

      monitor=,preferred,auto,2

      env = XCURSOR_SIZE,24
      env = HYPRCURSOR_SIZE,24
      env = NIXOS_OZONE_WL,1

      exec-once = hyprpanel
      exec-once = hypridle
      exec-once = mako
      exec-once = wl-paste --watch cliphist store

      input {
        kb_layout = us
        kb_options = ctrl:nocaps
        follow_mouse = 1
        touchpad {
          natural_scroll = true
          tap-to-click = true
        }
      }

      general {
        gaps_in = 5
        gaps_out = 16
        border_size = 2
        layout = dwindle
      }

      decoration {
        rounding = 12
        shadow {
          enabled = true
          range = 8
          render_power = 3
        }
        blur {
          enabled = true
          size = 3
          passes = 1
        }
      }

      animations {
        enabled = true
        bezier = easeOutQuint,0.23,1,0.32,1
        animation = windows,1,4,easeOutQuint
        animation = border,1,6,default
        animation = fade,1,4,default
        animation = workspaces,1,4,easeOutQuint
      }

      dwindle {
        pseudotile = true
        preserve_split = true
      }

      misc {
        disable_hyprland_logo = true
        force_default_wallpaper = 0
      }

      bind = $mod, Return, exec, $terminal
      bind = $mod, Space, exec, $launcher
      bind = $mod SHIFT, X, exec, keepassxc
      bind = CTRL ALT, Return, exec, $browser
      bind = $mod SHIFT, Space, exec, $fileManager
      bind = $mod, Q, killactive,
      bind = ALT, F4, killactive,
      bind = $mod, F, fullscreen,
      bind = $mod, D, togglefloating,
      bind = $mod, G, togglegroup,
      bind = $mod SHIFT, G, changegroupactive, f
      bind = $mod, Tab, workspace, previous
      bind = CTRL ALT, BackSpace, exec, hyprlock

      bind = $mod, H, movefocus, l
      bind = $mod, J, movefocus, d
      bind = $mod, K, movefocus, u
      bind = $mod, L, movefocus, r
      bind = $mod SHIFT, H, movewindow, l
      bind = $mod SHIFT, J, movewindow, d
      bind = $mod SHIFT, K, movewindow, u
      bind = $mod SHIFT, L, movewindow, r

      bind = $mod, T, workspace, 2
      bind = $mod, B, workspace, 1
      bind = $mod, W, workspace, 4
      bind = $mod, Left, workspace, e-1
      bind = $mod, Right, workspace, e+1
      bind = $mod, Up, workspace, e-1
      bind = $mod, Down, workspace, e+1

      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9
      bind = $mod, 0, workspace, 10
      bind = $mod SHIFT, 1, movetoworkspace, 1
      bind = $mod SHIFT, 2, movetoworkspace, 2
      bind = $mod SHIFT, 3, movetoworkspace, 3
      bind = $mod SHIFT, 4, movetoworkspace, 4
      bind = $mod SHIFT, 5, movetoworkspace, 5
      bind = $mod SHIFT, 6, movetoworkspace, 6
      bind = $mod SHIFT, 7, movetoworkspace, 7
      bind = $mod SHIFT, 8, movetoworkspace, 8
      bind = $mod SHIFT, 9, movetoworkspace, 9
      bind = $mod SHIFT, 0, movetoworkspace, 10

      bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
      bind = SHIFT, Print, exec, grim - | wl-copy

      bindel = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
      bindel = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
      bindl = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle

      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow
    '';
  };

  "${xdg_configHome}/hypr/hyprlock.conf" = {
    text = ''
      background {
        color = rgb(1f1f1f)
      }

      input-field {
        size = 320, 64
        position = 0, -20
        halign = center
        valign = center
        outline_thickness = 2
        outer_color = rgb(546e7a)
        inner_color = rgb(1f1f1f)
        font_color = rgb(ffffff)
        placeholder_text = Password
      }
    '';
  };

  "${xdg_configHome}/hypr/hypridle.conf" = {
    text = ''
      general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
      }

      listener {
        timeout = 600
        on-timeout = loginctl lock-session
      }
    '';
  };

  "${xdg_configHome}/mako/config" = {
    text = ''
      font=Noto Sans 10
      width=320
      height=400
      margin=33,65
      padding=32
      border-size=0
      background-color=#1f1f1fee
      text-color=#ffffffff
      default-timeout=5000
    '';
  };
}
// (
  if isVm then
    {
      "${xdg_configHome}/hyprpanel/config.json" = {
        text = ''
          ${vmHyprpanelConfig}
        '';
      };
    }
  else
    { }
)
