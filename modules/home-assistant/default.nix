{ config, pkgs, ... }: {

  # Needed for some integrations
  users.users.hass.extraGroups = [ "dialout" ];

  # Enable home-assistant
  services.home-assistant = {
    enable = true;

  # Disable the python checks, they take for ever
  package =
    (pkgs.home-assistant.overrideAttrs (old: { doCheck = false; }));

    config = {
      # default_config = {};
      # Basic settings
      homeassistant = {
        name = "Home";
        latitude = "32.8753367";
        longitude = "-117.2474053";
        elevation = 86;
        unit_system = "metric";
        time_zone = "Europe/Berlin";
        external_url = "https://home.pablo.tools";
      };

      # Discover some devices automatically
      discovery = { };

      # Show some system health data
      system_health = { };

      # Http settings
      http = {
        server_host = "127.0.0.1";
        use_x_forwarded_for = true;
        trusted_proxies = "127.0.0.1";
        server_port = 8123;
      };
      mqtt = {

        broker = "127.0.0.1";
        # certificate = "auto";
        # port = "8883";
        # username = "hass@thalheim.io";
        # password = "!secret ldap_password";
      };

      # Enables a map showing the location of tracked devies
      map = { };

      # Track the sun
      sun = { };

      # Enable mobile app
      mobile_app = { };

      # Enable configuration UI
      config = { };
      # # Make the ui configurable through ui-lovelace.yaml
      #   lovelace.mode = "yaml";
      #   lovelace.resources = [
      #     { url = "/local/vacuum-card.js";  type = "module"; }
      #   ];
      # Enable support for tracking state changes over time
      history = { };

      # Purge tracked history after 10 days
      recorder.purge_keep_days = 10;

      # View all events in o logbook
      logbook = { };

    };
  };
}
