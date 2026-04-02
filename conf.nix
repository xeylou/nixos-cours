{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  networking.hostName = "nixos-alexis";

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

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  users.mutableUsers = true;
  users.users = lib.genAttrs [ "pierre" "paul" "jacques" ] (name: {
    isNormalUser = true;
    description = name;
    extraGroups = [ "networkmanager" "wheel" "users" ];
    initialPassword = name;
  });

  programs.firefox.enable = false;
  programs.mtr.enable = true; # suid to run non-root
  nixpkgs.config.allowUnfree = true;
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
  # add flathub repository + install flatpak apps via systemd service
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

  # gnome dconf settings for users
  # le profil "user" s'applique comme valeurs par defaut pour les utilisateurs
  # sans locks, les utilisateurs peuvent modifier les valeurs via leur config locale
  # (~/.config/dconf/user), qui a priorite sur les valeurs system
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

          # show seconds in the clock + set cursor theme
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

  system.stateVersion = "25.11";

}
