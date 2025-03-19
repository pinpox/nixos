{
  config,
  retiolum,
  ...
}:
{

  imports = [ retiolum.nixosModules.retiolum ];

  networking.retiolum = {
    ipv4 = "10.243.100.100";
    ipv6 = "42:0:3c46:519d:1696:f464:9756:8727";
  };

  networking.retiolum.nodename = "ahorn";

  clan.core.vars.generators."retiolum" = {
    prompts.rsa_priv.persist = true;
    prompts.ed25519_priv.persist = true;
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = config.clan.core.vars.generators."retiolum".files."rsa_priv".path;
    ed25519PrivateKeyFile = config.clan.core.vars.generators."retiolum".files."ed25519_priv".path;
  };
}
