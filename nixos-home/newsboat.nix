{ config, pkgs, lib, ... }:
let
  splitString = str:
    builtins.filter builtins.isString (builtins.split "\n" str);
in {
  programs.newsboat = {
    enable = true;
    autoReload = true;
    urls = [
      # https://hackaday.com/blog/feed/
      {
        title = "nixOS mobile";
        tags = [ "nixos" "nix" ];
        url = "https://mobile.nixos.org/index.xml";
      }
      {
        title = "r/NixOS";
        tags = [ "nixos" "nix" "reddit" ];
        url = "https://www.reddit.com/r/NixOS.rss";
      }
      {
        title = "NixOS weekly";
        tags = [ "nixos" "nix" ];
        url = "https://weekly.nixos.org/feeds/all.rss.xml";
      }
    ] ++ (map (x: {
      url = x;
      tags = [ "rss" ];
    }) (splitString (builtins.readFile ./newsboat/rss.txt)))

      ++ (map (x: {
        url = x;
        tags = [ "podcast" ];
      }) (splitString (builtins.readFile ./newsboat/podcast.txt)))

      ++ (map (x: {
        url = x;
        tags = [ "youtube" ];
      }) (splitString (builtins.readFile ./newsboat/youtube.txt)));
  };

}
