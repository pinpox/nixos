{ ... }:
# Incus container/VM hosts managed as independent "remotes" (no clustering).
# Each machine with the `peer` role runs incusd with its REST API exposed so it
# can be added via `incus remote add`. Persistent workloads live on always-on
# peers (e.g. clementine, containers only — Netcup blocks nested KVM), ephemeral
# VMs on workstation peers with /dev/kvm (e.g. mango).
#
# Set `webui.enable` + `webui.host` on a peer to additionally serve the Incus
# web UI through Caddy on a clan-internal `.pin` host. The endpoint is exported
# so the clan `pki` service issues its TLS cert and dm-dns publishes the name;
# Authelia OIDC sits in front (register the `incus` client on the Authelia
# instance — see `extraClients` in inventory.nix). Visit https://<host>/ui/.
{
  _class = "clan.service";
  manifest.name = "incus";
  manifest.description = "Incus container/VM hosts as independent remotes, optional OIDC-protected web UI";
  manifest.readme = ''
    Roles:
      - peer: runs incusd, exposes the REST API (core.https_address) and adds
        `pinpox` to the `incus-admin` group. A sensible default setup (dir
        storage pool, `incusbr0` bridge, default profile) is applied via
        preseed so the host is usable out of the box.

    Per-machine settings of note:
      - webui.enable / webui.host: serve the web UI via Caddy on a clan-internal
        `.pin` host. The host is exported as an endpoint, so the clan `pki`
        service issues the TLS cert and dm-dns publishes the name (no ACME).
        Configures OIDC on incusd; peers without a UI use TLS client certs.
      - openFirewall: open the API port. Disable on hosts that are only
        reached through the Caddy web UI proxy (the API stays on loopback).

    Caddy reverse-proxies to the local incusd over loopback (incusd serves its
    own self-signed cert, hence tls_insecure_skip_verify). The OIDC redirect
    URI is https://<host>/oidc/callback.
  '';
  manifest.categories = [ "System" ];
  manifest.exports.out = [ "endpoints" ];

  roles.peer = {
    description = "An Incus server (container/VM host) reachable as a remote; optionally serves the web UI.";

    interface =
      { lib, ... }:
      {
        options = {
          httpsAddress = lib.mkOption {
            type = lib.types.str;
            default = ":8443";
            description = "Address:port incusd binds its REST API to (core.https_address).";
            example = "10.0.0.5:8443";
          };

          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Open the API port in the firewall so the host can be added as a
              remote. Disable when the API is only reached through the Caddy
              web UI proxy (incusd still binds the address, but external access
              is blocked and only loopback — i.e. Caddy — can reach it).
            '';
          };

          storageDriver = lib.mkOption {
            type = lib.types.str;
            default = "dir";
            description = "Driver for the default storage pool created via preseed.";
            example = "btrfs";
          };

          lanInterface = lib.mkOption {
            type = lib.types.str;
            default = "";
            example = "enp191s0";
            description = ''
              Physical LAN interface to attach instances to via a `macvlan`
              network named `lan`. When set, the default profile puts instances
              directly on that LAN (address + DNS from your router), reachable
              from other LAN hosts. When empty, instances use the NAT'd
              `incusbr0` bridge. Note: with macvlan the incus host itself cannot
              reach its own instances over the network (kernel limitation) — use
              the console / `incus exec` for host-side access.
            '';
          };

          localImages = lib.mkOption {
            type = lib.types.attrsOf lib.types.path;
            default = { };
            example = lib.literalExpression ''
              {
                nixos-unstable-cloud-init = self.packages.x86_64-linux.incus-nixos-unstable-cloud-init;
                dev = self.packages.x86_64-linux.incus-dev-image;
              }
            '';
            description = ''
              Named NixOS VM images imported into Incus as `local:<name>`. Attr
              name = Incus alias; value = a package built by `pkgs.mkIncusVmImage`
              (a dir with `metadata.tar.xz` + `disk.qcow2`), typically referenced
              from the flake as `self.packages.<system>.<name>`. Launch with
              `incus launch local:<name> foo --vm`; the instance is SSH-reachable
              (pinpox keys baked in) out of the box. Rebuild + relaunch to pick up
              changes (existing instances are copies and do not auto-update).
            '';
          };

          webui = {
            enable = lib.mkEnableOption "serving the Incus web UI through Caddy with OIDC";
            host = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Clan-internal FQDN Caddy serves the web UI on; exported as an endpoint so pki issues the cert and dm-dns the DNS.";
              example = "boxes.pin";
            };
          };

          oidc = {
            issuer = lib.mkOption {
              type = lib.types.str;
              default = "https://auth.pablo.tools";
              description = "OIDC issuer (Authelia).";
            };
            clientId = lib.mkOption {
              type = lib.types.str;
              default = "incus";
              description = "OIDC client id registered with the issuer.";
            };
            audience = lib.mkOption {
              type = lib.types.str;
              default = "";
              defaultText = lib.literalExpression ''"https://''${webui.host}"'';
              description = ''
                Expected token audience; must match the Authelia client's
                `audience`. Defaults to the web UI URL when empty.
              '';
            };
          };
        };
      };

    perInstance =
      { settings, mkExports, ... }:
      {
        # Export the web UI host so the clan pki service issues its TLS cert and
        # dm-dns publishes the .pin name.
        exports = mkExports {
          endpoints.hosts = if settings.webui.enable then [ settings.webui.host ] else [ ];
        };

        nixosModule =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            port = lib.toInt (lib.last (lib.splitString ":" settings.httpsAddress));
            webuiEnabled = settings.webui.enable;
            audience =
              if settings.oidc.audience != "" then settings.oidc.audience else "https://${settings.webui.host}";
            lanEnabled = settings.lanInterface != "";
            defaultNetwork = if lanEnabled then "lan" else "incusbr0";
          in
          {
            assertions = [
              {
                assertion = !webuiEnabled || settings.webui.host != "";
                message = "incus: webui.host must be set when webui.enable is true";
              }
            ];

            # Incus on NixOS requires the nftables firewall backend.
            networking.nftables.enable = true;

            networking.firewall.allowedTCPPorts =
              lib.optionals settings.openFirewall [ port ]
              ++ lib.optionals webuiEnabled [
                80
                443
              ];

            # Trust the managed bridge: incusd's own nft table accepts guest
            # DHCP/DNS to the host, but nixos-fw's default-drop input chain runs
            # at the same hook and would drop it (a `drop` in any base chain
            # wins). Without this, instances get no IPv4 lease and no DNS.
            networking.firewall.trustedInterfaces = [ "incusbr0" ];

            # Local CLI access for the admin user.
            users.users.pinpox.extraGroups = [ "incus-admin" ];

            # Preseed can't manage images, so import each image package via a
            # oneshot. Content-addressed + idempotent: the alias is pointed at
            # the image whose fingerprint (sha256 of metadata ‖ rootfs, emitted
            # by mkIncusVmImage) matches. If that content is already in the
            # store (e.g. under another alias, or from a prior run) it's just
            # (re)aliased — never re-imported — so alias renames and repeat
            # activations can't collide ("image with same fingerprint exists").
            systemd.services = lib.mapAttrs' (
              alias: img:
              lib.nameValuePair "incus-image-${alias}" {
                description = "Import NixOS image into Incus (local:${alias})";
                after = [ "incus.service" ];
                requires = [ "incus.service" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
                script = ''
                  incus=${config.virtualisation.incus.package}/bin/incus
                  fp=$(cat ${img}/fingerprint)
                  # Serialize across all image services: two aliases for the
                  # same content would otherwise both import concurrently and
                  # collide on the shared fingerprint.
                  (
                    ${pkgs.util-linux}/bin/flock 9
                    if "$incus" image info "$fp" >/dev/null 2>&1; then
                      # Content already in the store (another alias, or a prior
                      # run). Point our alias at it — no re-import, so alias
                      # renames / repeat activations never collide.
                      cur=$("$incus" image info "${alias}" 2>/dev/null | sed -n 's/^Fingerprint: //p')
                      if [ "$cur" != "$fp" ]; then
                        "$incus" image alias delete ${alias} 2>/dev/null || true
                        "$incus" image alias create ${alias} "$fp"
                      fi
                      echo "image 'local:${alias}' -> $fp"
                    else
                      "$incus" image import ${img}/metadata.tar.xz ${img}/disk.qcow2 --alias ${alias}
                    fi
                  ) 9>/run/incus-image-import.lock
                '';
              }
            ) settings.localImages;

            virtualisation.incus = {
              enable = true;
              ui.enable = webuiEnabled;

              # Re-applied on change (overwrites managed entities, never removes).
              preseed = {
                config = {
                  "core.https_address" = settings.httpsAddress;
                }
                // lib.optionalAttrs webuiEnabled {
                  "oidc.issuer" = settings.oidc.issuer;
                  "oidc.client.id" = settings.oidc.clientId;
                  "oidc.audience" = audience;
                };

                networks = [
                  {
                    name = "incusbr0";
                    type = "bridge";
                    config = {
                      "ipv4.address" = "auto";
                      "ipv4.nat" = "true";
                      "ipv6.address" = "auto";
                      "ipv6.nat" = "true";
                    };
                  }
                ]
                ++ lib.optionals lanEnabled [
                  {
                    name = "lan";
                    type = "macvlan";
                    config.parent = settings.lanInterface;
                  }
                ];

                storage_pools = [
                  {
                    name = "default";
                    driver = settings.storageDriver;
                  }
                ];

                profiles = [
                  {
                    name = "default";
                    # NixOS (and most non-Microsoft-signed) VM images aren't
                    # signed for UEFI Secure Boot, which Incus enables by
                    # default. Disable it so VMs boot; containers ignore this key.
                    config."security.secureboot" = "false";
                    devices = {
                      eth0 = {
                        name = "eth0";
                        network = defaultNetwork;
                        type = "nic";
                      };
                      root = {
                        path = "/";
                        pool = "default";
                        type = "disk";
                      };
                    };
                  }
                ];
              };
            };

            # Web UI: Caddy serves the .pin host (TLS cert from the clan pki
            # service) and proxies to the local incusd, which serves the UI at
            # /ui/ and the OIDC callback at /oidc/callback. header_up keeps
            # r.Host = <host> so the callback URI is https://<host>/oidc/callback.
            services.caddy = lib.mkIf webuiEnabled {
              enable = true;

              # Incus' console/terminal uses WebSockets. Caddy cannot proxy
              # WebSockets over HTTP/2 (RFC 8441 / golang/go#53209), so browsers
              # that negotiate h2 fail to open the console socket. Force HTTP/1.1
              # for this host's Caddy so the h1.1 WebSocket upgrade path is used.
              # Note: applies to every site served by this host's Caddy.
              globalConfig = ''
                servers {
                  protocols h1
                }
              '';

              virtualHosts.${settings.webui.host}.extraConfig = ''
                @root path /
                redir @root /ui/ 302
                reverse_proxy https://127.0.0.1:${toString port} {
                  transport http {
                    tls_insecure_skip_verify
                  }
                  # incus derives its OIDC redirect_uri from the request Host;
                  # force the original host so it stays <webui.host> instead of
                  # the 127.0.0.1 upstream (otherwise Authelia rejects the
                  # redirect_uri as unregistered).
                  header_up Host {host}
                }
              '';
            };
          };
      };
  };
}
