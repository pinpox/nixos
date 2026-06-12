{ config, pkgs, ... }:
{
  # Self-signed cert for the leaf listener (native TLS on 7422). The public
  # cert is committed (non-secret) and shared out-of-band with teammates,
  # who reference it as their leaf remote `caFile`. Long validity so it
  # rarely needs rotation; regenerate + redistribute like an nkey when it
  # does. SAN must match the hostname teammates dial (nats.0cx.de).
  clan.core.vars.generators.team-nats-cert = {
    share = false;
    files.cert.secret = false; # public, committed to the flake
    files.key = {
      secret = true;
      mode = "0440";
      owner = "nats";
    };
    runtimeInputs = with pkgs; [ openssl ];
    script = ''
      openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -nodes -keyout $out/key -out $out/cert \
        -subj "/CN=nats.0cx.de" \
        -addext "subjectAltName=DNS:nats.0cx.de" \
        -days 3650
    '';
  };

  pinpox.services.team-nats = {
    enable = true;
    teammates.pinpox.nkey = "UDCHB7UQD46DZIHEL2DBI2R6H2I3FYM73QUUU5CS54ZM5AIXSYH6QLEP";
    tls = {
      certFile = config.clan.core.vars.generators.team-nats-cert.files.cert.path;
      keyFile = config.clan.core.vars.generators.team-nats-cert.files.key.path;
    };
  };
}
