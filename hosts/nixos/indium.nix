{
  config,
  inputs,
  lib,
  pkgs,
  my-fonts,
  sops-nix,
  ...
}:

let
  user = "edattore";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];
in
{
  imports = [
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/power.nix
    # ../../modules/nixos/disk-config.nix
    sops-nix.nixosModules.sops
  ];


  # pasted from /etc/nixos/hardware-configuration.nix
  fileSystems."/" =
    { device = "/dev/mapper/luks-49933748-7ffc-4a90-a08d-33753dceec1a";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-49933748-7ffc-4a90-a08d-33753dceec1a" = {
    device = "/dev/disk/by-uuid/49933748-7ffc-4a90-a08d-33753dceec1a";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/EA24-31A9";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 40 * 1024;
    }
  ];

  # Lanzaboote replaces systemd-boot to support UEFI Secure Boot.
  boot = {
    resumeDevice = "/dev/mapper/luks-49933748-7ffc-4a90-a08d-33753dceec1a";
    kernelParams = [ "resume_offset=116439040" ];

    loader = {
      systemd-boot = {
        enable = lib.mkForce false;
        configurationLimit = 42;
      };
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    initrd.systemd.enable = true;
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "thunderbolt"
    ];
    # Uncomment for AMD GPU
    # initrd.kernelModules = [ "amdgpu" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "uinput" "kvm-intel" ];
  };

  # Set your time zone.
  time.timeZone = "America/Denver";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking = {
    hostName = "Indium"; # Define your hostname.
    wireless.enable = true;
    wireless.extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
    networkmanager.enable = true;
  };

  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nixos-config:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [
        "@admin"
        "${user}"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Manages keys and such
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Needed for anything GTK related
    dconf.enable = true;

    # My shell
    zsh.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  services = {
    fwupd.enable = true;
    upower.enable = true;
    pcscd.enable = true;

    udev.packages = [ pkgs.brightnessctl ];

    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "suspend";
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
          user = "greeter";
        };
      };
    };

    # Let's be able to SSH into this machine
    openssh.enable = true;

    # Sync state between machines
    # Sync state between machines
    syncthing = {
      enable = true;
      openDefaultPorts = true;
      dataDir = "/home/${user}/.local/share/syncthing";
      configDir = "/home/${user}/.config/syncthing";
      user = "${user}";
      group = "users";
      guiAddress = "127.0.0.1:8384";
      overrideFolders = true;
      overrideDevices = true;

      settings = {
        devices = { };
        options.globalAnnounceEnabled = false; # Only sync on LAN
      };
    };

    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
  };

  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";

  # Enable CUPS to print documents
  # services.printing.enable = true;
  # services.printing.drivers = [ pkgs.brlaser ]; # Brother printer driver

  hardware.enableRedistributableFirmware = true;

  # Enable sound
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.services = {
    hyprlock.fprintAuth = true;
    sudo.fprintAuth = true;
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Video support
  hardware = {
    graphics.enable = true;
    # nvidia.modesetting.enable = true;

    # Enable Xbox support
    # xone.enable = true;

    # Crypto wallet support
    ledger.enable = true;
  };

  # Add docker daemon
  virtualisation.docker.enable = true;
  virtualisation.docker.logDriver = "json-file";

  # It's me, it's you, it's everyone
  users.users = {
    ${user} = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
        "docker"
        "video"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
    };

    root = {
      openssh.authorizedKeys.keys = keys;
    };
  };

  # Don't require password for users in `wheel` group for these commands
  security.sudo = {
    enable = true;
    extraRules = [
      {
        commands = [
          {
            command = "${pkgs.systemd}/bin/reboot";
            options = [ "NOPASSWD" ];
          }
        ];
        groups = [ "wheel" ];
      }
    ];
  };
  security.tpm2.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
    font-awesome

    my-fonts.packages.${pkgs.stdenv.hostPlatform.system}.tx02
  ];

  environment.systemPackages = with pkgs; [
    sops
    gitFull
    inetutils
    sbctl
    tpm2-tools
  ];

  system.stateVersion = "25.11"; # Don't change this
}
