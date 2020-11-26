let domain = "nix.own";
in { config, pkgs, lib, ... }: {
  imports = [

    # Include virtual hardware configuration
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>

    # Default users
    #../../common/user-profiles/root.nix
    ../../common/user-profiles/pinpox.nix

    # Include reusables
    # ../../common/borg/home.nix
    # ../../common/sound.nix
    ../../common/openssh.nix
    ../../common/environment.nix
    # ../../common/xserver.nix
    # ../../common/networking.nix
    # ../../common/bluetooth.nix
    # ../../common/fonts.nix
    ../../common/locale.nix
    # ../../common/yubikey.nix
    # ../../common/virtualization.nix
    ../../common/zsh.nix
  ];

  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    # TODO enable  firewall
    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 80 443 ];
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

      commonHttpConfig = ''
        server_names_hash_bucket_size 128;
      '';

      virtualHosts = {

        "pablo.tools" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/www/pablo-tools";
        };

        "pass.pablo.tools" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8222"; };
        };
      };
    };

    services.bitwarden_rs = {
      enable = true;
      config = {
        domain = "https://pass.pablo.tools:443";
        signupsAllowed = true;
        rocketPort = 8222;
      };

      environmentFile = /var/lib/bitwarden_rs/envfile;
    };
  };
}
