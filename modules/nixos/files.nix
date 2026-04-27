{
  profile ? "full",
  ...
}:

let
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
