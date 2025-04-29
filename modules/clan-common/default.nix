{
  config,
  pkgs,
  lib,
  ...
}:
{

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Default to depolying to the hostname
  clan.core.networking.targetHost = lib.mkDefault config.networking.hostName;

  clan.core.vars.settings.secretStore = "password-store";
  clan.core.vars.settings.passBackend = "passage";

  environment.systemPackages = [ pkgs.passage ];

  clan.core.vars.generators."mkpasswd-generator" = {
    files.test-password = { };
    runtimeInputs = with pkgs; [
      coreutils
      xkcdpass
    ];
    script = ''
      mkdir -p $out
      xkcdpass > $out/test-password
    '';
  };

  environment.etc."test-password".source =
    config.clan.core.vars.generators."mkpasswd-generator".files."test-password".path;

  nix.settings.trusted-substituters = [
    "https://cache.clan.lol"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28="
  ];

}
