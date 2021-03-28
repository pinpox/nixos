{

  hosts = [
    {
      hostname = "kartoffel";
      networking = { wg0-ip = "192.168.7.3"; };
    }
    {
      hostname = "ahorn";
      networking = { wg0-ip = "192.168.7.2"; };
    }
    {
      hostname = "birne";
      networking = { wg0-ip = "192.168.7.4"; };
    }
    {
      hostname = "porree";
      networking = {
        wg0-ip = "192.168.7.1";
        public-ip = "94.16.114.42";
      };
    }
    {
      hostname = "kfbox";
      networking = {
        wg0-ip = "192.168.7.5";
        public-ip = "46.38.242.17";
      };
    }
    {
      hostname = "mega";
      networking = {
        wg0-ip = "192.168.7.6";
        public-ip = " 5.181.48.121";
      };
    }
    {
      hostname = "kfbox-old";
      networking = {
        public-ip = "93.177.66.52";
      };
    }
  ]

# VPN protected services
# 192.168.7.1 vpn.alerts.pablo.tool
