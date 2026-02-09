{
  clanLib,
  directory,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "dm-deploy";
  manifest.description = "Pull-based NixOS deployment via data-mesher";
  manifest.readme = "Pull-based NixOS deployment via data-mesher";
  manifest.categories = [ "System" ];
  manifest.exports.out = [ "dataMesher" ];

  # Push role — machines that can trigger deployments
  roles.push = {
    description = "Can push deployment targets to the clan via data-mesher";
    interface = { };

    perInstance =
      {
        mkExports,
        machine,
        ...
      }:
      {
        exports = mkExports {
          dataMesher.files = {
            "dm_deploy/target" = [
              (clanLib.getPublicValue {
                flake = directory;
                generator = "dm-deploy-signing-key";
                file = "signing.pub";
                default = throw ''
                  dm-deploy: Signing key not yet generated.
                  Run 'clan vars generate ${machine.name} -g dm-deploy-signing-key' to generate it.
                '';
              })
            ];
          };
        };

        nixosModule =
          { config, pkgs, ... }:
          {
            # Signing key for deployment target distribution via data-mesher
            clan.core.vars.generators.dm-deploy-signing-key = {
              share = true;
              files = {
                "signing.key" = { };
                "signing.pub".secret = false;
              };
              runtimeInputs = [ config.services.data-mesher.package ];
              script = ''
                data-mesher generate signing-key \
                  --private-key-path "$out/signing.key" \
                  --public-key-path "$out/signing.pub"
              '';
            };

            environment.systemPackages = [
              (pkgs.writeShellApplication {
                name = "dm-send-deploy";
                runtimeInputs = [ config.services.data-mesher.package ];
                text = ''
                  if [ $# -ne 1 ]; then
                    echo "Usage: dm-send-deploy <flake-ref>"
                    echo "Example: dm-send-deploy github:pinpox/nixos/abc123..."
                    exit 1
                  fi

                  KEY="${config.clan.core.vars.generators.dm-deploy-signing-key.files."signing.key".path}"
                  if [ ! -r "$KEY" ]; then
                    echo "Error: cannot read signing key at $KEY (are you root?)"
                    exit 1
                  fi

                  FLAKE_REF="$1"
                  TMPFILE=$(mktemp)
                  trap 'rm -f "$TMPFILE"' EXIT

                  printf '%s' "$FLAKE_REF" > "$TMPFILE"

                  data-mesher file update "$TMPFILE" \
                    --url http://localhost:7331 \
                    --key "$KEY" \
                    --name "dm_deploy/target"

                  echo "Deployment target pushed: $FLAKE_REF"
                '';
              })
            ];
          };
      };
  };

  # Default role — machines that auto-rebuild when a new target is pushed
  roles.default = {
    description = "Auto-rebuilds when a new deployment target is distributed via data-mesher";
    interface = { };

    perInstance =
      {
        mkExports,
        machine,
        ...
      }:
      {
        exports = mkExports {
          dataMesher.files = {
            "dm_deploy/status_${machine.name}" = [
              (clanLib.getPublicValue {
                flake = directory;
                machine = machine.name;
                generator = "dm-deploy-status-key";
                file = "signing.pub";
                default = throw ''
                  dm-deploy: Status signing key for ${machine.name} not yet generated.
                  Run 'clan vars generate ${machine.name} -g dm-deploy-status-key' to generate it.
                '';
              })
            ];
          };
        };

        nixosModule =
          {
            config,
            pkgs,
            flake-self,
            ...
          }:
          let
            hostname = machine.name;
            revision = flake-self.rev or "unknown";
            dmFilesDir = "/var/lib/data-mesher/files/dm_deploy";
            targetFile = "${dmFilesDir}/target";
          in
          {
            # Per-host signing key for status updates
            clan.core.vars.generators.dm-deploy-status-key = {
              files = {
                "signing.key" = { };
                "signing.pub".secret = false;
              };
              runtimeInputs = [ config.services.data-mesher.package ];
              script = ''
                data-mesher generate signing-key \
                  --private-key-path "$out/signing.key" \
                  --public-key-path "$out/signing.pub"
              '';
            };

            # Create dm-deploy subdirectory in data-mesher's file storage
            services.data-mesher.fileDirectories = [ "dm_deploy" ];

            # Watch for new deployment targets
            systemd.paths.dm-deploy = {
              description = "Watch for deployment target changes from data-mesher";
              wantedBy = [ "multi-user.target" ];
              pathConfig = {
                PathChanged = dmFilesDir;
                Unit = "dm-deploy.service";
              };
            };

            # Rebuild service triggered by path watcher
            systemd.services.dm-deploy = {
              description = "Rebuild NixOS from deployment target distributed via data-mesher";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                SyslogIdentifier = "dm-deploy";
              };
              path = [
                pkgs.nixos-rebuild
                pkgs.nix
                pkgs.git
              ];
              script = ''
                set -euo pipefail

                if [ ! -f "${targetFile}" ]; then
                  echo "No deployment target file found at ${targetFile}, skipping"
                  exit 0
                fi

                FLAKE_REF=$(cat "${targetFile}")
                echo "Deployment target: $FLAKE_REF"
                nixos-rebuild dry-build --flake "$FLAKE_REF#${hostname}"
                # nixos-rebuild switch --flake "$FLAKE_REF#${hostname}"
              '';
            };

            # Report deployed revision to data-mesher; reruns when revision changes
            systemd.services.dm-deploy-status = {
              description = "Report deployed config revision via data-mesher";
              after = [ "data-mesher.service" ];
              wants = [ "data-mesher.service" ];
              wantedBy = [ "multi-user.target" ];
              restartTriggers = [ revision ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                SyslogIdentifier = "dm-deploy-status";
              };
              path = [ config.services.data-mesher.package ];
              script = ''
                set -euo pipefail

                TMPFILE=$(mktemp)
                trap 'rm -f "$TMPFILE"' EXIT
                echo "${revision}" > "$TMPFILE"

                data-mesher file update "$TMPFILE" \
                  --url http://localhost:7331 \
                  --key "${config.clan.core.vars.generators.dm-deploy-status-key.files."signing.key".path}" \
                  --name "dm_deploy/status_${hostname}"

                echo "Status updated for ${hostname}: ${revision}"
              '';
            };
          };
      };
  };
}
