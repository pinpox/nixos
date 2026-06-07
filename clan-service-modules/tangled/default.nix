{ ... }:
{
  _class = "clan.service";
  manifest.name = "tangled";
  manifest.description = "Tangled self-hosted git host (knot) and CI runner (spindle).";
  manifest.readme = ''
    Two roles:
      - knot: self-hosted git repository host. Serves HTTP behind Caddy and
        SSH (port 22) for git, with key auth wired up to the tangled appview.
      - spindle: CI runner. Serves HTTP behind Caddy and runs workflow jobs
        in Docker containers.

    Both register against the appview at https://tangled.org and need to be
    verified once via the appview UI (settings → knots / settings → spindles).
  '';
  manifest.categories = [ "Development" ];
  manifest.exports.out = [ "endpoints" ];

  roles.knot = {
    description = "Tangled knot: self-hosted git host (HTTP + SSH).";
    interface =
      { lib, meta, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "knot.${meta.domain}";
            description = "Public hostname (fronted by Caddy).";
            example = "knot.example.com";
          };
          owner = lib.mkOption {
            type = lib.types.str;
            default = "did:plc:y6qbagc23y773kp5emhsaoo3";
            description = ''
              DID of the knot owner. Must be registered via /knots on the
              appview before the knot is accepted. Defaults to pinpox.bsky.social.
            '';
            example = "did:plc:qfpnj4og54vl56wngdriaxug";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 5555;
            description = "Loopback HTTP port the knot serves on, behind Caddy.";
          };
          motd = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Message-of-the-day shown when SSHing to the knot as `git`.
              `null` keeps the upstream default ("Welcome to this knot!").
            '';
            example = "Hi from pinpox's knot.\n";
          };
        };
      };

    perInstance =
      {
        settings,
        mkExports,
        ...
      }:
      {
        exports = mkExports { endpoints.hosts = [ settings.host ]; };
        nixosModule = import ./knot.nix { inherit settings; };
      };
  };

  roles.spindle = {
    description = "Tangled spindle: CI runner that executes pipelines in Docker.";
    interface =
      { lib, meta, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "spindle.${meta.domain}";
            description = "Public hostname (fronted by Caddy).";
            example = "spindle.example.com";
          };
          owner = lib.mkOption {
            type = lib.types.str;
            default = "did:plc:y6qbagc23y773kp5emhsaoo3";
            description = ''
              DID of the spindle owner. Must be registered via /spindles on
              the appview. Defaults to pinpox.bsky.social.
            '';
            example = "did:plc:qfpnj4og54vl56wngdriaxug";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 6555;
            description = "Loopback HTTP port the spindle serves on, behind Caddy.";
          };
        };
      };

    perInstance =
      {
        settings,
        mkExports,
        ...
      }:
      {
        exports = mkExports { endpoints.hosts = [ settings.host ]; };
        nixosModule = import ./spindle.nix { inherit settings; };
      };
  };
}
