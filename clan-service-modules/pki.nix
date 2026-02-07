{
  lib,
  clanLib,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "pki";
  manifest.description = "PKI certificate infrastructure for clan endpoints";
  manifest.readme = "Provides Root CA, per-machine intermediate CAs, and automatic TLS endpoint certificates for clan services.";

  roles.default = {
    description = "TLS certificate infrastructure (Root CA, intermediate CA, endpoint certs)";

    interface = { };

    perInstance =
      {
        machine,
        exports,
        ...
      }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            machineExports = clanLib.selectExports (scope: scope.machineName == machine.name) exports;

            domain = config.clan.core.settings.domain;

            isInternalHost = host: lib.hasSuffix ".${domain}" host;
            extractEndpoint = host: lib.removeSuffix ".${domain}" host;

            allHosts = lib.concatLists (
              lib.mapAttrsToList (_scopeKey: exportValue: exportValue.endpoints.hosts or [ ]) machineExports
            );

            internalHosts = lib.filter isInternalHost allHosts;
            allEndpoints = map extractEndpoint internalHosts;

            mkTLSDirective =
              endpoint:
              let
                cert = config.clan.core.vars.generators."cert-${endpoint}".files."${endpoint}.fullchain.crt".path;
                key = config.clan.core.vars.generators."cert-${endpoint}".files."${endpoint}.key".path;
              in
              "tls ${cert} ${key}";

            tlsOverrides = lib.listToAttrs (
              map (host: {
                name = host;
                value.extraConfig = lib.mkBefore "${mkTLSDirective (extractEndpoint host)}\n";
              }) internalHosts
            );

            nginxSSLOverrides = lib.listToAttrs (
              map (host:
                let
                  endpoint = extractEndpoint host;
                  cert = config.clan.core.vars.generators."cert-${endpoint}".files."${endpoint}.fullchain.crt".path;
                  key = config.clan.core.vars.generators."cert-${endpoint}".files."${endpoint}.key".path;
                in
                {
                  name = host;
                  value = {
                    sslCertificate = cert;
                    sslCertificateKey = key;
                  };
                }
              ) internalHosts
            );

            endpointCertGenerators = lib.listToAttrs (
              map (endpoint: {
                name = "cert-${endpoint}";
                value = {
                  dependencies = [ "pki-intermediate-ca" ];

                  files."${endpoint}.key" = {
                    secret = true;
                    deploy = true;
                    group = "clan-pki";
                    mode = "0640";
                  };
                  files."${endpoint}.crt" = {
                    secret = false;
                    deploy = true;
                  };
                  files."${endpoint}.fullchain.crt" = {
                    secret = false;
                    deploy = true;
                  };

                  validation = {
                    inherit endpoint domain;
                  };

                  runtimeInputs = [ pkgs.openssl ];

                  script = ''
                    openssl genrsa -out "$out/${endpoint}.key" 4096

                    openssl req -new \
                      -key "$out/${endpoint}.key" \
                      -subj "/CN=${endpoint}.${domain}" \
                      -out endpoint.csr

                    openssl x509 -req \
                      -in endpoint.csr \
                      -CA "$in/pki-intermediate-ca/intermediate.crt" \
                      -CAkey "$in/pki-intermediate-ca/intermediate.key" \
                      -CAcreateserial \
                      -days 365 \
                      -sha256 \
                      -extfile <(printf "subjectAltName=DNS:${endpoint}.${domain}") \
                      -out "$out/${endpoint}.crt"

                    cat "$out/${endpoint}.crt" "$in/pki-intermediate-ca/intermediate.crt" \
                      > "$out/${endpoint}.fullchain.crt"
                  '';
                };
              }) allEndpoints
            );
          in
          {
            users.groups.clan-pki = { };

            security.pki.certificateFiles = [
              config.clan.core.vars.generators."pki-root-ca".files."ca.crt".path
            ];

            users.users = lib.mkMerge [
              (lib.mkIf config.services.caddy.enable {
                caddy.extraGroups = [ "clan-pki" ];
              })
              (lib.mkIf config.services.nginx.enable {
                nginx.extraGroups = [ "clan-pki" ];
              })
            ];

            services.caddy.virtualHosts = lib.mkIf (internalHosts != [ ]) tlsOverrides;
            services.nginx.virtualHosts = lib.mkIf (internalHosts != [ ]) nginxSSLOverrides;

            # Root CA + Intermediate CA + endpoint certificate generators
            clan.core.vars.generators =
              {
                "pki-root-ca" = {
                  share = true;

                  files."ca.key" = {
                    secret = true;
                    deploy = false;
                  };
                  files."ca.crt".secret = false;

                  runtimeInputs = [ pkgs.openssl ];

                  script = ''
                    openssl genrsa -out $out/ca.key 4096

                    openssl req -x509 -new -nodes \
                      -key $out/ca.key \
                      -sha256 -days 3650 \
                      -subj "/CN=Clan Root CA" \
                      -out $out/ca.crt
                  '';
                };

                "pki-intermediate-ca" = {
                  dependencies = [ "pki-root-ca" ];

                  files."intermediate.key" = {
                    secret = true;
                    deploy = true;
                  };
                  files."intermediate.crt" = {
                    secret = false;
                    deploy = true;
                  };

                  validation = {
                    machineName = config.clan.core.settings.machine.name;
                  };

                  runtimeInputs = [ pkgs.openssl ];

                  script = ''
                    openssl genrsa -out $out/intermediate.key 4096

                    openssl req -new \
                      -key $out/intermediate.key \
                      -subj "/CN=${config.clan.core.settings.machine.name} Intermediate CA" \
                      -out intermediate.csr

                    openssl x509 -req \
                      -in intermediate.csr \
                      -CA $in/pki-root-ca/ca.crt \
                      -CAkey $in/pki-root-ca/ca.key \
                      -CAcreateserial \
                      -days 1825 \
                      -sha256 \
                      -extfile <(printf "basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign") \
                      -out $out/intermediate.crt
                  '';
                };
              }
              // endpointCertGenerators;
          };
      };
  };
}
