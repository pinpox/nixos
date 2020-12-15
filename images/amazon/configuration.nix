{ pkgs, ... }: {

  config = {

    programs.ssh.startAgent = false;

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      startWhenNeeded = true;
      challengeResponseAuthentication = false;
    };

    environment.systemPackages = with pkgs; [
      neovim
      git
      zsh
      gnumake
      youtube-dl
    ];

    users = {
      users.root = {
        openssh.authorizedKeys.keyFiles = [
          (builtins.fetchurl { url = "https://github.com/MayNiklas.keys"; })
          (builtins.fetchurl { url = "https://github.com/pinpox.keys"; })
        ];
      };
    };
  };
}

