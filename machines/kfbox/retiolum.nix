{
  config,
  retiolum,
  ...
}:
{

  imports = [ retiolum.nixosModules.retiolum ];

  networking.retiolum = {
    ipv4 = "10.243.100.102";
    ipv6 = "42:0:3c46:3ae6:90a8:b220:e772:8a5c";
  };

  clan.core.vars.generators."retiolum" = {
    prompts.rsa_priv.persist = true;
    prompts.ed25519_priv.persist = true;
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = config.clan.core.vars.generators."retiolum".files."rsa_priv".path;
    ed25519PrivateKeyFile = config.clan.core.vars.generators."retiolum".files."ed25519_priv".path;
  };
}
