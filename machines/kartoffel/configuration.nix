# Configuration for kartoffel

{ config, pkgs, inputs, ... }: {

  # Define the hostname
  networking.hostName = "kartoffel";

  # Video driver for nvidia graphics card
  services.xserver.videoDrivers = [ "nvidia" ];

  boot = {
    # Use GRUB2 as EFI boot loader.
    loader.grub.enable = true;
    loader.grub.version = 2;
    loader.grub.device = "nodev";
    loader.grub.efiSupport = true;
    loader.grub.useOSProber = true;
    loader.efi.canTouchEfiVariables = true;

    blacklistedKernelModules = [ "nouveau" ];

    # Encrypted drive to be mounted by the bootloader. Path of the device will
    # have to be changed for each install.
    initrd.luks.devices = {
      root = {
        # Get UUID from blkid /dev/sda2
        device = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
        preLVM = true;
        allowDiscards = true;
      };
    };

    # /tmp is cleaned after each reboot
    cleanTmpDir = true;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # Users allowed to run nix
    allowedUsers = [ "root" ];
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
set mmonit http://monit:monit@localhost:8080/collector
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # borgbackup
    arandr
    ctags
    docker
    docker-compose
    git
    gnumake
    go
    killall
    neovim
    nixfmt
    nodejs
    openvpn
    python
    ripgrep
    ruby
    wget
  ];

  programs.dconf.enable = true;

  networking.firewall = {
    enable = true;
    interfaces.wg0.allowedTCPPorts = [ 2812 ];
  };

  # Enable Wireguard
  networking.wireguard.interfaces = {

    wg0 = {

      # Determines the IP address and subnet of the client's end of the
      # tunnel interface.
      ips = [ "192.168.7.3/24" ];

      # Path to the private key file
      privateKeyFile = toString /var/src/secrets/wireguard/private;
      peers = [{
        # Public key of the server (not a file path).
        publicKey = "XKqEk5Hsp3SRVPrhWD2eLFTVEYb9NYRky6AermPG8hU=";

        # Don't forward all the traffic via VPN, only particular subnets
        allowedIPs = [ "192.168.7.0/24" ];

        # Server IP and port.
        endpoint = "vpn.pablo.tools:51820";

        # Send keepalives every 25 seconds. Important to keep NAT tables
        # alive.
        persistentKeepalive = 25;
      }];
    };
  };

  nixpkgs = { config.allowUnfree = true; };

  # Clean up old generations after 30 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
