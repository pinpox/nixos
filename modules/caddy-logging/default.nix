{
  config,
  lib,
  ...
}:
let
  cfg = config.pinpox.services.caddy-logging;

  # Per-vhost `log { ... }` body. We send everything to stderr so it
  # ends up in the systemd journal (which is already size-capped via
  # `services.journald.extraConfig = "SystemMaxUse=1G"` in the
  # server machine-type module). No file rotation to manage, no
  # /var/log/caddy to fill the disk.
  #
  # When the `log` block lives inside a site block, Caddy automatically
  # scopes it to that site's logger, so per-site filtering still works
  # via the JSON `request.host` field, e.g.:
  #     journalctl -u caddy -o cat | \
  #         jq 'select(.request.host=="0cx.de")'
  defaultLogFormat = ''
    output stderr
    format json
  '';
in
{
  options = {
    pinpox.services.caddy-logging.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.services.caddy.enable;
      defaultText = lib.literalExpression "config.services.caddy.enable";
      description = ''
        Route Caddy access logs to the systemd journal instead of
        per-vhost files in `/var/log/caddy`. Journal size is already
        capped via `services.journald.extraConfig`, so disk usage is
        bounded for free.

        Individual vhosts can opt out by setting their own
        `services.caddy.virtualHosts.<name>.logFormat` — this module
        uses `lib.mkDefault`.
      '';
    };

    # Extend the per-vhost submodule type with one extra module that
    # contributes a default value for `logFormat`. NixOS merges
    # submodule definitions when the same option is declared with an
    # `attrsOf submodule` type in multiple modules. Using
    # `lib.mkDefault` here means individual vhosts can still override
    # the value, and we avoid the infinite-recursion trap that comes
    # with trying to read host names from
    # `config.services.caddy.virtualHosts` while contributing to it.
    services.caddy.virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            config = lib.mkIf cfg.enable {
              logFormat = lib.mkDefault defaultLogFormat;
            };
          }
        )
      );
    };
  };
}
