# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use GRUB2 as EFI boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.blacklistedKernelModules = [ "nouveau" ];

  # Encrypted drive to be mounted by the bootloader. Path of the device will
  # have to be changed for each install.
  boot.initrd.luks.devices = {
    root = {
      # Get UUID from blkid /dev/sda2
      device = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
      preLVM = true;
      allowDiscards = true;
    };
  };

  # /tmp is cleaned after each reboot
  boot.cleanTmpDir = true;

  # Users allowed to run nix
  nix.allowedUsers = [ "root" "pinpox" ];

  networking = {

    # Define the hostname
    hostName = "kartoffel";

    # Defile the DNS servers
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "192.168.2.1"
    ];

    # Enables wireless support via wpa_supplicant.
    # networking.wireless.enable = true;

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    # useDHCP = false;
    # interfaces.eno1.useDHCP = true;

    # Enable networkmanager
    networkmanager.enable = true;

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Additional hosts to put in /etc/hosts
    extraHosts = ''
      94.16.114.42 nix.own
      94.16.114.42 lislon.nix.own
      192.168.2.84 backup-server
      192.168.2.84 cloud.pablo.tools

      10.10.10.212 bucket.htb
      10.10.10.212 s3.bucket.htb
    '';
  };

  # Set localization properties and timezone
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "colemak";
  };

  time.timeZone = "Europe/Berlin";

  # System-wide environment variables to be set
  environment = {
    variables = {
      EDITOR = "nvim";
      GOPATH = "~/.go";
      VISUAL = "nvim";
      # Use librsvg's gdk-pixbuf loader cache file as it enables gdk-pixbuf to load
      # SVG files (important for icons)
      GDK_PIXBUF_MODULE_FILE =
        "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)";
    };

    # Needed for yubikey to work
    shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
  };

  # Needed for zsh completion of system packages, e.g. systemd
  environment.pathsToLink = [ "/share/zsh" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    qemu
    python
    ctags
    openvpn
    ruby
    python
    borgbackup
    go
    ripgrep
    nodejs
    killall
    arandr
    wget
    neovim
    git
    zsh
    gnumake
    nixfmt
  ];

  programs.dconf.enable = true;

  programs.chromium = {
    enable = true;
    extraOpts = {
      # "BrowserSignin" = 0;
      # "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [ "de" "en-US" ];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gtk2";
    # extraConfig = ''
    #        pinentry-program ${pkgs.pinentry.gnome3}/bin/pinentry-gnome3
    #      '';
  };

  programs.zsh = {
    enable = true;
    shellAliases = { vim = "nvim"; };
    enableCompletion = true;
    autosuggestions.enable = true;
  };

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
  };

  virtualisation.docker.enable = true;

  # Virtualbox stuff
  #virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    startWhenNeeded = true;
    challengeResponseAuthentication = false;
  };

  # Enable Wireguard
  networking.wireguard.interfaces = {

    wg0 = {

      # Determines the IP address and subnet of the client's end of the
      # tunnel interface.
      ips = [ "192.168.7.2/24" ];

      # Path to the private key file
      privateKeyFile = "/secrets/wireguard/privatekey";
      peers = [{
        # Public key of the server (not a file path).
        publicKey = "XKqEk5Hsp3SRVPrhWD2eLFTVEYb9NYRky6AermPG8hU=";

        # Don't forward all the traffic via VPN, only particular subnets
        allowedIPs = [ "192.168.7.0/24" ];

        # Server IP and port.
        endpoint = "vpn.pablo.tools:51820";

        # Send keepalives every 25 seconds. Important to keep NAT tables
        # alive.
        persistentKeepalive = 25;
      }];
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
  };

  hardware.bluetooth = {
    enable = true;
    # config = "
    #   [General]
    #   Enable=Source,Sink,Media,Socket
    # ";
  };

  services.blueman.enable = true;



  # Enable the X11 windowing system.
  services.xserver = {
    videoDrivers = [ "nvidia" ];
    enable = true;
    autorun = true;
    layout = "us";
    dpi = 125;
    xkbVariant = "colemak";
    xkbOptions = "caps:escape";

    libinput = {
      enable = true;
      accelProfile = "flat";
    };

    config = ''
      Section "InputClass"
        Identifier "mouse accel"
        Driver "libinput"
        MatchIsPointer "on"
        Option "AccelProfile" "flat"
        Option "AccelSpeed" "0"
      EndSection
    '';

    desktopManager = {
      xterm.enable = false;
      session = [{
        name = "home-manager";
        start = ''
          ${pkgs.runtimeShell} $HOME/.hm-xsession &
           waitPID=$!
        '';
      }];
    };

    displayManager = { startx.enable = true; };
  };

  nixpkgs = { config.allowUnfree = true; };

  # Backup with borgbackup to remote server. The connection key and repository
  # encryption passphrase is read from /secrets. This directory has to be
  # copied ther *manually* (so this config can be shared publicly)!
  services.borgbackup.jobs.home = {

    # Paths to backup, home should be enough for now, since system-wide
    # configuration is generated by nixOS
    paths = "/home";

    # Remote servers repository to use. Archives will be labeled with the
    # hostname and a timestamp
    repo =
      "ssh://borg@backup-server//mnt/backup/borgbackup/${config.networking.hostName}";

    # Don't create repo if it does not exist. Ensures the backup fails, if for
    # some reason the backup drive is not mounted or the path has changed.
    doInit = false;

    # Encryption and connection keys are read from /secrets
    encryption = {
      mode = "repokey";
      passCommand = "cat /secrets/borg/repo-passphrase";
    };
    environment.BORG_RSH = "ssh -i /secrets/ssh/backup-key";

    # Print more infomation to log and set intervals at which resumable
    # checkpoints are created
    extraCreateArgs = "--verbose --list --checkpoint-interval 600";

    # Exclude some directories from backup that contain garbage
    exclude = [
      "*.pyc"
      "*/cache2"
      "/*/.cache"
      "/*/.config/Signal"
      "/*/.config/chromium"
      "/*/.config/discord"
      "/*/.container-diff"
      "/*/.gvfs/"
      "/*/.local/share/Trash"
      "/*/.mozilla/firefox/*.default/Cache"
      "/*/.mozilla/firefox/*.default/OfflineCache"
      "/*/.npm/_cacache"
      "/*/.thumbnails"
      "/*/.ts3client"
      "/*/.vagrant.d"
      "/*/.vim"
      "/*/Cache"
      "/*/Downloads"
      "/*/VirtualBox VMs"
      "discord/Cache"
    ];

    compression = "lz4";

    # Backup will run daily
    startAt = "daily";
  };

  # Install some fonts system-wide, especially "Source Code Pro" in the
  # Nerd-Fonts pached version with extra glyphs.
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
      noto-fonts-emoji
      corefonts
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {

    # For Virtualbox
    # extraGroups = {
    #   vboxusers.members = ["pinpox"];
    # };

    # Shell is set to zsh for all users as default.
    defaultUserShell = pkgs.zsh;

    users.pinpox = {
      isNormalUser = true;
      home = "/home/pinpox";
      description = "Pablo Ovelleiro Corral";
      extraGroups = [ "docker" "wheel" "networkmanager" "audio" "libvirtd" "dialout"];
      shell = pkgs.zsh;

      # Public ssh-keys that are authorized for the user. Fetched from homepage
      # and github profile.
      openssh.authorizedKeys.keyFiles = [
        (builtins.fetchurl { url = "https://pablo.tools/ssh-key"; })
        (builtins.fetchurl { url = "https://github.com/pinpox.keys"; })
      ];
    };
  };

  # Clean up old generations after 30 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}

