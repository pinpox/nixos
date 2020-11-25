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
    networking.firewall.enable = false;

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

    security.acme.certs =

      {
        "pablo.tools" = {
          webroot = "/var/www/challenges/";
          email = "letsencrypt@pablo.tools";
          # extraDomainNames = [ "www.example.com" "foo.example.com" ];
        };
        # "bar.example.com" = {
        #   webroot = "/var/www/challenges/";
        #   email = "bar@example.com";
        # };
      };

    services.nginx = {
      enable = true;
      virtualHosts."nix.own" = {
        # addSSL = true;
        # enableACME = true;
        # root = "${blog}";
        root = "/var/www/pablo-tools";
      };

      # virtualHosts."lislon.nix.own" = {
      # addSSL = true;
      # enableACME = true;
      # root = "/var/www/lislon-pablo-tools";
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

  # users = {
  #   users.root = {
  #     openssh.authorizedKeys.keyFiles =
  #       [ (builtins.fetchurl { url = "https://github.com/pinpox.keys"; }) ];
  #   };
  # };
}
