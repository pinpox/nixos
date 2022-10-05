{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.chromium;
in
{
  options.pinpox.programs.chromium.enable = mkEnableOption "chromium browser";

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      extensions = [
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # Ublock Origin
        { id = "gcbommkclmclpchllfjekcdonpmejbdp"; } # HTTPS everywhere
        { id = "mmpokgfcmbkfdeibafoafkiijdbfblfg"; } # Merge windows
        { id = "agldajbhchobfgjcmmigehfdcjbmipne"; } # Blank Dark New Tab
      ];
    };
  };
}
