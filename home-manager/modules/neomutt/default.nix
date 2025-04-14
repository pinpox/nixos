{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.neomutt;
in
{
  options.pinpox.programs.neomutt.enable = mkEnableOption "neomutt mail client";

  config = mkIf cfg.enable {
    programs.neomutt = {
      enable = true;
      sidebar = {
        enable = true;
      };
      extraConfig = ''
        set imap_user = "pablo1@mailbox.org"
        set imap_pass = "`pass mailbox.org/pablo1@mailbox.org`"
      '';
    };
  };
}
