{ config, pkgs, ... }:
let

  # List extraComponents here to be installed. The names can be found here:
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
  # Components listed here will be possible to add via the webUI if not
  # automatically picked up.

  home-assistant-package = pkgs.home-assistant.override {
    extraComponents = [
      # Fritzbox network statistics
      # "fritzbox_netmonitor"

      # Wifi led strip controller
      # "flux_led"

      # Not sure if needed with default_config?
      "lovelace"
    ];
  };
in {

  # Needed for some integrations
  users.users.hass.extraGroups = [ "dialout" ];

  # Open port for mqtt
  networking.firewall.allowedTCPPorts = [ 1883 8123 ];
  networking.firewall.allowedUDPPorts = [ 1900 1901 137 136 138 ];

  # Enable mosquitto MQTT broker
  services.mosquitto = {
    enable = true;

    # Mosquitto is only listening on the local IP, traffic from outside is not
    # allowed.
    host = "192.168.2.84";
    port = 1883;
    users = {
      # No real authentication needed here, since the local network is
      # trusted.
      mosquitto = {
        acl = [ "pattern readwrite #" ];
        password = "mosquitto";
      };
    };
  };

  # Enable home-assistant service
  services.home-assistant = {
    enable = true;

    # Disable the python checks, they take for ever when building the
    # configuration
    package = (home-assistant-package.overrideAttrs (old: {
      doInstallCheck = false;
      doCheck = false;
    }));

    # Configuration generated to /var/lib/hass/configuration.yaml
    config = {
      # Provides some sane defaults and minimal dependencies
      default_config = { };

      # HTTP only listening on localhost, since it will be behind nginx

      zeroconf = { default_interface = true; };
      # Basic settings for home-assistant
      homeassistant = {
        name = "Villa Kunterbunt";
        latitude = "32.8753367";
        longitude = "-117.2474053";
        elevation = 86;
        unit_system = "metric";
        time_zone = "Europe/Berlin";
        external_url = "https://home.pablo.tools";
      };

      frontend = { };
      "map" = { };
      shopping_list = { };
      logger.default = "info";
      sun = { };
      config = { };
      mobile_app = { };
      cloud = { };
      system_health = { };

      # Discover some devices automatically
      # discovery = { };

      # Show some system health data
      system_health = { };

      # Enable support for tamota devices
      tasmota = { };

      # Led strip wifi controller, component needs to be listed explicitely in
      # extraComponents above
      # light = [{
      #   platform = "flux_led";
      #   automatic_add = true;
      #   devices = { "192.168.2.106" = { name = "flux_led"; }; };
      # }];

      # Fritzbox network traffic stats
      # sensor = [{ platform = "fritzbox_netmonitor"; }];

      # Enable MQTT and configure it to use the mosquitto broker
      mqtt = {
        broker = "192.168.2.84";
        port = "1883";
        username = "mosquitto";
        password = "mosquitto";
      };

      # Enables a map showing the location of tracked devies
      # map = { };

      # Track the sun
      # sun = { };

      # Enable mobile app
      # mobile_app = { };

      # Enable configuration UI
      # config = { };

      # Enable support for tracking state changes over time
      # history = { };

      # Purge tracked history after 10 days
      # recorder.purge_keep_days = 10;

      # View all events in o logbook
      # logbook = { };
    };
  };
}
