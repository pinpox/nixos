{
  config,
  pkgs,
  lib,
  ...
}:
{

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

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

}
