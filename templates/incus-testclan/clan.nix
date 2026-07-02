let
  keys = import ./keys.nix;
in
{
  # Ensure this is unique among all clans you want to use.
  meta.name = "testclan";
  meta.domain = "clan";

  inventory.instances = {

    sshd.roles.server.tags = [ "all" ];

    user-root = {
      module.name = "users";
      roles.default.tags = [ "all" ];
      roles.default.settings = {
        user = "root";
        openssh.authorizedKeys.keys = keys.ssh;
      };
    };

    # p2p-ssh-iroh.roles.server.tags = [ "all" ];

    importer = {
      roles.default.tags = [ "all" ];
      roles.default.extraModules = [ modules/incus.nix ];
    };

  };

  machines = {
    # test-machine = { config, ... }: {
    #   environment.systemPackages = [ pkgs.asciinema ];
    # };
  };

  # Use the age backend for secret vars. Recipients are the admin/user age keys
  # that encrypt each machine's private key; the yubikey behind them is only
  # needed at decrypt/deploy time.
  vars.settings.secretStore = "age";
  vars.settings.recipients.default = keys.age;
  secrets.age.plugins = [ "age-plugin-yubikey" ];

}
