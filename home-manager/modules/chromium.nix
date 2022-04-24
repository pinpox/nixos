{ config, pkgs, lib, ... }: {
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # Ublock Origin
      { id = "gcbommkclmclpchllfjekcdonpmejbdp"; } # HTTPS everywhere
      { id = "mmpokgfcmbkfdeibafoafkiijdbfblfg"; } # Merge windows
    ];
  };
}
