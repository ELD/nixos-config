{ config, pkgs, lib, home-manager, ... }:

let
  user = "edattore";
  # Define the content of your file as a derivation
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
  mkFullPathRelativeToNixpkgs = homeDirectory: relative: "${homeDirectory}/.nixos-config/${relative}";
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
    # brews = [ "opencode" ];
    casks = pkgs.callPackage ./casks.nix {};
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
    };

    taps = builtins.attrNames config.nix-homebrew.taps;

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
      # Utilities
      "1Blocker" = 1365531024;
      "1Password for Safari" = 1569813296;
      "Cardhop" = 1290358394;
      "Flighty" = 1358823008;
      "one sec" = 1532875441;
      "Pile" = 1549454338;
      "StopTheMadness Pro" = 6471380298;
      "Tailscale" = 1475387142;
      "TestFlight" = 899247664;

      # Code
      "Xcode" = 497799835;

      # Writing
      "iA Writer" = 775737590;
      "Ulysses" = 1225570693;

      # Creative
      "Compressor" = 6746516157;
      "Final Cut Pro" = 1631624924;
      "GarageBand" = 682658836;
      "Kindle" = 302584613;
      "Logic Pro" = 1615087040;
      "MainStage" = 6746637089;
      "Motion" = 6746637149;
      "Pixelmator Pro" = 6746662575;

      # Games
      "Balatro" = 6502451661;
      "CivilizationVII" = 6744373452;

      # Productivity
      "Fantastical" = 975937182;
      "Keynote" = 361285480;
      "Numbers" = 361304891;
      "Pages" = 361309726;
      "Slack" = 803453959;
      # "Structured" = 0;
      "Things" = 904280696;
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
        ];

        sessionPath = [
          "/Users/${user}/.cargo/bin"
        ];

        stateVersion = "25.11";
      };
      programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;

      xdg.configFile =
      {
        nvim = {
          source =
            config.lib.file.mkOutOfStoreSymlink (mkFullPathRelativeToNixpkgs "/Users/${user}"
              "modules/shared/config/sigmavim");
          recursive = true;
        };
        ghostty = {
          source =
            config.lib.file.mkOutOfStoreSymlink (mkFullPathRelativeToNixpkgs "/Users/${user}"
              "modules/shared/config/ghostty");
          recursive = true;
        };
        "starship.toml" = {
          source = ../shared/config/starship.toml;
        };
      };
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/System/Applications/Apps.app"; }
        { path = "/Applications/Ghostty.app"; }
        { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
        { path = "/System/Applications/Messages.app"; }
        { path = "/System/Applications/Mail.app"; }
        { path = "/Applications/UlyssesMac.app"; }
        { path = "/Applications/Obsidian.app"; }
        { path = "/Applications/Things3.app"; }
        { path = "/Applications/Structured.app"; }
        { path = "/Applications/Slack.app/"; }
        { path = "/Applications/Discord.app"; }
        { path = "/Applications/Fantastical.app"; }
        { path = "/System/Applications/Music.app"; }
      ];
    };
  };
}
