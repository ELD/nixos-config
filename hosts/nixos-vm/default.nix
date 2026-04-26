{ pkgs, ... }:

let
  user = "edattore";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];
in
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = false;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "virtio_blk"
      "virtio_gpu"
      "virtio_net"
      "usbhid"
      "sd_mod"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "uinput" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8180b195-82d1-4246-9a41-6413dd224ed2";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6B9C-3345";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  time.timeZone = "America/New_York";

  networking = {
    hostName = "nixos-vm";
    useDHCP = true;
  };

  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nixos-config:/etc/nixos" ];
    settings = {
      allowed-users = [ user ];
      trusted-users = [
        "@admin"
        user
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

  programs = {
    gnupg.agent.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    dconf.enable = true;
    zsh.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    LIBGL_ALWAYS_SOFTWARE = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  services = {
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
        user = "greeter";
      };
    };
    openssh.enable = true;
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.services.hyprlock = { };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  hardware.graphics.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;

  users.users = {
    ${user} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "input"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
    };
    root.openssh.authorizedKeys.keys = keys;
  };

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

  fonts.packages = with pkgs; [
    jetbrains-mono
    font-awesome
  ];

  environment.systemPackages = with pkgs; [
    gitFull
    inetutils
    sops
  ];

  system.stateVersion = "25.11";
}
