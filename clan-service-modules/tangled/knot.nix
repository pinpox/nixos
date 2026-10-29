{ settings }:
{
  config,
  pkgs,
  tangled,
  ...
}:
{
  imports = [ tangled.nixosModules.knot-rs ];

  # 32 random bytes, standard base64, as knot-server expects in
  # KNOT_MASTER_KEY. Losing it makes the sealed signing key unreadable.
  clan.core.vars.generators."tangled-knot" = {
    files.envfile = { };
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      echo "KNOT_MASTER_KEY=$(head -c 32 /dev/urandom | base64 -w0)" > "$out"/envfile
    '';
  };

  services.tangled.knot-rs = {
    enable = true;
    # Opens sshPort; the HTTP surface is loopback-only behind Caddy.
    openFirewall = true;
    environmentFile = config.clan.core.vars.generators."tangled-knot".files.envfile.path;
    settings = {
      server = {
        hostname = settings.host;
        admins = [ settings.owner ];
        listen_addr = "127.0.0.1:${toString settings.port}";
        ssh_listen_addr = "[::]:${toString settings.sshPort}";
      };
      atproto.plc_directory = "https://plc.directory";
      contact.email = settings.contactEmail;
      lfs.store_path = "/var/lib/knot/lfs";
      # Caddy replaces X-Forwarded-For with the client address.
      xrpc = {
        trusted_proxy_header = "x-forwarded-for";
        trusted_proxies = [ "127.0.0.1" ];
      };
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
