# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz") {
    config.allowUnfree = true;
  };
  sops-nix = builtins.fetchTarball {
    url = "https://github.com/Mic92/sops-nix/archive/master.tar.gz";
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/packages.nix
      ./modules/users.nix
      # Home Manager module
      <home-manager/nixos>
      # sops-nix for hemmeligheter
      "${sops-nix}/modules/sops"
    ];

#  nix = {
#    package = pkgs.nixFlakes; # hvis du vil bruke flakes
#    extraOptions = ''
#      experimental-features = nix-command flakes
#    '';
# };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "nb_NO.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Hyprland – siste versjon fra nixpkgs-unstable
  programs.hyprland = {
    enable = true;
    package = unstable.hyprland;
    portalPackage = unstable.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  # Polkit – nødvendig for auth-dialogs i Wayland/Hyprland
  security.polkit.enable = true;

  # Lås opp GNOME Keyring automatisk via PAM ved GDM-innlogging.
  # For at Electron/Wire safeStorage (gnome-libsecret) skal fungere i Hyprland.
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;

  # Bruk Flatpak for skrivebordsapper som fungerer bedre med upstream-runtime.
  services.flatpak.enable = true;

  # Wayland-støtte for Electron/Chromium-apper globalt
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "no";
    variant = "winkeys";
  };

  # Configure console keymap
  console.keyMap = "no";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # sops-nix konfigurasjon
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.age.keyFile = "/home/henrik/.config/age/key.txt";
  sops.age.generateKey = false;

  # Home Manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.henrik = import ./home.nix;
  home-manager.users.root = import ./root.nix;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
