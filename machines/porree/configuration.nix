let domain = "nix.own";
in { config, pkgs, lib, ... }: {
  imports = [

    # Include virtual hardware configuration
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>

    # Default users
    #../../common/user-profiles/root.nix
    ../../common/user-profiles/pinpox.nix

    # Include reusables
    # ../../common/bluetooth.nix
    # ../../common/borg/home.nix
    # ../../common/fonts.nix
    # ../../common/networking.nix
    # ../../common/sound.nix
    # ../../common/virtualization.nix
    # ../../common/xserver.nix
    # ../../common/yubikey.nix
    ../../common/environment.nix
    ../../common/locale.nix
    ../../common/openssh.nix
    ../../common/zsh.nix
  ];

  config = {
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
    };

    boot.growPartition = true;
    boot.kernelParams = [ "console=ttyS0" ];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    programs.ssh.startAgent = false;

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
    ];

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
