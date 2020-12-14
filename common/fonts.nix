{ config, pkgs, lib, ... }: {
  # Install some fonts system-wide, especially "Source Code Pro" in the
  # Nerd-Fonts pached version with extra glyphs.
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
      noto-fonts-emoji
      corefonts
    ];
  };
}
