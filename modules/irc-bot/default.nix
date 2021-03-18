{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.go-karma-bot;

go-karma-bot = pkgs.buildGoModule rec {

  pname = "go-karma-bot";
  version = "0.1";

  src = pkgs.fetchFromGitHub {
    owner = "pinpox";
    repo = "go-karma-bot";
    # rev = "v${version}";
    rev = "main";
    sha256 =  "sha256-KSaBwsjam3hqhSzwCTur9pUQR7EXUrYhVM0Eve9157k=";
  };


  vendorSha256 = "sha256-si9G6t7SULor9GDxl548WKIeBe4Ik21f+lgNN+9bwzg=";
  subPackages = [ "." ];

  # deleteVendor = true;

  # runVend = true;

  meta = with lib; {
    description = "IRC Bot that tracks karma of things";
    homepage = "https://github.com/pinpox/go-karma-bot";
    license = licenses.gpl3;
    maintainers = with maintainers; [ pinpox ];
    platforms = platforms.linux;
  };
};



in {

  options.pinpox.services.go-karma-bot = {
    enable = mkEnableOption "the irc bot.";
  };

  config = mkIf cfg.enable {

    # Here goes the config
    # environment.systemPackages = with pkgs; [go-karma-bot];


  users.users.go-karma-bot= {
    isNormalUser = false;
    home = "/var/lib/go-karma-bot";
    description = "go-karma-bot system user";
    extraGroups = [ "go-karma-bot" ];
    createHome = true;
  };

  users.groups.go-karma-bot= { name = "go-karma-bot"; };

   systemd.services.go-karma-bot= {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start the IRC karma-bot";
      serviceConfig = {
        # Type = "forking";

      EnvironmentFile = [ "/var/src/secrets/go-karma-bot/envfile" ];

        WorkingDirectory = "/var/lib/go-karma-bot";
        User = "go-karma-bot";
        ExecStart = ''${go-karma-bot}/bin/go-karma-bot'';

    #mmonit-init = pkgs.writeScriptBin "mmonit-init" ''
    #  #!${pkgs.stdenv.shell}
    #  FILE=/var/lib/mmonit/.created
    #  if [ ! -f "$FILE" ]; then
    #    echo "$FILE not found, creating new mmonit home"
    #    mkdir -p /var/lib/mmonit
    #    cp -r ${mmonit}/* /var/lib/mmonit
    #    chown -R mmonit:mmonit /var/lib/mmonit
    #    chmod -R 600 /var/lib/mmonit
    #    touch /var/lib/mmonit/.created
    #  fi
    #'';
      # preStart = "+/run/current-system/sw/bin/mmonit-init";
      };
   };
  };
}
