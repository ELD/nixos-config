{ config, pkgs, lib, home-manager, ... }:

let
  user = "edattore";
  # Define the content of your file as a derivation
  myEmacsLauncher = pkgs.writeScript "emacs-launcher.command" ''
    #!/bin/sh
    emacsclient -c -n &
  '';
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
   ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
    };

    taps = [];

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)

    masApps = {
      "1Blocker" = 1365531024;
      "1Password for Safari" = 1569813296;
      "Cardhop" = 1290358394;
      "Fantastical" = 975937182;
      "Pile" = 1549454338;
      "Pixelmator Pro" = 1289583905;
      "Slack" = 803453959;
      "Things 3" = 904280696;

      "Pages" = 409201541;
      "Keynote" = 409203825;
      "Numbers" = 409183694;

      "MainStage 3" = 634159523;
      "Logic Pro X" = 634148309;

      "Final Cut Pro" = 424389933;

      "iA Writer" = 775737590;
      "MindNode" = 1289197285;
      "UlyssesMac" = 1225570693;

      "Xcode" = 497799835;

      "Day Progress" = 6450280202;
      # "Structured" = 1499198946;

      "TestFlight" = 899247664;

      "Flighty" = 1358823008;
      "Kindle" = 302584613;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        file = lib.mkMerge [
          sharedFiles
          additionalFiles
          { "emacs-launcher.command".source = myEmacsLauncher; }
        ];

        stateVersion = "23.11";
      };
      programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = false;
      entries = [
        { path = "/Applications/Slack.app/"; }
        { path = "/System/Applications/Messages.app/"; }
        { path = "/System/Applications/Facetime.app/"; }
        { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
        { path = "/System/Applications/Music.app/"; }
        { path = "/System/Applications/News.app/"; }
        { path = "/System/Applications/Photos.app/"; }
        { path = "/System/Applications/Photo Booth.app/"; }
        { path = "/System/Applications/TV.app/"; }
        { path = "/System/Applications/Home.app/"; }
        {
          path = toString myEmacsLauncher;
          section = "others";
        }
        {
          path = "${config.users.users.${user}.home}/.local/share/";
          section = "others";
          options = "--sort name --view grid --display folder";
        }
        {
          path = "${config.users.users.${user}.home}/.local/share/downloads";
          section = "others";
          options = "--sort name --view grid --display stack";
        }
      ];
    };
  };
}
