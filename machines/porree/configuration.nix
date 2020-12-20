let domain = "nix.own";
in { config, pkgs, lib, modulesPath, ... }: {

  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  config = {

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gtk2";
    };

    services.qemuGuest.enable = true;

    # Setup Yubikey SSH and GPG
    services.pcscd.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    # Block anything that is not HTTP(s) or SSH.
    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 80 443 22 2812 ];
      allowedUDPPorts = [ 51820 ];
    };

    boot.growPartition = true;
    boot.kernelParams = [ "console=ttyS0" ];
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    programs.ssh.startAgent = false;

    environment.systemPackages = with pkgs; [
      ctags
      git
      gnumake
      go
      htop
      mmonit
      neovim
      nix-index
      nixfmt
      python
      ripgrep
      wget
    ];
    services.netdata = {
      enable = true;
    };

    services.monit = {

      enable = true;
      config = ''
## Start Monit in the background (run as a daemon):
set daemon  120             # check services at 2 minutes intervals
    with start delay 240    # optional: delay the first check by 4-minutes

## Set syslog logging
set logfile syslog

## Set global SSL options
set ssl {
    verify     : enable, # verify SSL certificates
}

check process nginx with pidfile /var/run/nginx/nginx.pid

check host pablo.tools with address pablo.tools
    if failed port 443 protocol https for 2 cycles then alert

check host pass.pablo.tools with address pass.pablo.tools
    if failed port 443 protocol https for 2 cycles then alert

check host cloud.pablo.tools with address cloud.pablo.tools
    if failed port 443 protocol https for 2 cycles then alert

check host 0cx.de with address 0cx.de
    if failed port 443 protocol https for 2 cycles then alert

check host irc.0cx.de with address irc.0cx.de
    if failed port 443 protocol https for 2 cycles then alert

check host mm.0cx.de with address mm.0cx.de
    if failed port 443 protocol https for 2 cycles then alert

check host pads.0cx.de with address pads.0cx.de
    if failed port 443 protocol https for 2 cycles then alert
    group kf

check host bins.0cx.de with address bins.0cx.de
    if failed port 443 protocol https for 2 cycles then alert
    group kf

check host megaclan3000.de with address megaclan3000.de
    if failed port 443 protocol https for 2 cycles then alert

## Set the list of mail servers for alert delivery. Multiple servers may be 
## specified using a comma separator. If the first mail server fails, Monit 
# will use the second mail server in the list and so on. By default Monit uses 
# port 25 - it is possible to override this with the PORT option.
#
# set mailserver mail.bar.baz,               # primary mailserver
#                backup.bar.baz port 10025,  # backup mailserver on port 10025
#                localhost                   # fallback relay
#
#
## By default Monit will drop alert events if no mail servers are available. 
## If you want to keep the alerts for later delivery retry, you can use the 
## EVENTQUEUE statement. The base directory where undelivered alerts will be 
## stored is specified by the BASEDIR option. You can limit the queue size 
## by using the SLOTS option (if omitted, the queue is limited by space
## available in the back end filesystem).
#
# set eventqueue
#     basedir /var/monit  # set the base directory where events will be stored
#     slots 100           # optionally limit the queue size
#
#
## Send status and events to M/Monit (for more informations about M/Monit 
## see http://mmonit.com/). By default Monit registers credentials with 
## M/Monit so M/Monit can smoothly communicate back to Monit and you don't
## have to register Monit credentials manually in M/Monit. It is possible to
## disable credential registration using the commented out option below. 
## Though, if safety is a concern we recommend instead using https when
## communicating with M/Monit and send credentials encrypted.
#
set mmonit http://monit:monit@status.pablo.tools:8080/collector
#     # and register without credentials     # Don't register credentials
#
#
## Monit by default uses the following format for alerts if the the mail-format
## statement is missing::
## --8<--
## set mail-format {
##   from:    Monit <monit@$HOST>
##   subject: monit alert --  $EVENT $SERVICE
##   message: $EVENT Service $SERVICE
##                 Date:        $DATE
##                 Action:      $ACTION
##                 Host:        $HOST
##                 Description: $DESCRIPTION
##
##            Your faithful employee,
##            Monit
## }
## --8<--
##
## You can override this message format or parts of it, such as subject
## or sender using the MAIL-FORMAT statement. Macros such as $DATE, etc.
## are expanded at runtime. For example, to override the sender, use:
#
# set mail-format { from: monit@foo.bar }
#
#
## You can set alert recipients whom will receive alerts if/when a 
## service defined in this file has errors. Alerts may be restricted on 
## events by using a filter as in the second example below.
#
# set alert sysadm@foo.bar                       # receive all alerts
#
## Do not alert when Monit starts, stops or performs a user initiated action.
## This filter is recommended to avoid getting alerts for trivial cases.
#
# set alert your-name@your.domain not on { instance, action }
#
#
## Monit has an embedded HTTP interface which can be used to view status of 
## services monitored and manage services from a web interface. The HTTP 
## interface is also required if you want to issue Monit commands from the
## command line, such as 'monit status' or 'monit restart service' The reason
## for this is that the Monit client uses the HTTP interface to send these
## commands to a running Monit daemon. See the Monit Wiki if you want to 
## enable SSL for the HTTP interface. 
#
set httpd port 2812 and
    use address 192.168.7.1  # only accept connection from localhost
    allow 192.168.7.2        # allow localhost to connect to the server and
    allow 192.168.7.3        # allow localhost to connect to the server and

###############################################################################
## Services
###############################################################################
##
## Check general system resources such as load average, cpu and memory
## usage. Each test specifies a resource, conditions and the action to be
## performed should a test fail.
#
check system $HOST
  if loadavg (1min) > 4 then alert
  if loadavg (5min) > 2 then alert
  if cpu usage > 95% for 10 cycles then alert
  if memory usage > 75% then alert
  if swap usage > 25% then alert
#
#    
## Check if a file exists, checksum, permissions, uid and gid. In addition
## to alert recipients in the global section, customized alert can be sent to 
## additional recipients by specifying a local alert handler. The service may 
## be grouped using the GROUP option. More than one group can be specified by
## repeating the 'group name' statement.

check filesystem root with path /dev/disk/by-label/nixos
  if space usage > 80% for 5 times within 15 cycles then alert


## Check a network link status (up/down), link capacity changes, saturation
## and bandwidth usage.

check network public with interface ens3
  if failed link then alert
  if changed link then alert
  if saturation > 90% then alert
  if download > 10 MB/s then alert
  if total upload > 1 GB in last hour then alert

## Check custom program status output.
#
#  check program myscript with path /usr/local/bin/myscript.sh
#    if status != 0 then alert
#
#
###############################################################################
## Includes
###############################################################################
##
## It is possible to include additional configuration parts from other files or
## directories.
#
#  include /etc/monit.d/*
#
'';
};


    networking.hostName = "porree";

    security.acme.acceptTerms = true;
    security.acme.email = "letsencrypt@pablo.tools";

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "128m";

      # Needed for bitwarden_rs, it seems to have trouble serving scripts for
      # the frontend without it.
      commonHttpConfig = ''
        server_names_hash_bucket_size 128;
      '';

      # No need to support plain HTTP, forcing TLS for all vhosts. Certificates
      # provided by Let's Encrypt via ACME. Generation and renewal is automatic
      # if DNS is set up correctly for the (sub-)domains.
      virtualHosts = {
        # Personal homepage and blog
        "pablo.tools" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/www/pablo-tools";
        };

        # Password manager (bitwarden) instance
        "pass.pablo.tools" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8222"; };
        };

        # Monitoring
        "status.pablo.tools" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:8080"; };
        };
      };
    };

    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      # Users allowed to run nix
      allowedUsers = [ "root" ];
    };

    # Enable Wireguard
    networking.wireguard.interfaces = {

      wg0 = {

        # Determines the IP address and subnet of the client's end of the
        # tunnel interface.
        ips = [ "192.168.7.0/24" ];

        listenPort = 51820;

        # Path to the private key file
        privateKeyFile = toString /var/src/secrets/wireguard/private;
        peers = [
          # kartoffel
          {
            publicKey = "759CaBnvpwNqFJ8e9d5PhJqIlUabjq72HocuC9z5XEs=";
            allowedIPs = [ "192.168.7.3" ];
          }
          # ahorn
          {
            publicKey = "ny2G9iJPBRLSn48fEmcfoIdYi3uHLbJZe3pH1F0/XVg=";
            allowedIPs = [ "192.168.7.2" ];
          }
        ];
      };
    };

    # Bitwarden_rs installed via nixpkgs.
    services.bitwarden_rs = {
      enable = true;
      config = {
        domain = "https://pass.pablo.tools:443";
        signupsAllowed = true;

        # The rocketPort option should match the value of the port in the reverse-proxy
        rocketPort = 8222;
      };

      # The environment file has to be provided manually as it includes private data.
      environmentFile = /var/lib/bitwarden_rs/envfile;
    };
  };
}
