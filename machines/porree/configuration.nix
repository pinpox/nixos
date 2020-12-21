let domain = "nix.own";
in { config, pkgs, lib, modulesPath, ... }: {

  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  config = {

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gtk2";
    };

    services.qemuGuest.enable = true;

    # Setup Yubikey SSH and GPG
    services.pcscd.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    # Block anything that is not HTTP(s) or SSH.
    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 80 443 22 ];
      allowedUDPPorts = [ 51820 ];

      interfaces.wg0.allowedTCPPorts = [ 2812 ];
    };

    boot.growPartition = true;
    boot.kernelParams = [ "console=ttyS0" ];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    programs.ssh.startAgent = false;

    environment.systemPackages = with pkgs; [
      ctags
      git
      gnumake
      go
      htop
      mmonit
      neovim
      nix-index
      nixfmt
      python
      ripgrep
      wget
    ];

    services.monit = {

      enable = true;
      config = ''
        include /var/src/secrets/monit/conf
        include /var/src/machine-config/modules/monit/configs/default
        include /var/src/machine-config/modules/monit/configs/porree
'';
};


    networking.hostName = "porree";

    security.acme.acceptTerms = true;
    security.acme.email = "letsencrypt@pablo.tools";

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "128m";

      # Needed for bitwarden_rs, it seems to have trouble serving scripts for
      # the frontend without it.
      commonHttpConfig = ''
        server_names_hash_bucket_size 128;
      '';

      # No need to support plain HTTP, forcing TLS for all vhosts. Certificates
      # provided by Let's Encrypt via ACME. Generation and renewal is automatic
      # if DNS is set up correctly for the (sub-)domains.
      virtualHosts = {
        # Personal homepage and blog
        "pablo.tools" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/www/pablo-tools";
        };

        # Password manager (bitwarden) instance
        "pass.pablo.tools" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8222"; };
        };
      };
    };

    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      # Users allowed to run nix
      allowedUsers = [ "root" ];
    };

    # Enable Wireguard
    networking.wireguard.interfaces = {

      wg0 = {

        # Determines the IP address and subnet of the client's end of the
        # tunnel interface.
        ips = [ "192.168.7.1/24" ];

        listenPort = 51820;

        # Path to the private key file
        privateKeyFile = toString /var/src/secrets/wireguard/private;
        peers = [
          # kartoffel
          {
            publicKey = "759CaBnvpwNqFJ8e9d5PhJqIlUabjq72HocuC9z5XEs=";
            allowedIPs = [ "192.168.7.3" ];
          }
          # ahorn
          {
            publicKey = "ny2G9iJPBRLSn48fEmcfoIdYi3uHLbJZe3pH1F0/XVg=";
            allowedIPs = [ "192.168.7.2" ];
          }
          # kfbox
          {
            publicKey = "Cykozj24IkXEJ/6ktXxaqqIsxx8xjRMHKmR76lindCc=";
            allowedIPs = [ "192.168.7.5" ];
          }
          # birne
          {
            publicKey = "feDKNR4ZAeEiAsLFJM9FdNi6LHMjnvDj9ap/GRdLKF0=";
            allowedIPs = [ "192.168.7.4" ];
          }
          # mega
          {
            publicKey = "0IjZ/3dTvz0zaWPhJ9vIAINYG+W0MjbwePUDvhQNCXo=";
            allowedIPs = [ "192.168.7.6" ];
          }
        ];
      };
    };

    # Bitwarden_rs installed via nixpkgs.
    services.bitwarden_rs = {
      enable = true;
      config = {
        domain = "https://pass.pablo.tools:443";
        signupsAllowed = true;

        # The rocketPort option should match the value of the port in the reverse-proxy
        rocketPort = 8222;
      };

      # The environment file has to be provided manually as it includes private data.
      environmentFile = /var/lib/bitwarden_rs/envfile;
    };
  };
}
