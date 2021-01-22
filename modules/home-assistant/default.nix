{ config, pkgs, ... }: {

  # Enable home-assistant
  services.home-assistant = {
    enable = true;

    config = {
    default_config = {};
      # Basic settings
      homeassistant = {
        name = "Home";
        latitude = "32.8753367";
        longitude = "-117.2474053";
        elevation = 22;
        unit_system = "metric";
        time_zone = "Europe/Stockholm";
        external_url = "https://home.pablo.tools";
      };

      # # Discover some devices automatically
      # discovery = { };

      # # Show some system health data
      # system_health = { };

      # Http settings
      http = {
        server_host = "127.0.0.1";
        use_x_forwarded_for = true;
        trusted_proxies = "127.0.0.1";
        server_port = 8123;
      };

      # Track the sun
      # sun = { };

    };
  };
}
