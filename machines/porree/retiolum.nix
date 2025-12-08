{
  config,
  retiolum,
  ...
}:
{

  imports = [ retiolum.nixosModules.retiolum ];

  networking.retiolum.ipv4 = "10.243.100.101";
  networking.retiolum.ipv6 = "42:0:3c46:b51c:b34d:b7e1:3b02:8d24";

  clan.core.vars.generators."retiolum" = {
    prompts.rsa_priv.persist = true;
    prompts.ed25519_priv.persist = true;
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = config.clan.core.vars.generators."retiolum".files."rsa_priv".path;
    ed25519PrivateKeyFile = config.clan.core.vars.generators."retiolum".files."ed25519_priv".path;
  };
}
