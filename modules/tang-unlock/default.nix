{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.tang-unlock;
in
{
  # Unlock a LUKS device unattended while the Tang server is reachable; falls
  # back to the passphrase otherwise. The JWE wraps a key in its own LUKS
  # keyslot and is useless without Tang.
  #
  # The keyslot itself is not managed here. New installs: add
  #   additionalKeyFiles = [ config.clan.core.vars.generators.luks-tang-key.files.key.path ];
  # to the disko LUKS partition. Existing installs: `cryptsetup luksAddKey` the
  # key from `clan vars get <machine> luks-tang-key/key`.
  options.pinpox.services.tang-unlock = {
    enable = mkEnableOption "unattended LUKS unlock via clevis/Tang in the initrd";

    url = mkOption {
      type = types.str;
      default = "http://192.168.101.1:9090";
      description = "Tang server URL, reached from the initrd over IPv4.";
    };

    adv = mkOption {
      type = types.path;
      default = ./tang-adv.jws;
      description = ''
        Tang advertisement (`curl <url>/adv`). The key is encrypted against it
        offline, since the generator sandbox has no network. Refresh after
        rotating the server's Tang keys; the JWE is then re-encrypted with the
        same LUKS key.
      '';
    };

    device = mkOption {
      type = types.str;
      default = "crypted";
      description = "Name of the LUKS device in `boot.initrd.luks.devices`.";
    };

    interface = mkOption {
      type = types.str;
      example = "enp191s0";
      description = "Network interface used to reach Tang (systemd.network `Name=` match, globs allowed).";
    };

    kernelModules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "r8169"
        "realtek"
      ];
      description = "Initrd kernel modules needed for the network interface.";
    };

    waitOnlineTimeout = mkOption {
      type = types.ints.positive;
      default = 120;
      description = ''
        Seconds the initrd waits for the network before clevis gives up and
        the passphrase prompt appears. Lower it on machines that often boot
        without the cable.
      '';
    };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "pinpox.services.tang-unlock requires boot.initrd.systemd.enable";
      }
    ];

    clan.core.vars.generators = {
      # LUKS key for the Tang keyslot. Uploaded only during
      # `clan machines install`, where disko can add it as a keyslot.
      luks-tang-key = {
        files.key.neededFor = "partitioning";
        runtimeInputs = [ pkgs.coreutils ];
        script = ''
          head -c 48 /dev/urandom | base64 -w0 > "$out"/key
        '';
      };

      luks-tang-jwe = {
        dependencies = [ "luks-tang-key" ];
        files.jwe.secret = false;
        validation = {
          adv = builtins.hashFile "sha256" cfg.adv;
          inherit (cfg) url;
        };
        runtimeInputs = [ pkgs.clevis ];
        script = ''
          clevis encrypt tang '${
            builtins.toJSON {
              inherit (cfg) url;
              adv = "${cfg.adv}";
            }
          }' < "$in"/luks-tang-key/key > "$out"/jwe
        '';
      };
    };

    boot.initrd = {
      clevis = {
        enable = true;
        useTang = true;
        devices.${cfg.device}.secretFile =
          config.clan.core.vars.generators.luks-tang-jwe.files.jwe.flakePath;
      };
      availableKernelModules = cfg.kernelModules;
      systemd.network = {
        enable = true;
        wait-online.timeout = cfg.waitOnlineTimeout;
        networks."10-lan" = {
          matchConfig.Name = cfg.interface;
          networkConfig.DHCP = "ipv4";
          # Tang is reached over IPv4. Without this, router advertisements give
          # the link IPv6 addresses first, network-online fires, and clevis runs
          # before the DHCPv4 lease exists.
          linkConfig.RequiredFamilyForOnline = "ipv4";
        };
      };
    };
  };
}
