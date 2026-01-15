{
  pkgs,
  pinpox-keys,
  wrappers,
  ...
}:
let
  # Extend wrappers with custom modules by importing all subdirectories from pinpox-wraps
  myWrappers = wrappers // {
    wrapperModules =
      wrappers.wrapperModules
      // (builtins.listToAttrs (
        map (name: {
          inherit name;
          value = import (./pinpox-wraps + "/${name}") {
            wlib = wrappers.lib;
            lib = pkgs.lib;
          };
        }) (builtins.attrNames (builtins.readDir ./pinpox-wraps))
      ));
  };

  # Instantiate the wrapped ffmpeg with custom options
  # ffmpeg-wrapped =
  #   (myWrappers.wrapperModules.ffmpeg.apply {
  #     inherit pkgs;
  #     profile = "quality"; # or "fast"
  #     outputDir = "/home/pinpox/videos"; # customize as needed
  #   }).wrapper;

  # Example using a built-in wrapper module
  # mpv-wrapped =
  #   (myWrappers.wrapperModules.mpv.apply {
  #     inherit pkgs;
  #     scripts = [ pkgs.mpvScripts.mpris ];
  #   }).wrapper;

  # Chromium with extensions configured
  chromium-wrapped =
    (myWrappers.wrapperModules.chromium.apply {
      inherit pkgs;
      extensions = [
        # { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus - adds a paintbrush icon to toolbar
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # Ublock Origin
        { id = "gcbommkclmclpchllfjekcdonpmejbdp"; } # HTTPS everywhere
        { id = "mmpokgfcmbkfdeibafoafkiijdbfblfg"; } # Merge windows
        { id = "agldajbhchobfgjcmmigehfdcjbmipne"; } # Blank Dark New Tab
      ];
    }).wrapper;
in
{

  # Define a user account. Don't forget to set a password with 'passwd'.
  users = {

    # For Virtualbox
    extraGroups.vboxusers.members = [ "pinpox" ];

    # Shell is set to zsh for all users as default.
    defaultUserShell = pkgs.zsh;

    users.pinpox = {

      packages = [
        # ffmpeg-wrapped
        # mpv-wrapped
        # chromium-wrapped
      ];

      isNormalUser = true;
      home = "/home/pinpox";
      description = "Pablo Ovelleiro Corral";
      extraGroups = [
        "plugdev"
        "docker"
        "wheel"
        "networkmanager"
        "audio"
        "libvirtd"
        "tty"
        "dialout"
        "video"
        "storage-users"
      ];
      shell = pkgs.zsh;

      # Public ssh-keys that are authorized for the user. Fetched from github
      openssh.authorizedKeys.keyFiles = [ pinpox-keys ];
    };
  };

  # Allow to run nix
  nix.settings.allowed-users = [ "pinpox" ];
}
