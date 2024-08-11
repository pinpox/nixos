{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.home-assistant;
in
{

  options.pinpox.services.home-assistant = {
    enable = mkEnableOption "Home-assitant server";
  };

  config = mkIf cfg.enable {

    # TODO workaround for https://github.com/NixOS/nixpkgs/pull/272576
    nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

    networking.firewall.trustedInterfaces = [ "wg0" ];

    lollypops.secrets.files."home-assistant/secrets.yaml" = {
      owner = "hass";
      path = "/var/lib/hass/secrets.yaml";
    };

    # https://nixos.wiki/wiki/Home_Assistant#Combine_declarative_and_UI_defined_automations
    systemd.tmpfiles.rules = [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    ];

    # Backup configuration dir - Config done via UI stateful
    pinpox.services.restic-client.backup-paths-offsite = [ config.services.home-assistant.configDir ];

    # Needed for some integrations
    users.users.hass.extraGroups = [
      "dialout"
      "keys"
    ];

    # Open port for mqtt
    networking.firewall = {

      allowedTCPPorts = [ 1883 ];

      # For home-assistant COIT
      interfaces.eno1.allowedUDPPorts = [ 5683 ];

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
      listeners = [
        {
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
        }
      ];
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
      customComponents = with pkgs.home-assistant-custom-components; [
        ntfy
        awtrix
        moonraker
      ];

      # List extraComponents here to be installed. The names can be found here:
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
      # Components listed here will be possible to add via the webUI if not
      # automatically picked up.
      extraComponents = [
        # "piper"
        # "whisper"
        "bthome"
        "nextcloud"
        "unifi_direct"
        "unifi"
        "esphome"
        "map"
        "openweathermap"
        "tasmota"
        "icloud"
      ];

      # Disable the python checks, they take for ever when building the
      # configuration
      # package = (home-assistant-package.overrideAttrs (old: {
      #   doInstallCheck = false;
      #   doCheck = false;
      # }));

      # Configuration generated to /var/lib/hass/configuration.yaml
      config = {

        /*
          # M5Stack Atom Echo
          # Example configuration.yaml
          homeassistant.media_dirs = {
            # media ="/var/lib/hass/media";
            media = "/var/lib/hass/tts";
            recording = "/var/lib/hass/recordings";
          };
        */

        sensor = [
          {
            name = "random_joke";
            platform = "rest";
            json_attributes = "joke";
            resource = "https://icanhazdadjoke.com/";
            scan_interval = "3600";
            headers.Accept = "application/json";
          }
        ];

        conversation.intents.TellJoke = [ "Witz" ];

        intent_script.TellJoke = {
          speech.text = ''{{ state_attr("sensor.random_joke", "joke") }}'';
          action = {
            service = "homeassistant.update_entity";
            entity_id = "sensor.random_joke";
          };
        };

        assist_pipeline = { };

        notify = [
          {
            name = "ntfy";
            platform = "rest";
            method = "POST_JSON";
            authentication = "basic";
            username = "nfty";
            password = "!nfty-pass";
            data.topic = "homeassistant";
            title_param_name = "title";
            message_param_name = "message";
            resource = "https://push.pablo.tools";
          }
        ];

        device_tracker =
          let
            # Unifi APs
            ap-ips = [
              "192.168.2.110"
              "192.168.2.111"
              "192.168.2.126"
            ];
          in
          map (host: {
            inherit host;
            platform = "unifi_direct";
            username = "pinpox";
            password = "!unifi-ap-ssh";
          }) ap-ips;

        weather = { };
        sun = { };
        # icloud = { };

        intent_script.FindIphone = {
          # speech.text = "Notified pinpox";
          action = {
            service = "icloud.play_sound";
            data_template.account = "apple@pablo.tools";
            data_template.device_name = "Apfeltasche (2)";
          };
        };

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
            {
              name = "Toggle Bulbbox";
              background_color = "#24283B";
              label = {
                text = "Bulbbox";
                color = "#E5E9F0";
              };
              icon = {
                icon = "lightbulb-on";
                color = "#E5E9F0";
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

        "automation ui" = "!include automations.yaml";

        "automation manual" = [
          {
            id = "rackmount_button1";
            mode = "single";
            alias = "Rack Button 1";
            description = "Toggle Lightbulb Box";
            trigger = [
              {
                type = "turned_off";
                platform = "device";
                device_id = "f0a65ba3fc5a542ec83a1fc22a36d2e2";
                entity_id = "42b59835bb83659d01cc2ab0da4c429e";
                domain = "binary_sensor";
              }
            ];
            action = [
              {
                type = "toggle";
                device_id = "a8c96a8429ae8a7a13c058f79c886684";
                entity_id = "switch.lightbulb_box";
                domain = "switch";
              }
            ];
          }
          {
            id = "rackmount_button2";
            mode = "single";
            alias = "Rack Button 2";
            description = "Toggle RGB Strip";
            trigger = [
              {
                type = "turned_off";
                platform = "device";
                device_id = "f0a65ba3fc5a542ec83a1fc22a36d2e2";
                entity_id = "binary_sensor.button_2";
                domain = "binary_sensor";
              }
            ];
            action = [
              {
                type = "toggle";
                device_id = "d97c93bff99173ae0b3b20d640050508";
                entity_id = "light.rgb_strip_1";
                domain = "light";
              }
            ];
          }

          {
            id = "rackmount_button3";
            mode = "single";
            alias = "Rack Button 3";
            description = "Toggle Ceiling light";
            trigger = [
              {
                type = "turned_off";
                platform = "device";
                device_id = "f0a65ba3fc5a542ec83a1fc22a36d2e2";
                entity_id = "binary_sensor.button_3";
                domain = "binary_sensor";
              }
            ];
            action = [
              {
                type = "toggle";
                device_id = "d71e3f9c22a777149793e6b126f27550";
                entity_id = "switch.deckenlicht";
                domain = "switch";
              }
            ];
          }
          {
            id = "auto_deckenlicht_toggle";
            alias = "Deckenlicht Toggle";
            trigger = [
              {
                platform = "event";
                event_type = "ios.action_fired";
                event_data.actionName = "Toggle Deckenlicht";
              }
            ];

            action = [
              {
                type = "toggle";
                device_id = "d71e3f9c22a777149793e6b126f27550";
                entity_id = "switch.deckenlicht";
                domain = "switch";
              }
            ];
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

            action = [
              {
                type = "toggle";
                device_id = "d97c93bff99173ae0b3b20d640050508";
                entity_id = "light.rgb_strip_1";
                domain = "light";
              }
            ];
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

        frontend = { };
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
        # tasmota = { };

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
        prometheus = {
          namespace = "hass";
        };

        # Enable MQTT
        mqtt = { };

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
