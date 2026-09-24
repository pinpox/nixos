{ ... }:
{
  _class = "clan.service";
  manifest.name = "monitoring-glue";
  manifest.description = "Caddy, OIDC and alerting glue for the clan-core monitoring server";
  manifest.readme = ''
    Fronts the clan-core `monitoring` server (mimir/loki/grafana, deployed
    with proxy.enable = false) with the infra-native plumbing:

    - Caddy vhost on a clan-internal `.pin` host: /mimir and /loki behind
      basic auth (reusing the clan-core mimir-auth/loki-auth htpasswd,
      converted to caddy's format), /grafana prefix-stripped to grafana. The
      host is exported as an endpoint, so pki issues the TLS cert and dm-dns
      publishes the name.
    - Grafana login via Pocket ID (exported auth.client; secret published by
      the reconciler at /run/pocket-id-clients/<clientId>/secret).
    - Declarative Grafana alerting: rules from ./alert-rules.nix, delivered
      to the Matrix room via the machine-local matrix-hook webhook.
    - Provisioned dashboards from ./dashboards ("Overview" per host,
      "Caddy" per toplevel domain from the access logs in loki), alongside
      the ones clan-core ships.
    - HTTP(S) probing of `probes` URLs via Alloy's embedded blackbox
      exporter (probe_* metrics in mimir), feeding the http_status and
      cert_expiry alerts and the Endpoints section of the Overview.

    Assign to the same machine as the clan-core monitoring server role. The
    clients' extra collectors (vmstat/boottime/textfile) live in
    ./client-collectors.nix, wired via extraModules on the clan-core
    monitoring client role.
  '';
  manifest.categories = [ "Monitoring" ];
  manifest.exports.out = [
    "endpoints"
    "auth"
  ];

  roles.default = {
    description = "Caddy vhost, Pocket ID OIDC and declarative alerts for the clan-core monitoring server";

    interface =
      { lib, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "status.pin";
            description = "Clan-internal FQDN Caddy serves the monitoring stack on; exported as an endpoint so pki issues the cert and dm-dns the DNS. Must match the clan-core monitoring server's host setting.";
          };

          oidc = {
            issuer = lib.mkOption {
              type = lib.types.str;
              default = "https://id.pablo.tools";
              description = "OIDC issuer URL";
            };
            clientId = lib.mkOption {
              type = lib.types.str;
              default = "grafana";
              description = "OIDC client id registered by the Pocket ID reconciler";
            };
            providerName = lib.mkOption {
              type = lib.types.str;
              default = "Pocket ID";
              description = "Login button label";
            };
          };

          probes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "https://pablo.tools" ];
            description = "URLs probed every 2 minutes from this machine: HTTP 200 expected, TLS verified, certificate expiry recorded.";
          };

          servers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            example = [ "porree" ];
            description = "Machines the host_down alert watches, matched against the `instance` label (= machine name). Only always-on machines belong here; desktops and mobiles are powered off routinely and would page on every shutdown. Set from the `server`-tagged machines in inventory.nix.";
          };
        };
      };

    perInstance =
      { settings, mkExports, ... }:
      {
        exports = mkExports {
          endpoints.hosts = [ settings.host ];
          auth.client = {
            clientId = settings.oidc.clientId;
            clientName = "Grafana";
            redirectUris = [ "https://${settings.host}/grafana/login/generic_oauth" ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            public = false;
          };
        };

        nixosModule =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            oidc = settings.oidc;
            authFiles = config.clan.core.vars.generators."monitoring-caddy-auth".files;
            mimirPort = config.services.mimir.configuration.server.http_listen_port;
            lokiPort = config.services.loki.configuration.server.http_listen_port;
            grafanaPort = config.services.grafana.settings.server.http_port;
          in
          {
            # clan-core's mimir-auth/loki-auth htpasswd ("user:$2y$...")
            # converted to caddy's basic_auth format ("user $2y$...").
            clan.core.vars.generators."monitoring-caddy-auth" = {
              dependencies = [
                "mimir-auth"
                "loki-auth"
              ];
              files."mimir" = {
                owner = "caddy";
                group = "caddy";
              };
              files."loki" = {
                owner = "caddy";
                group = "caddy";
              };
              runtimeInputs = [ pkgs.gnused ];
              script = ''
                sed 's/:/ /' $in/mimir-auth/htpasswd > $out/mimir
                sed 's/:/ /' $in/loki-auth/htpasswd > $out/loki
              '';
            };

            systemd.services.caddy.restartTriggers = [
              authFiles."mimir".path
              authFiles."loki".path
            ];

            # Blackbox probing of settings.probes. Alloy loads every *.alloy in
            # /etc/alloy next to the clan-core client config; component names
            # carry a _blackbox suffix, the remote_write mirrors
            # ./client-collectors.nix (same credentials the clan client loads).
            # The exporter labels targets instance=<component id> and
            # job=integrations/blackbox/<name>. Unlike the prometheus blackbox
            # convention (instance=<url>), `instance` stays the probing machine
            # here so the probes don't show up as hosts in dashboards that list
            # label_values(instance); the URL goes into `target`.
            environment.etc."alloy/blackbox.alloy" = lib.mkIf (settings.probes != [ ]) {
              text = ''
                prometheus.exporter.blackbox "blackbox" {
                  config = ${
                    builtins.toJSON (
                      builtins.toJSON {
                        modules.http_2xx = {
                          prober = "http";
                          timeout = "5s";
                          http = {
                            valid_status_codes = [ 200 ];
                            fail_if_not_ssl = true;
                            preferred_ip_protocol = "ip4";
                          };
                        };
                      }
                    )
                  }
                ${lib.concatMapStrings (
                  url:
                  "  target {\n    name    = ${builtins.toJSON url}\n    address = ${builtins.toJSON url}\n    module  = \"http_2xx\"\n  }\n"
                ) settings.probes}
                }

                discovery.relabel "blackbox" {
                  targets = prometheus.exporter.blackbox.blackbox.targets
                  rule {
                    source_labels = ["__param_target"]
                    target_label  = "target"
                  }
                  rule {
                    target_label = "instance"
                    replacement  = ${builtins.toJSON config.networking.hostName}
                  }
                  rule {
                    target_label = "job"
                    replacement  = "integrations/blackbox"
                  }
                }

                prometheus.scrape "blackbox" {
                  targets = discovery.relabel.blackbox.output
                  forward_to = [prometheus.remote_write.mimir_blackbox.receiver]
                  scrape_interval = "2m"
                }

                prometheus.remote_write "mimir_blackbox" {
                  endpoint {
                    url = "https://${settings.host}/mimir/api/v1/push"
                    basic_auth {
                      username = "${config.clan.core.vars.generators.mimir-auth.files.username.value}"
                      password_file = sys.env("CREDENTIALS_DIRECTORY") + "/mimir-auth-password"
                    }
                  }
                }
              '';
            };

            # Reverse proxy; pki injects TLS for the .pin endpoint. mimir and
            # loki serve under their own path prefixes, so no prefix stripping
            # there; grafana serves at / and gets the /grafana prefix stripped
            # (its root_url is set by the clan-core monitoring service).
            services.caddy = {
              enable = true;
              virtualHosts."${settings.host}".extraConfig = ''
                redir / /grafana/ 302

                handle /mimir/* {
                  basic_auth {
                    import ${authFiles."mimir".path}
                  }
                  reverse_proxy 127.0.0.1:${toString mimirPort}
                }

                handle /loki/* {
                  basic_auth {
                    import ${authFiles."loki".path}
                  }
                  reverse_proxy 127.0.0.1:${toString lokiPort}
                }

                handle_path /grafana/* {
                  reverse_proxy 127.0.0.1:${toString grafanaPort}
                }
              '';
            };

            # The Caddy dashboard runs topk() over per-path/per-IP aggregations;
            # Loki counts the inner series against max_query_series (default
            # 500), which scanner traffic alone exceeds. Single-user instance.
            services.loki.configuration.limits_config.max_query_series = 5000;

            # Grafana's OIDC client secret is published by the Pocket ID
            # reconciler at /run/pocket-id-clients/<id>/secret (root:pocket-id-clients
            # 0640). Load it as a systemd credential and wait until the
            # reconciler has written it.
            systemd.services.grafana = {
              after = [ "pocket-id-clients.service" ];
              requires = [ "pocket-id-clients.service" ];
              serviceConfig.LoadCredential = [
                "oidc-secret:/run/pocket-id-clients/${oidc.clientId}/secret"
              ];
            };

            services.grafana = {
              settings = {
                # SCIM is enabled by default in recent Grafana versions and
                # intercepts OIDC user provisioning, causing "Failed to create
                # user: user not found". Disable it so the standard
                # generic_oauth flow can create users.
                feature_toggles.enableSCIM = false;

                # OIDC-only login: hide the username/password form, do not
                # auto-create local users via signup, redirect straight to the
                # OIDC provider.
                auth = {
                  disable_login_form = true;
                  signout_redirect_url = "${oidc.issuer}/api/oidc/end-session";
                  # Self-healing OIDC user linking: if user_auth has no row for
                  # the OIDC subject (e.g. fresh DB restore, or the IdP was
                  # rebuilt and the sub UUID changed), Grafana falls back to
                  # matching by email and auto-creates the user_auth link. Safe
                  # here because Pocket ID is a fully trusted IdP we control.
                  oauth_allow_insecure_email_lookup = true;
                };
                users = {
                  # Must be true so the OIDC provisioning path can create new
                  # users. disable_login_form = true (above) already prevents
                  # the local signup form from being rendered, so this only
                  # enables OIDC-initiated signup.
                  allow_sign_up = true;
                  auto_assign_org = true;
                  auto_assign_org_role = "Admin";
                };
                "auth.generic_oauth" = {
                  enabled = true;
                  name = oidc.providerName;
                  icon = "signin";
                  auto_login = true;
                  client_id = oidc.clientId;
                  client_secret = "$__file{/run/credentials/grafana.service/oidc-secret}";
                  scopes = "openid profile email groups";
                  empty_scopes = false;
                  auth_url = "${oidc.issuer}/authorize";
                  token_url = "${oidc.issuer}/api/oidc/token";
                  api_url = "${oidc.issuer}/api/oidc/userinfo";
                  login_attribute_path = "preferred_username";
                  email_attribute_path = "email";
                  name_attribute_path = "name";
                  groups_attribute_path = "groups";
                  # Pocket ID already restricts who can reach the client via
                  # its authorization policy, so anyone who successfully logs
                  # in is granted Admin in Grafana.
                  role_attribute_path = "'Admin'";
                  allow_sign_up = true;
                  use_pkce = true;
                };
              };

              # Dashboards next to clan-core's "clan" provider (providers is
              # a list, definitions concatenate). Files are read from the
              # store, so they are read-only in the UI.
              provision.dashboards.settings.providers = [
                {
                  name = "pinpox";
                  options.path = ./dashboards;
                }
              ];

              # Declarative alerting: rules evaluate in Grafana against the
              # mimir/loki datasources (uids pinned by the clan-core monitoring
              # service) and notify the Matrix room through the machine-local
              # matrix-hook (same webhook payload format as alertmanager).
              provision.alerting = {
                contactPoints.settings = {
                  apiVersion = 1;
                  contactPoints = [
                    {
                      orgId = 1;
                      name = "matrix";
                      receivers = [
                        {
                          uid = "matrix-hook";
                          type = "webhook";
                          settings.url = "http://127.0.0.1:11000/alert";
                        }
                      ];
                    }
                  ];
                };

                # Mirrors the old alertmanager route.
                policies.settings = {
                  apiVersion = 1;
                  policies = [
                    {
                      orgId = 1;
                      receiver = "matrix";
                      group_by = [ "instance" ];
                      group_wait = "30s";
                      group_interval = "2m";
                      repeat_interval = "24h";
                    }
                  ];
                };

                rules.settings = {
                  apiVersion = 1;
                  groups = [
                    {
                      orgId = 1;
                      name = "clan";
                      folder = "Alerts";
                      interval = "1m";
                      rules = import ./alert-rules.nix {
                        inherit lib;
                        inherit (settings) servers;
                      };
                    }
                  ];
                };
              };
            };
          };
      };
  };
}
