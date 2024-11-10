{ agenix, config, pkgs, ... }:

let user = "edattore"; in

{

  imports = [
    ../../modules/darwin/secrets.nix
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
     agenix.darwinModules.default
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Setup user, packages, programs
  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };

    gc = {
      user = "root";
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs; [
    agenix.packages."${pkgs.system}".default
  ] ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

  security = {
    pam.enableSudoTouchIdAuth = true;
  };

  system = {
    stateVersion = 4;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
        AppleShowScrollBars = "Automatic";

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 1;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 10;

        "com.apple.mouse.tapBehavior" = null;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 1.0;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 96;
        static-only = false;
        showhidden = false;
        show-process-indicators = true;
        mru-spaces = false;
      };

      finder = {
        _FXShowPosixPathInTitle = true;
        FXEnableExtensionChangeWarning = true;
        AppleShowAllExtensions = true;
      };

      trackpad = {
        Clicking = false;
        TrackpadThreeFingerDrag = true;
        ActuationStrength = 1;
        FirstClickThreshold = 1;
        TrackpadRightClick = true;
      };

      alf = {
        globalstate = 1;
        loggingenabled = 0;
        stealthenabled = 1;
      };
    };
  };
}
