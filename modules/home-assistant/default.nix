{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.home-assistant;
  # home-assistant-package = pkgs.home-assistant.override {
  #   extraComponents = [
  #     # Fritzbox network statistics
  #     "fritzbox_netmonitor"
  #   ];
  # };
in
{

  options.pinpox.services.home-assistant = {
    enable = mkEnableOption "Home-assitant server";
  };
  config = mkIf cfg.enable {

    lollypops.secrets.files."home-assistant/secrets.yaml" = {
      owner = "hass";
      path = "/var/lib/hass/secrets.yaml";
    };

    # List extraComponents here to be installed. The names can be found here:
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
    # Components listed here will be possible to add via the webUI if not
    # automatically picked up.

    # Needed for some integrations
    users.users.hass.extraGroups = [ "dialout" "keys" ];

    # Open port for mqtt
    networking.firewall = {

      allowedTCPPorts = [ 1883 ];

      # Expose home-assitant over wireguard
      interfaces.wg0.allowedTCPPorts = [
        8123
        9273 # Telegraf
      ];
    };

    # Enable mosquitto MQTT broker
    services.mosquitto = {
      enable = true;

      # Mosquitto is only listening on the local IP, traffic from outside is not
      # allowed.
      listeners = [{
        address = "192.168.2.84";
        port = 1883;
        users = {
          # No real authentication needed here, since the local network is
          # trusted.
          mosquitto = {
            acl = [ "readwrite #" ];
            password = "mosquitto";
          };
        };
      }];
    };

    # The prometheus integration of home-assistant is incomplete (e.g. missing
    # GPS lon/lat data), but the influx integration is fine. To have the
    # home-assistant states in prometheus to be able to create alerts and
    # graphs, telegraf is used to listen for influx formatted data form
    # home-assistant and export it as prometheus metrics.

    services.telegraf = {
      enable = true;
      extraConfig = {

        agent = {
          interval = "60s";
          ## Log at debug level.
          debug = true;
          ## Log only error level messages.
          quiet = false;
        };
        inputs = {
          influxdb_v2_listener = {
            # Start influxdb V2 listener on localhost only as we are running on
            # the same host as home-assistant.
            service_address = ":8086";
          };
        };

        outputs = {
          prometheus_client = {
            # Listen on the wireguard VPN IP. Localhost is not enough here, as
            # prometheus is hosted on a different machine.
            listen = "${config.pinpox.wg-client.clientIp}:9273";
            metric_version = 2;
          };
        };
      };
    };

    # Enable home-assistant service
    services.home-assistant = {
      enable = true;

      # Disable the python checks, they take for ever when building the
      # configuration
      # package = (home-assistant-package.overrideAttrs (old: {
      #   doInstallCheck = false;
      #   doCheck = false;
      # }));

      # Configuration generated to /var/lib/hass/configuration.yaml
      config =
        {

          ios = {
            actions = [
              # Toggle RGB strip
              {
                name = "Toggle RGB";
                background_color = "#24283B";
                label = {
                  text = "RGB-Kette";
                  color = "#E5E9F0";
                };
                icon = {
                  icon = "lightbulb-on";
                  color = "#FF5370";
                };
              }
              # Toggle Deckenlicht
              {
                name = "Toggle Deckenlicht";
                background_color = "#24283B";
                label = {
                  text = "Deckenlicht";
                  color = "#E5E9F0";
                };
                icon = {
                  icon = "lightbulb-on";
                  color = "#E5E9F0";
                };
              }
            ];
          };

          # https://home.pablo.tools/developer-tools/event
          # https://home.pablo.tools/config/automation/dashboard
          automation = [
            {
              id = "auto_deckenlicht_toggle";
              alias = "Deckenlicht Toggle";
              trigger = [{
                platform = "event";
                event_type = "ios.action_fired";
                event_data.actionName = "Toggle Deckenlicht";
              }];

              action = [{
                type = "toggle";
                device_id = "d71e3f9c22a777149793e6b126f27550";
                entity_id = "switch.deckenlicht";
                domain = "switch";
              }];
            }
            {
              id = "auto_rgb_toggle";
              alias = "RGB-Kette Toggle";
              trigger = [
                {
                  platform = "event";
                  event_type = "state_changed";
                  event_data.entity_id = "switch.lichterkette";
                }
                {
                  platform = "event";
                  event_type = "ios.action_fired";
                  event_data.actionName = "Toggle RGB";
                }
              ];

              condition = [
                {
                  condition = "template";
                  value_template = "{{ trigger.event.data.old_state.state != 'unavailable' }}";
                }
                {
                  condition = "template";
                  value_template = "{{ trigger.event.data.new_state.state != 'unavailable' }}";
                }
              ];

              action = [{
                type = "toggle";
                device_id = "d97c93bff99173ae0b3b20d640050508";
                entity_id = "light.rgb_strip_1";
                domain = "light";
              }];
            }
          ];

          # Provides some sane defaults and minimal dependencies
          default_config = { };

          shelly = { };

          zeroconf = {
            # default_interface = true;
          };
          # Basic settings for home-assistant
          homeassistant = {
            name = "Villa Kunterbunt";
            latitude = "!secret home-latitude";
            longitude = "!secret home-longitude";
            elevation = 86;
            unit_system = "metric";
            time_zone = "Europe/Berlin";
            external_url = "https://home.pablo.tools";
          };

          http = {
            use_x_forwarded_for = true;
            trusted_proxies = [ "192.168.7.1" ];
          };

          esphome = { };

          frontend = { };
          "map" = { };
          shopping_list = { };
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

          # Metrics for prometheus
          prometheus = { namespace = "hass"; };

          # Enable MQTT and configure it to use the mosquitto broker
          mqtt = {
            broker = "192.168.2.84";
            port = "1883";
            username = "mosquitto";
            password = "mosquitto";
          };

          logger.default = "info";
          # logger.default = "debug";

          influxdb = {
            api_version = 2;
            # host = "vpn.influx.pablo.tools";
            host = "localhost";
            port = "8086";
            max_retries = 10;
            ssl = false;
            verify_ssl = false;
            # Authorization is not used for telegraf, but home-assistant requires
            # passing these parameters
            token = "!secret influx-token";
            organization = "pinpox";
            bucket = "home_assistant";
          };

          # Enables a map showing the location of tracked devies
          map = { };

          # Track the sun
          sun = { };

          # Enable mobile app
          mobile_app = { };

          # Enable configuration UI
          # config = { };

          # Enable support for tracking state changes over time
          history = { };

          # Purge tracked history after 10 days
          recorder.purge_keep_days = 10;

          # View all events in o logbook
          logbook = { };
        };
    };
  };
}
