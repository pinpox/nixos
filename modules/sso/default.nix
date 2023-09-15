{ lib, pkgs, config, ... }:

with lib;
let

  cfg = config.pinpox.services.sso;

  ldap-user = types.submodule ({ config, ... }: {
    options = {

      username = mkOption {
        type = types.str;
        example = "myuser";
        description = "Username to login with";
      };

      email = mkOption {
        type = types.str;
        example = "mail@domain.tld";
        description = "E-mail for the user";
      };

      password = mkOption {
        type = types.mkOptionType {
          name = "Argon2Password";
          description = "Argon2 hashed password";
          # TODO this regex could be more precise
          check = x: types.str.check x && builtins.match "^.ARGON2.+" x != null;
          inherit (types.str) merge;
        };
        example = "{ARGON2}$argon2id$v=19$m=19456,t=2,p=1$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        description = ''
          Argon2 hased password for the user.
          Hash can be created with slappasswd from pkgs.openldap using:
          slappasswd -o module-load=argon2 -h '{ARGON2}' -s super-secret-password
        '';
      };

      groups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "developers" "superusers" ];
        description = ''
          List of groups this user belogs to.
          Groups will be created if the don't exist
        '';
      };
    };
  });

in
{

  imports = [
    ./authelia.nix
    ./openldap.nix
  ];

  options.pinpox.services.sso = {
    enable = mkEnableOption "Single Sign On Authentication Portal";

    authHost = mkOption {
      type = types.str;
      example = "0cx.de";
      default = "0cx.de";
      description = "Domain for authelia. will be used to create auth.authHost and whoami.authHost";
    };

    ldapAutheliaUser = mkOption {
      type = ldap-user;
      description = "Ldap user for the authelia user";
      example = {
        username = "authelia";
        email = "authelia@host.tld";
        password = "{ARGON2}$argon2id$v=19$m=19456,t=2,p=1$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        groups = [ ];
      };
    };

    ldapDomainTld = mkOption {
      type = types.str;
      default = "tools";
      example = "org";
      description = "Top level domain used for LDAP";
    };

    ldapDomainName = mkOption {
      type = types.str;
      default = "pablo";
      example = "nixos";
      description = "Domain name used for LDAP";
    };

    ldapRootCN = mkOption {
      type = types.str;
      default = "admin";
      example = "admin";
      description = "Name of the LDAP admin user";
    };

    ldapRootPW = mkOption {
      type = types.str;
      example = "{ARGON2}$argon2id$v=19$m=19456,t=2,p=1$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
      description = "Argon2 hashed password for the LDAP admin user";
    };

    ldapUsers = mkOption {
      type = types.listOf ldap-user;
      default = [ ];
      description = "List of LDAP users to provision. Do not include the authelia user here.";
      example = [{
        username = "myusername";
        email = "mail@domain.tld";
        password = "{ARGON2}$argon2id$v=19$m=19456,t=2,p=1$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        groups = [ "developers" "superusers" ];
      }];
    };
  };
  config = mkIf cfg.enable {

    services.caddy.virtualHosts =
      let

        whoami_config = ''
          forward_auth 127.0.0.1:9091 {
            uri /api/verify?rd=https://auth.${cfg.authHost}
            copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
          }

          header Content-Type text/html
          respond <<HTML
              <html>
                <head><title>Welcome!</title></head>
                <body style="margin: auto; width: 70%; padding: 10px;">
                <h1>Welcome, {rp.header.Remote-Name}!</h1>
                  <p>You have been sucessfully authenticated</p>
                  <table>
                    <tr><td>User</td><td>{rp.header.Remote-User}</td></tr>
                    <tr><td>Name</td><td>{rp.header.Remote-Name}</td></tr>
                    <tr><td>Email</td><td>{rp.header.Remote-Email}</td></tr>
                    <tr><td>Groups</td><td>{rp.header.Remote-Groups}</td></tr>
                  </table>
                </body>
              </html>
              HTML 200
        '';
      in
      {
        # A simple page to test athentication. Will be only reachable whten
        # logged in and show the current user
        "whoami.${cfg.authHost}".extraConfig = whoami_config;

        # Same as above, but only visible for users in the group "admin"
        "whoami-admin.${cfg.authHost}".extraConfig = whoami_config;
      };
  };
}
