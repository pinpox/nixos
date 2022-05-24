{ config, pkgs, lib, nur, utils, ... }:
with lib;
let
  cfg = config.pinpox.programs.neomutt;
in
{
  options.pinpox.programs.neomutt.enable = mkEnableOption "neomutt mail client";

  config = mkIf cfg.enable {
    programs = {
      neomutt = {
        enable = true;
        # TODO
      };
    };
  };
}
