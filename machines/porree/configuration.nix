let
  domain = "nix.own";
  # blog = import ./blog.nix;
in { pkgs, lib, ... }:
with lib; {
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    # ./gitea.nix
  ];

  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    # TODO enable  firewall
    networking.firewall.enable = false;

    boot.growPartition = true;
    boot.kernelParams = [ "console=ttyS0" ];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    programs.ssh.startAgent = false;

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      startWhenNeeded = true;
      challengeResponseAuthentication = false;
    };

    environment.systemPackages = with pkgs; [
      nix-index
      htop
      neovim
      nixfmt
      git
      wget
      gnumake
      ripgrep
      go
      python
      ctags
      # python38Packages.gunicorn
      # python38Packages.flask
      # sourcehut.metasrht # Account management service for the sr.ht network
      # sourcehut.todosrht # Ticket tracking service for the sr.ht network
      # sourcehut.gitsrht       # Git repository hosting service for the sr.ht network
      # sourcehut.hubsrht       # Project hub service for the sr.ht network
      # sourcehut.mansrht       # Wiki service for the sr.ht network
      # sourcehut.buildsrht     # Continuous integration service for the sr.ht network
      # sourcehut.listssrht     # Mailing list service for the sr.ht network
      # sourcehut.pastesrht     # Ad-hoc text file hosting service for the sr.ht network
      # sourcehut.dispatchsrht  # Task dispatcher and service integration tool for the sr.ht network
      # sourcehut.hgsrht        # Mercurial repository hosting service for the sr.ht network
    ];

    # services.redis = {
    #   enable = true;
    #   # requirePassFile  ="/secrets/redis/password"
    # };

    # services.postgresql = {
    #   # TODO run metasrht-initdb when needed
    #   # enableTCPIP = true;
    #   enable = true;
    #   # dataDir = "/data/postgresql";
    #   package = pkgs.postgresql_11;
    #   identMap = ''
    #     sourcehut sourcehut sourcehut
    #   '';
    #   ensureDatabases = [ "sourcehut_meta" "sourcehut_git" ];
    #   ensureUsers = [{
    #     name = "sourcehut";
    #     ensurePermissions = {
    #       "DATABASE sourcehut_meta" = "ALL PRIVILEGES";
    #       "DATABASE sourcehut_git" = "ALL PRIVILEGES";
    #     };
    #   }];
    # };

    # systemd.services.sourcehut-meta = {
    #     description = "meta.sr.ht website service";
    #     requires = ["postgresql.service"];
    #     after = [ "postgresql.service network.target" ];

    #     environment = let
    #       penv = pkgs.python.buildEnv.override {
    #         extraLibs = [ pkgs.sourcehut.metasrht ] ;
    #       };
    #     in
    #     {
    #             PYTHONPATH = "${penv}/${pkgs.python.sitePackages}";
    #     };

    #     serviceConfig = {
    #       Type = "simple";
    #       User = "sourcehut";
    #       Restart = "always";
    #       ExecStart = ''${pkgs.python38Packages.gunicorn}/bin/gunicorn app.py --chdir ${pkgs.sourcehut.metasrht}/lib/python3.8/site-packages/metasrht -b 127.0.0.1:5000'';
    #     };
    #  };

    services.nginx = {
      enable = true;
      virtualHosts."nix.own" = {
        # addSSL = true;
        # enableACME = true;
        # root = "${blog}";
        root = "/var/www/pablo-tools";
      };

      virtualHosts."lislon.nix.own" = {
        # addSSL = true;
        # enableACME = true;
        root = "/var/www/lislon-pablo-tools";
      };
    };

    # virtualisation.oci-containers.containers = {
    #   bitwardenrs = {
    #     autoStart = true;
    #     image = "bitwardenrs/server:latest";
    #     environment = {
    #       DOMAIN = "http://nix.own";
    #       ADMIN_TOKEN = "test";
    #       SIGNUPS_ALLOWED = "true";
    #       INVITATIONS_ALOWED = "true";
    #     };
    #     ports = [
    #       "9999:80"
    #     ];
    #     volumes = [
    #       "/var/docker/bitwarden/:/data/"
    #     ];
    #   };
    # };


    users = {
      users.root = {
        openssh.authorizedKeys.keyFiles =
          [ (builtins.fetchurl { url = "https://github.com/pinpox.keys"; }) ];
      };

      # users.sourcehut = {
      #   description = "Sourcehut system user";

      #   home = "/var/sourcehut";
      #   createHome = true;
      #   openssh.authorizedKeys.keyFiles =
      #     [ (builtins.fetchurl { url = "https://github.com/pinpox.keys"; }) ];
      # };

      users.pinpox = {
        isNormalUser = true;
        home = "/home/pinpox";
        description = "Pablo Ovelleiro Corral";
        extraGroups = [ "wheel" "networkmanager" "audio" "libvirtd" ];

        # Public ssh-keys that are authorized for the user. Fetched from homepage
        # and github profile.
        openssh.authorizedKeys.keyFiles = [
          (builtins.fetchurl { url = "https://pablo.tools/ssh-key"; })
          (builtins.fetchurl { url = "https://github.com/pinpox.keys"; })
        ];
      };
    };

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "colemak";
    };
  };
}
