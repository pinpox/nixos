{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.unbound-desktop;
in
{

  options.pinpox.services.unbound-desktop = {
    enable = mkEnableOption "local unbound for desktops";
  };

  config = mkIf cfg.enable {

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
    # networking.networkmanager.dns = "unbound";
    # services.resolved.enable = false;
    networking.search = [ "fritz.box" ];

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

        domain-insecure = [ "fritz.box" ];
        stub-zone = [
          {
            name = "fritz.box";
            stub-addr = "192.168.2.1";
          }
        ];

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
