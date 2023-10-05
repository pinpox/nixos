{ config, lib, pkgs, caddy-patched, ... }:
with lib;
let cfg = config.pinpox.services.caddy-security;
in
{

  options.pinpox.services.caddy-security = {
    enable = mkEnableOption "Caddy security portal config";

    domain = mkOption {
      type = types.str;
      description = "Domain protetected by this caddy instance";
      example = "0cx.de";
    };

    host = mkOption {
      type = types.str;
      default = "auth.${cfg.domain}";
      description = "Host serving caddy-security portal";
      example = "auth.0cx.de";
    };

    authURL = mkOption {
      type = types.str;
      default = "https://${cfg.host}/oauth2/generic";
      description = "Authentication URL";
      example = "https://auth.mydomain.tld/oauth2/generic";
    };

    openID = {

      name = mkOption {
        type = types.str;
        default = "Dex";
        description = "Name of the OpenID provider, shown in the UI";
        example = "GitHub";
      };

      host = mkOption {
        type = types.str;
        default = "login.${cfg.openID.domain}";
        description = "Host of the OpenID provider";
        example = "login.mydomain.tld";
      };

      metadataUrl = mkOption {
        type = types.str;
        default = "https://${cfg.openID.host}/.well-known/openid-configuration";
        description = "Metadata URL of the OpenID Host";
        example = "https://myhost.tld/.well-known/openid-configuration";
      };
    };
  };

  config = mkIf cfg.enable {

    # Contains: JWT_SHARED_KEY GENERIC_CLIENT_ID GENERIC_CLIENT_SECRET
    lollypops.secrets.files."caddy/envfile" = { };

    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      EnvironmentFile = [ config.lollypops.secrets.files."caddy/envfile".path ];
    };

    services.caddy = {

      enable = true;
      package = caddy-patched.packages.x86_64-linux.caddy;

      globalConfig = ''
        order authenticate before respond
        order authorize before basicauth

        security {

          oauth identity provider generic {
            icon "${cfg.openID.name}" "las la-key la-2x" "white" "black" priority 100
            delay_start 5
            retry_attempts 5
            retry_interval 10
            realm generic
            driver generic
            client_id {env.GENERIC_CLIENT_ID}
            client_secret {env.GENERIC_CLIENT_SECRET}
            scopes openid email profile groups federated:id
            base_auth_url https://${cfg.openID.host}
            metadata_url ${cfg.openID.metadataUrl}
          }

          authentication portal myportal {
            crypto default token lifetime 3600
            crypto key sign-verify {env.JWT_SHARED_KEY}
            cookie domain ${cfg.domain}
            enable identity provider generic
            ui {
              links {
                "My Identity" "/whoami" icon "las la-user"
              }
            }

            transform user {
              match realm generic
              action add role authp/user
              ui link "Test site 1 (user)" https://static-site-one.${cfg.domain}/ icon "las la-star"
            }

            transform user {
              match realm generic
              match sub CgZwaW5wb3gSBmdpdGh1Yg # github ID of pinpox
              action add role authp/admin
              ui link "Test site 2 (admin)" https://static-site-two.${cfg.domain}/ icon "las la-star"
            }
          }

          authorization policy pol-user {
            set auth url ${cfg.authURL}
            crypto key verify {env.JWT_SHARED_KEY}
            allow roles authp/admin authp/user
            validate bearer header
            inject headers with claims
          }

          authorization policy pol-admin {
            set auth url ${cfg.authURL}
            crypto key verify {env.JWT_SHARED_KEY}
            allow roles authp/admin
            validate bearer header
            inject headers with claims
          }
        }
      '';

      virtualHosts =
        let
          mkStaticTestSite = num: pkgs.writeTextFile {
            name = "index.html";
            text = ''
              <!DOCTYPE html>
              <html>
                <head> <meta charset="UTF-8"> </head>
                <body>
                <h1>Hello World (${num})!</h1>
                <p>This is the site number ${num}</p>
                </body>
              </html>
            '';
            executable = false;
            destination = "/html/index.html";
          };

        in
        {

          "${cfg.host}".extraConfig = "authenticate with myportal";

          "static-site-one.${cfg.domain}" = {
            extraConfig = ''
              authorize with pol-user
              encode gzip
              root * ${mkStaticTestSite "one"}/html
              file_server
            '';
          };

          "static-site-two.${cfg.domain}" = {
            extraConfig = ''
              authorize with pol-admin
              encode gzip
              root * ${mkStaticTestSite "two"}/html
              file_server
            '';
          };
        };
    };
  };
}
