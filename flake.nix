{
  description = "Starter Configuration with secrets for MacOS and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
    # home-manager = {
    #   url = "github:aguirre-matteo/home-manager/fix-home-uid";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:Azd325/nix-homebrew";
    };
    # nix-homebrew = {
    #   url = "github:zhaofengli/nix-homebrew";
    # };
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
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/ELD/nix-secrets.git";
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
    my-fonts.url = "git+ssh://git@github.com/ELD/fonts.git";
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
      nixos-hardware,
      lanzaboote,
      sops-nix,
      secrets,
      flake-utils,
      neovim-nightly-overlay,
      zig,
      llm-agents,
      my-fonts,
    }@inputs:
    let
      inherit (flake-utils.lib) eachSystemMap;
      user = "edattore";
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      appLinuxSystems = [
        "x86_64-linux"
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
        }:
        {
          "${arch}-${os}" = {
            "${hostname}" =
              (if os == "darwin" then self.darwinConfigurations else self.nixosConfigurations)
              ."${hostname}@${arch}-${os}".config.system.build.toplevel;
            devShell = self.devShells."${arch}-${os}".default;
          };
        };
      overlays = import ./overlays (inputs // { inherit inputs; });
    in
    {
      devShells = eachSystemMap defaultSystems devShell;
      apps =
        nixpkgs.lib.genAttrs appLinuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
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
        }
        // mkChecks {
          arch = "aarch64";
          os = "linux";
          hostname = "nixos-vm";
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
            nixos-hardware.nixosModules.framework-12th-gen-intel
            lanzaboote.nixosModules.lanzaboote
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  nixosProfile = "full";
                };
                users.${user} = import ./modules/nixos/home-manager.nix;
              };
            }
            ./hosts/nixos/indium.nix
          ];
        };
        "nixos-vm@aarch64-linux" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = inputs // {
            inherit inputs;
          };
          modules = [
            {
              nixpkgs.overlays = overlays;
            }
            ./modules/shared
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  nixosProfile = "vm";
                };
                users.${user} = import ./modules/nixos/home-manager.nix;
              };
            }
            ./hosts/nixos-vm
          ];
        };
      };
    };
}
