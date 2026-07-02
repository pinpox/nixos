# Admin/user public keys, referenced from clan.nix.
# - age: recipients that encrypt each machine's age private key (yubikey-backed;
#   hardware only needed at decrypt/deploy time).
# - ssh: authorized keys installed for root on every machine.
{
  age = [
    "age1yubikey1qgj0qprapgs3z0h4yzuflwz3qpsqpm9hllu0hqsu2eekgd4re0vkvcuxjgs"
  ];

  ssh = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCTwBH0KIRE+9SC4n7hRAGAA7Lf/+PuCHFZzZDajy9lmYrcQdvD5SgP6Q5OikUxycniI0Zse5Xeitq9qkJNg6Lw="
  ];
}
