{ self }:
{
  lib,
  clanLib,
  directory,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "dm-dns";
  manifest.description = "Distributed DNS zone propagation and PKI certificates for clan networks";
  manifest.readme = "Provides distributed DNS zone synchronization and automatic TLS certificates for clan services.";
  manifest.traits = [ "dataMesher" ];

  roles.default = {
    description = "DNS zone propagation via data-mesher and unbound";

    interface = { };

    perInstance =
      {
        exports,
        mkExports,
        ...
      }:
      {

        exports = mkExports {
          dataMesher.files = {
            "dns/cnames" = [
              (clanLib.getPublicValue {
                flake = directory;
                generator = "dm-dns-signing-key";
                file = "signing.pub";
                default = throw ''
                  dm-dns: Signing key not yet generated.
                  Run 'clan vars generate' to generate the dm-dns signing key before deploying.
                '';
              })
            ];
          };
        };

        nixosModule =
          {
            pkgs,
            config,
            ...
          }:
          let
            domain = config.clan.core.settings.domain;

            # Collect all exports from the entire clan (for CNAME entries)
            allExports = clanLib.selectExports (_scope: true) exports;

            # Helper to check if a host is internal (matches *.${domain})
            isInternalHost = host: lib.hasSuffix ".${domain}" host;

            # Helper to extract endpoint name from host: "music.pin" -> "music"
            extractEndpoint = host: lib.removeSuffix ".${domain}" host;

            # Extract endpoints.hosts from exports, generate CNAME entries for the zone file
            cnameEntries = lib.concatLists (
              lib.mapAttrsToList (
                scopeKey: exportValue:
                let
                  parsed = clanLib.parseScope scopeKey;
                  hostname = parsed.machineName;
                  hosts = exportValue.endpoints.hosts or [ ];
                  internalHosts = lib.filter isInternalHost hosts;
                in
                map (
                  host:
                  let
                    endpoint = extractEndpoint host;
                  in
                  ''local-data: "${endpoint}.${domain}. CNAME ${hostname}.${domain}."''
                ) internalHosts
              ) allExports
            );

            # Zone file content distributed via data-mesher
            zoneContent = lib.concatStringsSep "\n" (
              [ ''local-zone: "${domain}." transparent'' ] ++ cnameEntries
            );

            # Generate local-data entries from networking.hosts
            localDataFromHosts = lib.flatten (
              lib.mapAttrsToList (
                ip: hostnames:
                map (
                  hostname:
                  if lib.hasInfix ":" ip then
                    ''"${hostname}. AAAA ${ip}"''
                  else
                    ''"${hostname}. A ${ip}"''
                ) (lib.filter (h: h != "localhost") hostnames)
              ) config.networking.hosts
            );

            dmFilesDir = "/var/lib/data-mesher/files/dns";
          in
          {
            # Signing key for zone file distribution via data-mesher
            clan.core.vars.generators.dm-dns-signing-key = {
              share = true;
              files = {
                "signing.key".deploy = false;
                "signing.pub".secret = false;
              };
              runtimeInputs = [ config.services.data-mesher.package ];
              script = ''
                data-mesher generate signing-key \
                  --private-key-path "$out/signing.key" \
                  --public-key-path "$out/signing.pub"
              '';
            };

            # Zone file content to be signed and pushed to data-mesher
            clan.core.vars.generators.dm-dns = {
              share = true;
              files."zone.conf".secret = false;
              # Regenerate when exports change
              validation.zoneContent = zoneContent;
              runtimeInputs = [ pkgs.coreutils ];
              script = ''
                cat > "$out/zone.conf" << 'ZONE'
                ${zoneContent}
                ZONE
              '';
            };

            # Helper script to sign and push the zone file to data-mesher
            environment.systemPackages =
              let
                dm-send-dns = pkgs.writeShellApplication {
                  name = "dm-send-dns";
                  runtimeInputs = [ config.services.data-mesher.package ];
                  text = ''
                    data-mesher file update \
                      "${config.clan.core.vars.generators.dm-dns.files."zone.conf".path}" \
                      --url http://localhost:7331 \
                      --key "$(passage show clan-vars/shared/dm-dns-signing-key/signing.key)" \
                      --name "dns/cnames"
                  '';
                };
              in
              [ dm-send-dns ];

            # Create dns subdirectory in data-mesher's file storage early in boot
            services.data-mesher.fileDirectories = [ "dns" ];

            # Add unbound to data-mesher group so it can read distributed zone files
            users.users.unbound.extraGroups = [ config.services.data-mesher.group ];

            # Route clan domain queries to unbound
            networking.nameservers = [ "127.0.0.1:5353#${domain}" ];
            services.resolved.settings.Resolve.Domains = [ "~${domain}" ];

            services.unbound = {
              enable = true;
              localControlSocketPath = "/run/unbound/unbound.ctl";
              settings = {
                server = {
                  port = 5353;
                  interface = [ "127.0.0.1" ];
                  access-control = [ "127.0.0.0/8 allow" ];
                  do-not-query-localhost = "no";
                  domain-insecure = [ "${domain}." ];

                  # A/AAAA records from networking.hosts
                  local-data = localDataFromHosts;

                  # Zone data (CNAME entries etc.) distributed via data-mesher
                  include = ''"${dmFilesDir}/*"'';
                };
                forward-zone = [
                  {
                    name = ".";
                    forward-addr = "127.0.0.53@53";
                  }
                ];
              };
            };

            # Allow unbound's sandbox to access data-mesher's dns file directory
            systemd.services.unbound.serviceConfig.BindReadOnlyPaths = [ dmFilesDir ];

            # Watch for zone file changes from data-mesher and reload unbound
            systemd.paths.unbound-reload-zones = {
              description = "Watch for zone file changes";
              wantedBy = [ "multi-user.target" ];
              pathConfig = {
                PathChanged = dmFilesDir;
                Unit = "unbound-reload-zones.service";
              };
            };

            systemd.services.unbound-reload-zones = {
              description = "Reload unbound zone configuration";
              after = [ "unbound.service" ];
              requires = [ "unbound.service" ];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${config.services.unbound.package}/bin/unbound-control -s /run/unbound/unbound.ctl reload";
              };
            };
          };
      };
  };
}
