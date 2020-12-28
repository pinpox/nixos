#!/usr/bin/env bash

# Don't ignore any errors
set -euo pipefail
shopt -s inherit_errexit

hostname="$1"

# Run `borg info` only once since it is quite slow
export BORG_PASSPHRASE="$(cat /var/src/secrets/borg-server/$hostname)"
json_out="$(/run/current-system/sw/bin/borg info --last 2 --json "/mnt/backup/borg-nix/$hostname")"

# Helper function to extract values from borg's json
get() {
	echo "$(echo "$json_out" | /run/current-system/sw/bin/jq -r "$1")"
}

print_info() {

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

}

check_repo_params() {
	# Encryption should be set to "repokey"
	if [ "$(get '.encryption.mode')" != "repokey" ]; then
		echo "Encryption for repository was: $(get '.encryption.mode')"
		exit 1
	fi
}

check_archive_time() {

	end1_sec=$(date -d "$(get '.archives[1].end')" +"%s")
	now=$(date +"%s")
	hours_diff="$(( ( now - end1_sec ) / 3600 ))"

	# Check if last backup is more than 24 hours old
	[[ $hours_diff -lt 24  ]] || { echo "Last backup is to old ($hours_diff > 24h)!"; exit 1; }
	echo "Last backup time: $hours_diff hours ago"
}

check_diff() {
	#TODO
}

echo "Checks"
echo "======"
echo ""
check_repo_params
check_archive_time

print_info


exit 0
