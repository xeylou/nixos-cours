{ config, pkgs, lib, ... }:

let
  userList = [ "pierre" "paul" "jacques" ];

  bmwOpenProfile = ''
    [burn-my-windows-profile]
    profile-animation-type=1
    energize-a-enable-effect=true
    portal-enable-effect=true
    hexagon-enable-effect=true
    fire-enable-effect=false
  '';

  bmwCloseProfile = ''
    [burn-my-windows-profile]
    profile-animation-type=2
    broken-glass-enable-effect=true
    incinerate-enable-effect=true
    fire-enable-effect=false
  '';
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  networking.hostName = "nixos-alexis";
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  # pas besoin de extraLocaleSettings si toutes les LC_* = defaultLocale
  console.keyMap = "fr";

  services.xserver = {
    enable = true;
    xkb.layout = "fr";
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.printing.enable = false;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };

  users.users = lib.genAttrs userList (name: {
    isNormalUser = true;
    description = name;
    extraGroups = [ "networkmanager" "wheel" "users" ];
    initialPassword = name;
  });

  nixpkgs.config.allowUnfree = true;

  programs = {
    firefox.enable = false;
    mtr.enable = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    dtools

    # gnome
    amberol
    gnome-tweaks
    gnome-extension-manager
    kdePackages.breeze
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.burn-my-windows
    gnomeExtensions.tiling-shell

    # brave en natif (remplace le flatpak)
    brave
  ];

  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/shell" = {
            enabled-extensions = [
              "appindicatorsupport@rgcjonas.gmail.com"
              "dash-to-dock@micxgx.gmail.com"
              "burn-my-windows@schneegans.github.com"
              "tilingshell@ferrarodomenico.com"
            ];
          };
          "org/gnome/desktop/interface" = {
            clock-show-seconds = true;
            cursor-theme = "Breeze_Light";
          };
        };
      }
    ];
  };

  system.activationScripts.configureBurnMyWindows = lib.stringAfter [ "users" ] ''
    for user in ${lib.concatStringsSep " " userList}; do
      BMW_DIR="/home/$user/.config/burn-my-windows/profiles"
      rm -rf "/home/$user/.config/burn-my-windows"
      mkdir -p "$BMW_DIR"

      cat > "$BMW_DIR/open.conf" << 'EOF'
    ${bmwOpenProfile}
    EOF

      cat > "$BMW_DIR/close.conf" << 'EOF'
    ${bmwCloseProfile}
    EOF

      chown -R "$user:users" "/home/$user/.config/burn-my-windows"
    done
  '';

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  system.stateVersion = "25.11";
}
