{
  description = "Host and profile configurations for macOS and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Empty by default. Supply only the appropriate repository at build time with
    # --override-input personal-secrets (or work-secrets). Never lock private URLs.
    personal-secrets = {
      url = "path:./secrets/empty";
      flake = false;
    };
    work-secrets = {
      url = "path:./secrets/empty";
      flake = false;
    };
    ghostty-shaders = {
      url = "github:hackr-sh/ghostty-shaders";
      flake = false;
    };
    # Publish Azithro, then run `nix flake update azithro` to pin its revision.
    azithro = {
      url = "github:ELD/azithro";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig = {
      url = "github:mitchellh/zig-overlay";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
  };
  outputs =
    {
      self,
      darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      home-manager,
      nixpkgs,
      disko,
      flake-utils,
      ...
    }@inputs:
    let
      inherit (flake-utils.lib) eachSystemMap;
      inherit (nixpkgs) lib;
      inventory = builtins.fromTOML (builtins.readFile ./hosts/inventory.toml);
      profileModules = {
        personal = {
          darwin = [ ./modules/profiles/darwin/personal.nix ];
          nixos = [ ];
          home = [ ./modules/profiles/home/personal-tools.nix ];
        };
        desktop = {
          darwin = [ ];
          nixos = [ ];
          home = [ ./modules/profiles/home/personal-tools.nix ];
        };
        work = {
          darwin = [ ./modules/profiles/darwin/work.nix ];
          nixos = [ ];
          home = [ ./modules/profiles/home/work.nix ];
        };
        development = {
          darwin = [ ];
          nixos = [ ];
          home = [ ./modules/profiles/home/development.nix ];
        };
      };
      # Host hardware and machine-specific policy belong in Nix, not TOML.
      hostModules = {
        rhodium = [ ./hosts/darwin/rhodium.nix ];
        indium = [ ./hosts/nixos/indium.nix ];
      };
      hosts = lib.mapAttrs (
        key: entry:
        let
          valid =
            entry ? platform
            && entry ? system
            && entry ? username
            && entry ? hostname
            && entry ? homeDirectory
            && entry ? stateVersion
            && entry ? profiles;
          user =
            if valid then inventory.users.${entry.username} or (throw "Unknown user on host ${key}") else { };
          supported =
            valid
            && (
              (entry.platform == "darwin" && entry.system == "aarch64-darwin")
              || (entry.platform == "nixos" && entry.system == "x86_64-linux")
            );
          knownProfiles =
            valid
            && builtins.isList entry.profiles
            && lib.all (profile: builtins.hasAttr profile profileModules) entry.profiles;
          secrets = entry.secrets or null;
          validSecrets =
            secrets == null
            || (
              secrets ? repo
              && secrets ? file
              && lib.elem secrets.repo [
                "personal"
                "work"
              ]
              && lib.elem secrets.repo entry.profiles
              && builtins.isString secrets.file
              && !(lib.hasPrefix "/" secrets.file)
              && !(lib.elem ".." (lib.splitString "/" secrets.file))
              && builtins.pathExists "${inputs."${secrets.repo}-secrets"}/${secrets.file}"
            );
        in
        assert lib.assertMsg valid
          "Host ${key} needs platform, system, username, hostname, homeDirectory, stateVersion and profiles";
        assert lib.assertMsg supported "Host ${key} has an unsupported platform/system combination";
        assert lib.assertMsg knownProfiles "Host ${key} names an unknown profile";
        assert lib.assertMsg (
          !(lib.elem "work" entry.profiles) || entry ? email
        ) "Work host ${key} needs its own email (do not inherit the personal Git identity)";
        assert lib.assertMsg validSecrets
          "Host ${key} needs a valid secrets repo/file and an overridden input containing that file";
        assert lib.assertMsg (
          entry.platform != "nixos" || builtins.hasAttr key hostModules
        ) "NixOS host ${key} needs a machine-specific Nix module in hostModules";
        user
        // entry
        // {
          inherit key;
        }
        // lib.optionalAttrs (secrets != null) {
          secretsFile = "${inputs."${secrets.repo}-secrets"}/${secrets.file}";
        }
      ) inventory.hosts;
      hostNames =
        let
          keys = builtins.attrNames hosts;
          homeOutputNames = lib.concatMap (
            key:
            let
              host = hosts.${key};
            in
            [ "${host.username}@${key}-${host.system}" ]
            ++ lib.optional (host.legacyHome or false) "${host.username}@${host.system}"
            ++ lib.optional (host.editableHome or false) "${host.username}-editable@${host.system}"
          ) keys;
        in
        assert lib.assertMsg
          (builtins.length homeOutputNames == builtins.length (lib.unique homeOutputNames))
          "Inventory creates duplicate Home Manager output names; only one host per user/system can own a legacy or editable alias";
        keys;
      defaultSystems = lib.unique (map (key: hosts.${key}.system) hostNames);
      profileModulesFor =
        kind: host: lib.concatMap (profile: profileModules.${profile}.${kind}) host.profiles;
      devShell =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default =
            with pkgs;
            mkShell {
              nativeBuildInputs = with pkgs; [
                bashInteractive
                git
                age
                sops
                nil
                nixd
              ];
              shellHook = ''
                export EDITOR=vim
              '';
            };
        };
      mkApp = scriptName: system: {
        type = "app";
        meta = {
          description = "Apps for managing this Nix system configuration for system, ${system}";
        };
        program = "${
          (nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
            #!/usr/bin/env bash
            PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
            echo "Running ${scriptName} for ${system}"
            exec ${self}/apps/${system}/${scriptName} "$@"
          '')
        }/bin/${scriptName}";
      };
      mkLinuxApps = system: {
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
      };
      mkDarwinApps = system: {
        "build" = mkApp "build" system;
        "build-hm" = mkApp "build-hm" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
        "rollback" = mkApp "rollback" system;
      };
      mkQualityChecks =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          mkCheck =
            name: tools: command:
            pkgs.runCommand name { nativeBuildInputs = tools; } ''
              cd ${self.outPath}
              ${command}
              touch "$out"
            '';
        in
        {
          nixfmt = mkCheck "check-nixfmt" [ pkgs.nixfmt pkgs.findutils ] ''
            find . -name '*.nix' -print0 | xargs -0 -r nixfmt --check
          '';
          deadnix = mkCheck "check-deadnix" [ pkgs.deadnix ] ''
            deadnix --fail .
          '';
          statix = mkCheck "check-statix" [ pkgs.statix ] ''
            statix check .
          '';
          shellcheck = mkCheck "check-shellcheck" [ pkgs.shellcheck pkgs.findutils ] ''
            find apps -type f -print0 | xargs -0 -r shellcheck --severity=error
          '';
          actionlint = mkCheck "check-actionlint" [ pkgs.actionlint ] ''
            actionlint .github/workflows/*.yml
          '';
        };
      mkChecks =
        system:
        mkQualityChecks system
        // {
          devShell = self.devShells.${system}.default;
        }
        // lib.foldl' (
          checks: key:
          let
            host = hosts.${key};
            output = "${key}@${host.system}";
          in
          if host.system != system then
            checks
          else
            checks
            // {
              "${key}" =
                (if host.platform == "darwin" then self.darwinConfigurations else self.nixosConfigurations)
                .${output}.config.system.build.toplevel;
              "${host.username}-${key}-home" =
                self.homeConfigurations."${host.username}@${key}-${system}".activationPackage;
            }
            // lib.optionalAttrs (host.legacyHome or false) {
              "${host.username}-home" = self.homeConfigurations."${host.username}@${system}".activationPackage;
            }
        ) { } hostNames;
      overlays = import ./overlays (inputs // { inherit inputs; });
      mkHomeConfig =
        host: editable:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit (host) system;
            inherit overlays;
            config = {
              allowUnfree = true;
              allowBroken = true;
              allowInsecure = false;
              allowUnsupportedSystem = true;
              permittedInsecurePackages = [ "olm-3.2.16" ];
            };
          };
          extraSpecialArgs = inputs // {
            inherit inputs host;
          };
          modules = [
            ./modules/home-manager
            {
              home.username = host.username;
              home.homeDirectory = host.homeDirectory;
            }
          ]
          ++ profileModulesFor "home" host
          ++ lib.optionals editable [
            {
              local.editableConfigRoot = "${host.homeDirectory}/.nixos-config";
              programs.azithro.editableConfigPath = "${host.homeDirectory}/.nixos-config/checkouts/azithro";
            }
          ];
        };
      mkDarwin =
        host:
        darwin.lib.darwinSystem {
          inherit (host) system;
          specialArgs = inputs // {
            inherit inputs host;
            homeProfileModules = profileModulesFor "home" host;
          };
          modules = [
            { nixpkgs.overlays = overlays; }
            ./modules/shared
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            ./hosts/darwin
          ]
          ++ (hostModules.${host.key} or [ ])
          ++ lib.optionals (lib.elem "personal" host.profiles) [
            {
              nix-homebrew = {
                user = host.username;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
          ]
          ++ profileModulesFor "darwin" host;
        };
      mkNixos =
        host:
        nixpkgs.lib.nixosSystem {
          inherit (host) system;
          specialArgs = inputs // {
            inherit inputs host;
          };
          modules = [
            { nixpkgs.overlays = overlays; }
            ./modules/shared
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${host.username}.imports = [
                  ./modules/nixos/home-manager.nix
                ]
                ++ profileModulesFor "home" host;
              };
            }
          ]
          ++ hostModules.${host.key}
          ++ profileModulesFor "nixos" host;
        };
    in
    {
      devShells = eachSystemMap defaultSystems devShell;
      formatter = nixpkgs.lib.genAttrs defaultSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
      apps = lib.genAttrs defaultSystems (
        system: if lib.hasSuffix "-darwin" system then mkDarwinApps system else mkLinuxApps system
      );
      checks = lib.genAttrs defaultSystems mkChecks;

      darwinConfigurations = lib.mapAttrs' (
        key: host: lib.nameValuePair "${key}@${host.system}" (mkDarwin host)
      ) (lib.filterAttrs (_: host: host.platform == "darwin") hosts);

      nixosConfigurations = lib.mapAttrs' (
        key: host: lib.nameValuePair "${key}@${host.system}" (mkNixos host)
      ) (lib.filterAttrs (_: host: host.platform == "nixos") hosts);

      homeConfigurations = lib.foldl' (
        acc: key:
        let
          host = hosts.${key};
          config = mkHomeConfig host false;
        in
        acc
        // {
          "${host.username}@${key}-${host.system}" = config;
        }
        // lib.optionalAttrs (host.legacyHome or false) {
          "${host.username}@${host.system}" = config;
        }
        // lib.optionalAttrs (host.editableHome or false) {
          "${host.username}-editable@${host.system}" = mkHomeConfig host true;
        }
      ) { } hostNames;
    };
}
