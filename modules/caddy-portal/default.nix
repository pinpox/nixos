{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.caddy-portal;

  caddy-with-plugins = pkgs.caddy.override {
    buildGoModule = args: pkgs.buildGoModule (args // {
      # vendorSha256 = "sha256-445MYvi487ls6g6i30UTTK2/n2wbILgJEuwNUQE//ZE";
      patches = [ ./caddy.patch ];
      vendorHash = "sha256-rgbHvCX3lf5oKSCmkUjdhFtITFUMysC5dn5fhvSyYco=";
      runVend = true;
    });
  };
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

  options.pinpox.services.caddy-portal = {
    enable = mkEnableOption "Caddy authentication portal";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ caddy-with-plugins ];

    services.caddy = {
      enable = true;
      package = caddy-with-plugins;

      globalConfig = ''
        order authenticate before respond
        order authorize before basicauth

        security {
                oauth identity provider generic {
                    realm generic
                    driver generic
                    client_id {env.GENERIC_CLIENT_ID}
                    client_secret {env.GENERIC_CLIENT_SECRET}
                    scopes openid email profile
                    base_auth_url https://git.0cx.de
                    metadata_url https://git.0cx.de/.well-known/openid-configuration
                }

                authentication portal myportal {
                    crypto default token lifetime 3600
                    crypto key sign-verify {env.JWT_SHARED_KEY}
                    enable identity provider generic
                    cookie domain pablo.tools
                    ui {
                        links {
                            "My Identity" "/whoami" icon "las la-user"
                        }
                    }

                    transform user {
                        match realm generic
                        action add role authp/user
                        ui link "Test site 1" https://static-site-one.pablo.tools/ icon "las la-star"
                        ui link "Test site 2" https://static-site-two.pablo.tools/ icon "las la-star"
                    }

                    transform user {
                        match realm generic
                        match email git@pablo.tools
                        action add role authp/admin
                    }
                }

                authorization policy mypolicy {
                    set auth url https://auth.pablo.tools/oauth2/generic
                    crypto key verify {env.JWT_SHARED_KEY}
                    allow roles authp/admin authp/user
                    validate bearer header
                    inject headers with claims
                }
            }
      '';

      virtualHosts = {

        "auth.pablo.tools" = {
          extraConfig = ''
            authenticate with myportal
          '';
        };

        "static-site-one.pablo.tools" = {
          extraConfig = ''
            authorize with mypolicy
            encode gzip
            root * ${mkStaticTestSite "one"}/html
            file_server
          '';
        };

        "static-site-two.pablo.tools" = {
          extraConfig = ''
            authorize with mypolicy
            encode gzip
            root * ${mkStaticTestSite "two"}/html
            file_server
          '';
        };
      };
    };

    systemd.services.caddy.serviceConfig.Environment = [
      "GENERIC_CLIENT_ID=8f45a8ed-66aa-4c39-a580-1865d97fb1a3"
      "GENERIC_CLIENT_SECRET=gto_bm2sjk2rvvagq6okwjump4ojwk4mdx6pzkdgegzmfxl5qu7a3hca"
      "JWT_SHARED_KEY=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    ];

  };
}
