{
  tunnel,
  pkgs,
  config,
  lib,
  ...
}:

let
  pinpox-utils = import ../../utils { inherit pkgs lib; };
in
{

  imports = [ tunnel.nixosModules.tunnel ];

  networking.hostName = "tunnelmonster";
  clan.core.networking.targetHost = "202.61.225.166";

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      22
    ];
  };

  clan.core.vars.generators."porkbun-dns" = pinpox-utils.mkEnvGenerator [
    "PORKBUN_SECRET_API_KEY"
    "PORKBUN_API_KEY"
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "letsencrypt@pablo.tools";

  security.acme.certs."tunnelmonster.com" = {
    domain = "tunnelmonster.com";
    extraDomainNames = [ "*.tunnelmonster.com" ];
    dnsProvider = "porkbun";
    environmentFile = config.clan.core.vars.generators.porkbun-dns.files.envfile.path;
  };

  services.caddy = {
    enable = true;
    virtualHosts."tunnelmonster.com" = {
      useACMEHost = "tunnelmonster.com";
      extraConfig = "reverse_proxy 127.0.0.1:8080";
    };
  };

  services.tunnel = {
    enable = false;
    hostname = "tunnelmonster.com";
    # hostname = "tunnelmonster.com";
    # wireguardNetwork = "10.101.0.0/16";
    # wireguardPort = 54321;
    # description = "The port for the tunnel HTTP service";
    # listenPort = 8080;
    caddy.enable = true;
  };

  # Allow tunnel service to bind to privileged ports and manage network
  # security.sudo.wheelNeedsPassword = false;
  # users.users.tunnel.extraGroups = [ "wheel" ];

  # Disable firewall for testing
  # networking.firewall.enable = lib.mkForce false;

  # Ensure WireGuard tools are available
  environment.systemPackages = with pkgs; [
    wireguard-go
    wireguard-tools
    nettools
    iproute2
    curl
  ];

  # networking.interfaces.ens3 = {
  #   ipv6.addresses = [
  #     {
  #       address = "2a03:4000:7:4e0::";
  #       prefixLength = 64;
  #     }
  #   ];
  # };
  #
  #
  # services.logind.extraConfig = ''
  #   RuntimeDirectorySize=20G
  # '';
  #
  #
  # pinpox = {
  #   services = { };
  # };
  #
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/nixos";
  #   fsType = "ext4";
  #   autoResize = true;
  # };
  #
  # fileSystems."/tmp" = {
  #   fsType = "tmpfs";
  #   device = "tmpfs";
  #   options = [
  #     "nosuid"
  #     "nodev"
  #     "relatime"
  #     "size=14G"
  #   ];
  # };
  #
  # boot.growPartition = true;
  # boot.kernelParams = [ "console=ttyS0" ];
  # boot.loader.grub.device = "/dev/sda";
  # boot.loader.timeout = 0;
}
