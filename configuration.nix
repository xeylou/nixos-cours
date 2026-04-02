{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-alexis";

  networking.useDHCP = false;
  networking.interfaces.ens18 = {
    ipv4.addresses = [{
      address = "159.31.247.228";
      prefixLength = 24;
    }];
  };

  networking.defaultGateway = "159.31.247.1";
  networking.nameservers = [ "8.8.8.8" ];

  time.timeZone = "Europe/Paris";
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

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };
  console.keyMap = "fr";

  services.printing.enable = false;

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

  users.users.pierre = {
    isNormalUser = true;
    description = "pierre";
    extraGroups = [ "users" ];
    initialPassword = "pierre";
  };

  users.users.paul = {
    isNormalUser = true;
    description = "paul";
    extraGroups = [ "users" ];
    initialPassword = "paul";
  };

  users.users.jacques = {
    isNormalUser = true;
    description = "jacques";
    extraGroups = [ "users" ];
    initialPassword = "jacques";
  };

  programs.firefox.enable = false;

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    amberol
    vim
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

  services.flatpak.enable = true;
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

  # le profil "user" s'applique comme valeurs par defaut pour tous les utilisateurs
  # sans locks les utilisateurs peuvent modifier ces valeurs via leur config locale
  # (~/.config/dconf/user), qui a priorite sur les valeurs systeme
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
              "tilingshell@ferrarodomenico.com"
            ];
          };

          # show seconds in the clock and set cursor theme
          "org/gnome/desktop/interface" = {
            clock-show-seconds = true;
            cursor-theme = "Breeze_Light";
          };

        };
        # burn-my-windows v47 utilise des fichiers de profil, pas dconf
        # profils crees via system.activationScripts.configureBurnMyWindows
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

  # firewall configuration nftables
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
  # l'extension v47 utilise des fichiers de profil, pas dconf
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
  programs.mtr.enable = true; # raw sockets without sudo + install it (redondance d'en haut...)
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
