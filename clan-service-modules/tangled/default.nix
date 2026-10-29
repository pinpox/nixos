{ ... }:
{
  _class = "clan.service";
  manifest.name = "tangled";
  manifest.description = "Tangled self-hosted git host (knot).";
  manifest.readme = ''
    knot: self-hosted git repository host (upstream `knot-rs`). Serves HTTP
    behind Caddy and runs its own SSH server for git on `sshPort`, separate
    from the system openssh. The master key unsealing the knot's signing key
    is generated as a clan var.

    Registers against the appview at https://tangled.org and needs to be
    verified once via the appview UI (settings → knots).
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
          sshPort = lib.mkOption {
            type = lib.types.port;
            default = 2222;
            description = ''
              Port of the knot's own SSH server for git. Opened in the
              firewall. Must not collide with the system openssh.
            '';
          };
          contactEmail = lib.mkOption {
            type = lib.types.str;
            default = "mail@pablo.tools";
            description = "Operator contact email advertised by the knot.";
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
}
