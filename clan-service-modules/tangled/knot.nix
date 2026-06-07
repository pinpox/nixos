{ settings }:
{ tangled, ... }:
{
  imports = [ tangled.nixosModules.knot ];

  services.tangled.knot = {
    enable = true;
    # Firewall (port 22) is managed by pinpox.services.openssh; suppress the
    # upstream module's own opening to keep firewall config in one place.
    openFirewall = false;
    motd = settings.motd;
    server = {
      hostname = settings.host;
      owner = settings.owner;
      # Loopback only; Caddy fronts it on 443.
      listenAddr = "127.0.0.1:${toString settings.port}";
    };
  };

  services.caddy = {
    enable = true;
    # Caddy auto-handles WebSocket upgrades for the /events endpoint.
    virtualHosts."${settings.host}".extraConfig = ''
      reverse_proxy 127.0.0.1:${toString settings.port}
    '';
  };
}
