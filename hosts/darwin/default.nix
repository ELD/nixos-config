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
      substituters = [
        "https://nix-community.cachix.org?priority=40"
        "https://cache.nixos.org?priority=41"
        "https://numtide.cachix.org?priority=42"
        "https://edattore-attic-nix-binary-cache.fly.dev/system?priority=43"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "system:9kc0wfN/u1hwyuvVf34YvpWGutSlLpjMeH8ovjOEJm8="
      ];
    };

    gc = {
      user = "root";
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      bash-prompt-prefix = (nix:$name)\040
      always-allow-substitutes = true
      extra-trusted-substituters = https://cache.flakehub.com
      extra-trusted-public-keys = cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio= cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU= cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU= cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8= cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ= cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o= cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y=
      extra-nix-path = nixpkgs=flake:nixpkgs
      upgrade-nix-store-path-url = https://install.determinate.systems/nix-upgrade/stable/universal
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs; [
    agenix.packages."${pkgs.system}".default
    age-plugin-yubikey
  ] ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

  networking = {
    computerName = "Rhodium";
    hostName = "Rhodium";
    localHostName = "Rhodium";
  };

  programs.gnupg = {
    agent.enable = true;
    agent.enableSSHSupport = true;
  };

  security = {
    pam.enableSudoTouchIdAuth = true;
  };

  system = {
    stateVersion = 4;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = false;
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
        tilesize = 80;
        largesize = 96;
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
