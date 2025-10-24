{
  pinpox-keys,
  ...
}:
{
  users.users.root.openssh.authorizedKeys.keyFiles = [ pinpox-keys ];

  # Allow to run nix
  nix.settings.allowed-users = [ "root" ];
}
