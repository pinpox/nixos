{ config, pkgs, lib, ... }: {

  nixpkgs.config.packageOverrides = pkgs: rec {
    mmonit = pkgs.callPackage ../packages/mmonit {};
    mmonit-start = pkgs.writeScriptBin "mmonit-start" ''
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

    mmonit-stop = pkgs.writeScriptBin "mmonit-start" ''
  #!${pkgs.stdenv.shell}
      exec ${mmonit}/bin/mmonit stop
    '';
  };

  environment.systemPackages = with pkgs; [ mmonit mmonit-start mmonit-stop];

  users.users.mmonit = {
    isNormalUser = false;
    home = "/var/lib/mmonit";
    description = "M/monit system user";
    extraGroups = [ "mmonit" ];
  };

  users.groups.mmonit = {
    name = "mmonit";
  };

# Usage: mmonit [options] {arguments}
# Options are as follows:
#   -c file   Specify an alternate server.xml control file
#   -r dir    Specify an alternate m/monit home directory
#   -p dir    Specify a directory for the mmonit.pid lock file
#   -w dir    Specify an alternate temporary working directory. Default is /tmp
#   -i        Do not start mmonit in daemon mode. (Run in foreground)
#   -t        Run syntax check for configuration files
#   -l        Print license information
#   -v        Print version number
#   -d        Diagnostic mode, work noisy (dump core on error)
#   -h        Print this text
# Arguments are as follows:
#   start     Start mmonit (default)
#   stop      Stop mmonit


  networking.firewall = {
    enable = true;
    allowedTCPPorts  =[ 8080 ];
  };

systemd.services.mmonit = {
  description = "M/monit Monitoring";
  serviceConfig = {
     # Type = "forking";
     # ExecStart = "mmonit-start";
     # PermissionsStartOnly=true
     preStart = "+/run/current-system/sw/bin/mmonit-start";
     ExecStart = "${pkgs.mmonit}/bin/mmonit -r /var/lib/mmonit -i start";
     # ExecStop = "mmonit-stop";
     Restart = "on-failure";
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.mmonit.enable = true;
}
