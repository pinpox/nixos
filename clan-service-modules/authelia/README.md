# Authelia

Self-hosted OIDC identity provider with declarative users (aggregated from
the `users` clan service's `auth.user` exports), OIDC client aggregation
(from other clan services' `auth.client` exports), and access control.

## Usage

```nix
inventory.instances = {
  # Users with identity settings export auth.user automatically
  user-alice = {
    module.name = "users";
    roles.default.tags.all = { };
    roles.default.settings = {
      user = "alice";
      share = true;
      identity = {
        email = "alice@example.com";
        groups = [ "admins" "users" ];
      };
    };
  };

  # Authelia consumes auth.user exports for its user database
  # and auth.client exports for OIDC client registrations
  authelia = {
    module.name = "authelia";
    roles.default.machines.<hostname>.settings = {
      publicHost = "auth.example.com";
      cookies = [
        { domain = "example.com"; autheliaUrl = "https://auth.example.com"; }
      ];
      accessControlRules = [
        { domain = "*.example.com"; policy = "one_factor"; }
      ];
      # Per-client access policies (convention: ${clientId}-policy)
      clientPolicies = {
        grafana-policy = {
          default_policy = "deny";
          rules = [{ policy = "one_factor"; subject = "user:alice"; }];
        };
      };
    };
  };
};
```

## Roles

### default

The single Authelia server role. Consumes `auth` exports from the entire clan
inventory.

## OIDC client aggregation

Other clan services declare their OIDC client requirements via the `auth`
export type. Set `manifest.exports.out = [ "auth" ]` in your service and emit:

```nix
exports = mkExports {
  auth.client = {
    clientId = "my-app";
    clientName = "My Application";
    redirectUris = [ "https://my-app.example.com/callback" ];
    scopes = [ "openid" "profile" "email" ];
    public = false;
  };
  auth.varsGenerator = {
    share = true;
    files.client_secret = { };
    files.client_secret_hash = { };
    runtimeInputs = with pkgs; [ openssl authelia gnused coreutils ];
    script = ''
      mkdir -p $out
      openssl rand -hex 32 > $out/client_secret
      authelia crypto hash generate argon2 --password "$(cat $out/client_secret)" \
        | sed 's/^Digest: //' > $out/client_secret_hash
    '';
  };
};
```

The Authelia service auto-aggregates these into its
`identity_providers.oidc.clients` config. Each exported client is assigned
`authorization_policy = "${clientId}-policy"` — configure the matching
policy via the `clientPolicies` setting on the authelia instance.

## Per-user passwords

For each user from the `auth.user` exports, the service auto-generates a
random xkcdpass plus an argon2 hash. Read the plaintext via:

```
clan vars get <hostname> authelia-user-<username>/password
```

## Provider-agnostic design

The `auth` export schema is not Authelia-specific. A future Kanidm or
Keycloak clan service can consume the same `auth.user` and `auth.client`
exports, implementing its own mapping to native config. Consuming services
don't need to change when swapping IdPs.
