{ config, pkgs, lib, modulesPath, ... }: {

  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];


  config = {

    networking.hostName = "kfbox";

    services.qemuGuest.enable = true;

    # Setup Yubikey SSH and GPG
    services.pcscd.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
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
      neovim
      nixfmt
      python
      ripgrep
      wget
    ];

    security.acme.acceptTerms = true;
    security.acme.email = "letsencrypt@pablo.tools";


    # Block anything that is not HTTP(s) or SSH.
    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 80 443 22 ];

      # interfaces.wg0.allowedTCPPorts = [ 2812 ];
    };

    services.nginx  = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "128m";

      # commonHttpConfig = ''
      #   server_names_hash_bucket_size 128;
      # '';

      # No need to support plain HTTP, forcing TLS for all vhosts. Certificates
      # provided by Let's Encrypt via ACME. Generation and renewal is automatic
      # if DNS is set up correctly for the (sub-)domains.
      virtualHosts = {
        # Personal homepage and blog
        # "0cx.de" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   root = "/var/www/";
        # };

        # The Lounge IRC
        "irc.0cx.de" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:9090"; };
        };



        # Mattermost
        # "mm.0cx.de" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = { proxyPass = "http://127.0.0.1:9005"; };
        # };

      };
    };
  };
}
