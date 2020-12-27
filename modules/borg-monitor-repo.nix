{ pkgs, ... }:

let
  borg-monitor-repo = pkgs.writeScriptBin "borg-monitor-repo" ''
    #!${pkgs.stdenv.shell}

    hostname="$1"

    # Run `borg info` only once since it is quite slow
    export BORG_PASSPHRASE="$(cat /var/src/secrets/borg-server/$hostname)"
    json_out="$(${pkgs.borgbackup}/bin/borg info --last 2 --json /mnt/backup/borg-nix/$hostname)"

    # Helper function to extract values from borg's json
    get() {
      echo "$(echo $json_out | ${pkgs.jq}/bin/jq -r $1)"
    }

    # Display Repository information
    cat << EOF
    Repository
    ==========

    Location:          $(get ".repository.location")
    Encryption:        $(get ".encryption.mode")
    Last Modified:     $(get ".repository.last_modified")

    Last archive:
    =============

    Time:              $(get '.archives[0].end')
    Duration:          $(get '.archives[0].duration')
    Name:              $(get '.archives[0].name')
    Hostname:          $(get '.archives[0].hostname')
    User:              $(get '.archives[0].username')
    Original size:     $(get '.archives[0].stats.original_size')
    Compressed size:   $(get '.archives[0].stats.compressed_size')
    Deduplicated size: $(get '.archives[0].stats.deduplicated_size')
    Number of files:   $(get '.archives[0].stats.nfiles')
    EOF

    exit 0
  '';

in {
  environment.systemPackages = [ borg-monitor-repo ];
}
