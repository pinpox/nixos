# Punchcard instances (clan-community module). Auto-merged into inventory.nix's `instances`.
{ ... }:
{
  punchcard1 = {
    module.input = "clan-community";
    module.name = "punchcard";
    roles.default.machines.clementine.settings = {
      publicHost = "punchcard.megaclan3000.de";
      environmentFile = "/run/secrets/punchcard/envfile";
    };
    roles.default.extraModules = [
      (
        { pinpox-utils, ... }:
        {
          clan.core.vars.generators."punchcard" = pinpox-utils.mkEnvGenerator [
            "OIDC_ISSUER_URL"
            "OIDC_CLIENT_ID"
            "OIDC_CLIENT_SECRET"
          ];
        }
      )
    ];
  };

  punchcard2 = {
    module.input = "clan-community";
    module.name = "punchcard";
    roles.default.machines.clementine.settings = {
      publicHost = "punchcard2.megaclan3000.de";
      port = 8100;
      environmentFile = "/run/secrets/punchcard2/envfile";
    };
    roles.default.extraModules = [
      (
        { pinpox-utils, ... }:
        {
          clan.core.vars.generators."punchcard2" = pinpox-utils.mkEnvGenerator [
            "OIDC_ISSUER_URL"
            "OIDC_CLIENT_ID"
            "OIDC_CLIENT_SECRET"
          ];
        }
      )
    ];
  };
}
