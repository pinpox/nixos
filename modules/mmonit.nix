{ config, pkgs, lib, ... }: {

  nixpkgs.config.packageOverrides = pkgs: rec {
    mmonit = pkgs.callPackage ../packages/mmonit {};
    mmonit-init = pkgs.writeScriptBin "mmonit-init" ''
      #!${pkgs.stdenv.shell}
      FILE=/var/lib/mmonit/.created
      if [ ! -f "$FILE" ]; then
        echo "$FILE not found, creating new mmonit home"
        mkdir -p /var/lib/mmonit
        cp -r ${mmonit}/* /var/lib/mmonit
        chown -R mmonit:mmonit /var/lib/mmonit
        chmod -R 600 /var/lib/mmonit
        touch /var/lib/mmonit/.created
      fi
    '';
  };

  environment.systemPackages = with pkgs; [ mmonit mmonit-init ];

  users.users.mmonit = {
    isNormalUser = false;
    home = "/var/lib/mmonit";
    description = "M/monit system user";
    extraGroups = [ "mmonit" ];
  };

  users.groups.mmonit = {
    name = "mmonit";
  };


  networking.firewall = {
    enable = true;

    interfaces.wg0.allowedTCPPorts = [ 8080 ];
  };

systemd.services.mmonit = {
  description = "M/monit Monitoring";
  serviceConfig = {
     # Type = "forking";
     preStart = "+/run/current-system/sw/bin/mmonit-init";
     ExecStart = "${pkgs.mmonit}/bin/mmonit -r /var/lib/mmonit -i start";
     ExecStop = "${pkgs.mmonit}/bin/mmonit stop";
     Restart = "on-failure";
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.mmonit.enable = true;
}
