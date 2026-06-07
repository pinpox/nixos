{ settings }:
{ tangled, ... }:
{
  imports = [ tangled.nixosModules.spindle ];

  services.tangled.spindle = {
    enable = true;
    server = {
      hostname = settings.host;
      owner = settings.owner;
      # Loopback only; Caddy fronts it on 443.
      listenAddr = "127.0.0.1:${toString settings.port}";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."${settings.host}".extraConfig = ''
      reverse_proxy 127.0.0.1:${toString settings.port}
    '';
  };
}
