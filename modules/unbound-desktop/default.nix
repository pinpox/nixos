{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.unbound-desktop;
in
{




  options.pinpox.services.unbound-desktop = {
    enable = mkEnableOption "local unbound for desktops";
  };

  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPortRanges = [
      { from = 6500; to = 8000; }
      { from = 49152; to = 65535; }
    ];
    networking.firewall.allowedUDPPortRanges = [
      { from = 6500; to = 8000; }
      { from = 49152; to = 65535; }
    ];


    networking.firewall.allowedTCPPorts = [
      7000
      7001
      7100

      554
      5990
      5353
      5961

      5960

      5959
      5960




      6960
      6961
      6962

      7960
      7961
      7962



    ];
    # 5353 	UDP 	This is the standard port used for mDNS communication and is always used for multicast sending of the current sources onto the network.
    # 5959 	TCP 	NDI Discovery Server is an optional method to have NDI devices perform discovery. This can be beneficial in large configurations, when you need to connect NDI devices between subnets or if mDNS is blocked.
    # 5960 	TCP 	This is a TCP port used for remote sources to query this machine and discover all of the sources running on it. This is used for instance when a machine is added by an IP address in the access manager so that from an IP address alone all of the sources currently running on that machine can be discovered automatically.
    # 5961 and up 	TCP 	These are the base TCP connections used for each NDI stream. For each current connection, at least one port number will be used in this range.
    # 5960 and up 	UDP 	In version 5 and above, when using reliable UDP connections it will use a very small number of ports in the range of 5960 for UDP. These port numbers are shared with the TCP connections. Because connection sharing is used in this mode, the number of ports required is very limited and only one port is needed per NDI process running and not one port per NDI connection.
    # 6960 and up 	TCP/UDP 	When using multi-TCP or UDP receiving, at least one port number in this range will be used for each connection.
    # 7960 and up 	TCP/UDP 	When using multi-TCP, unicast UDP, or multicast UDP sending, at least one port number in this range will be used for each connection.
    # Ephemeral 	TCP 	Legacy to NDI v1 - The current versions (4.6 and later) no longer use any ports in the ephemeral port range.
    networking.firewall.allowedUDPPorts = [






      5353
      6000
      6001
      7071
      7011

      554
      5990
      5353

      5960
      5961
      5962
      5963
      5964


      6960
      6961
      6962

      7960
      7961
      7962

    ];

    programs.wireshark.enable = true;
    programs.wireshark.package = pkgs.wireshark;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
        domain = true;
      };
    };

    networking.networkmanager.insertNameservers = config.services.unbound.settings.server.interface;
    networking.networkmanager.dns = "unbound";
    services.resolved.enable = false;
    # networking.search = [ "fritz.box" ];

    services.unbound = {
      enable = true;
      settings = {

        server = {
          interface = [ "127.0.0.1" ];

          # include = [
          #   "\"${dns-overwrites-config}\""
          #   "\"${flake-self.inputs.adblock-unbound.packages.${pkgs.system}.unbound-adblockStevenBlack}\""
          # ];

          access-control = [ "127.0.0.0/8 allow" ];
        };

        # domain-insecure = [ "fritx.box" ];
        # stub-zone = [{ name = "fritz.box"; stub-addr = "192.168.2.1"; }];

        forward-zone = [
          {
            name = "google.*.";
            forward-addr = [
              "8.8.8.8@853#dns.google"
              "8.8.8.4@853#dns.google"
            ];
            forward-tls-upstream = "yes";
          }
          {
            name = ".";
            forward-addr = [
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com"
              "192.168.2.1"
            ];
            forward-tls-upstream = "yes";
          }





        ];
        # remote-control.control-enable = true;
      };
    };
  };
}
