# edit this configuration file to define what should be installed on
# your system. help is available in the configuration.nix(5) man page
# and in the nixos manual (accessible by running 'nixos-help').

{ config, pkgs, lib, ... }:

{
  imports =
    [ # include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  # use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # define your hostname
  # networking.wireless.enable = true;  # enables wireless support via wpa_supplicant

  # configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # static network configuration
  networking.useDHCP = false;
  networking.interfaces.ens18 = {
    ipv4.addresses = [{
      address = "159.31.247.228";
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = "159.31.247.1";
  networking.nameservers = [ "8.8.8.8" ];

  # set your time zone
  time.timeZone = "Europe/Paris";

  # select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # enable the x11 windowing system
  services.xserver.enable = true;

  # enable the gnome desktop environment
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # configure keymap in x11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # configure console keymap
  console.keyMap = "fr";

  # enable cups to print documents
  services.printing.enable = true;

  # enable sound with pipewire and jack support
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # enable touchpad support (enabled default in most desktopmanager)
  # services.xserver.libinput.enable = true;

  # define user accounts
  users.users.xeylou = {
    isNormalUser = true;
    description = "xeylou";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  users.users.pierre = {
    isNormalUser = true;
    description = "pierre";
    extraGroups = [ "users" ];
  };

  users.users.paul = {
    isNormalUser = true;
    description = "paul";
    extraGroups = [ "users" ];
  };

  users.users.jacques = {
    isNormalUser = true;
    description = "jacques";
    extraGroups = [ "users" ];
  };

  # install firefox
  programs.firefox.enable = true;

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # list packages installed in system profile
  environment.systemPackages = with pkgs; [
    vim
    amberol
    wget
    mtr
    dtools
    htop
    gnome-tweaks
    kdePackages.breeze
    openssh
    # gnome extensions
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.burn-my-windows
    gnomeExtensions.tiling-shell
  ];

  # enable flatpak
  services.flatpak.enable = true;

  # add flathub repository and install flatpak apps via systemd service
  systemd.services.flatpak-setup = {
    description = "setup flatpak and install applications";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      ${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub com.mattjakeman.ExtensionManager || true
      ${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub com.brave.Browser || true
    '';
  };

  # gnome dconf settings for all users
  # le profil "user" s'applique comme valeurs par defaut pour tous les utilisateurs.
  # sans locks, les utilisateurs peuvent modifier ces valeurs via leur config locale
  # (~/.config/dconf/user), qui a priorite sur les valeurs systeme.
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          # enable gnome extensions
          "org/gnome/shell" = {
            enabled-extensions = [
              "appindicatorsupport@rgcjonas.gmail.com"
              "dash-to-dock@micxgx.gmail.com"
              "burn-my-windows@schneegans.github.com"
              "tiling-shell@ferrarodomenico.com"
            ];
          };

          # show seconds in the clock and set cursor theme
          "org/gnome/desktop/interface" = {
            clock-show-seconds = true;
            cursor-theme = "Breeze_Light";
          };

        };
        # note: burn-my-windows v47 utilise des fichiers de profil, pas dconf.
        # les profils sont crees via system.activationScripts.configureBurnMyWindows
      }
    ];
  };

  # enable openssh daemon
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # firewall configuration with nftables
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  # enable zram swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # configure burn-my-windows profiles on rebuild
  # l'extension v47 utilise des fichiers de profil, pas dconf pour les effets
  system.activationScripts.configureBurnMyWindows = lib.stringAfter [ "users" ] ''
    for user in xeylou pierre paul jacques; do
      BMW_DIR="/home/$user/.config/burn-my-windows/profiles"
      rm -rf /home/$user/.config/burn-my-windows
      mkdir -p "$BMW_DIR"

      # profil ouverture: energize-a, portal, hexagon
      cat > "$BMW_DIR/1000000000000001.conf" << 'PROFILE_OPEN'
[burn-my-windows-profile]
profile-animation-type=1
energize-a-enable-effect=true
portal-enable-effect=true
hexagon-enable-effect=true
fire-enable-effect=false
PROFILE_OPEN

      # profil fermeture: broken-glass, incinerate
      cat > "$BMW_DIR/1000000000000002.conf" << 'PROFILE_CLOSE'
[burn-my-windows-profile]
profile-animation-type=2
broken-glass-enable-effect=true
incinerate-enable-effect=true
fire-enable-effect=false
PROFILE_CLOSE

      chown -R $user:users /home/$user/.config/burn-my-windows
    done
  '';


  # some programs need suid wrappers, can be configured further or are
  # started in user sessions
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # this value determines the nixos release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. it's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # did you read the comment?

}
