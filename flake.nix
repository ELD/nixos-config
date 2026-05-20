{
  description = "Starter Configuration with secrets for MacOS and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
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
    secrets = {
      url = "git+ssh://git@github.com/ELD/nix-secrets.git";
      flake = false;
    };
    sigmavim = {
      url = "git+ssh://git@github.com/ELD/sigmavim.git";
      flake = false;
    };
    ghostty-shaders = {
      url = "github:hackr-sh/ghostty-shaders";
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
      sops-nix,
      secrets,
      sigmavim,
      ghostty-shaders,
      flake-utils,
      neovim-nightly-overlay,
      zig,
      llm-agents,
    }@inputs:
    let
      inherit (flake-utils.lib) eachSystemMap;
      user = "edattore";
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      darwinSystems = [
        "aarch64-darwin"
      ];
      defaultSystems = linuxSystems ++ darwinSystems;
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
            exec ${self}/apps/${system}/${scriptName} $@
          '')
        }/bin/${scriptName}";
      };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
        "rollback" = mkApp "rollback" system;
      };
      mkChecks =
        {
          arch,
          os,
          hostname,
          username ? user,
        }:
        {
          "${arch}-${os}" = {
            "${hostname}" =
              (if os == "darwin" then self.darwinConfigurations else self.nixosConfigurations)
              ."${hostname}@${arch}-${os}".config.system.build.toplevel;
            "${username}-home" = self.homeConfigurations."${username}@${arch}-${os}".activationPackage;
            devShell = self.devShells."${arch}-${os}".default;
          };
        };
      overlays = import ./overlays (inputs // { inherit inputs; });
      isDarwinSystem = system: builtins.elem system darwinSystems;
      homePrefix = system: if isDarwinSystem system then "/Users" else "/home";
      mkHomeConfig =
        {
          system,
          username ? user,
          extraModules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system overlays;
            config = {
              allowUnfree = true;
              allowBroken = true;
              allowInsecure = false;
              allowUnsupportedSystem = true;
              permittedInsecurePackages = [ "olm-3.2.16" ];
            };
          };
          extraSpecialArgs = inputs // {
            inherit inputs;
          };
          modules = [
            ./modules/home-manager
            {
              home = {
                inherit username;
                homeDirectory = "${homePrefix system}/${username}";
              };
            }
          ]
          ++ extraModules;
        };
    in
    {
      devShells = eachSystemMap defaultSystems devShell;
      apps =
        nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      checks =
        { }
        // mkChecks {
          arch = "aarch64";
          os = "darwin";
          hostname = "rhodium";
        }
        // mkChecks {
          arch = "x86_64";
          os = "linux";
          hostname = "indium";
        };

      darwinConfigurations = {
        "rhodium@aarch64-darwin" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = inputs // {
            inherit inputs;
          };
          modules = [
            {
              nixpkgs.overlays = overlays;
            }
            ./modules/shared
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                inherit user;
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
            ./hosts/darwin
          ];
        };
        "eric.dattore-mac@aarch64-darwin" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = inputs // {
            inherit inputs;
          };
          modules = [
            {
              nixpkgs.overlays = overlays;
            }
            ./modules/shared
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                inherit user;
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
            ./hosts/darwin
            # ./hosts/profiles/work
          ];
        };
      };

      nixosConfigurations = {
        "indium@x86_64-linux" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // {
            inherit inputs;
          };
          modules = [
            {
              nixpkgs.overlays = overlays;
            }
            ./modules/shared
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./modules/nixos/home-manager.nix;
              };
            }
            ./hosts/nixos
          ];
        };
      };

      homeConfigurations = {
        "${user}@aarch64-darwin" = mkHomeConfig {
          system = "aarch64-darwin";
        };
        "${user}@x86_64-linux" = mkHomeConfig {
          system = "x86_64-linux";
        };
      };
    };
}
