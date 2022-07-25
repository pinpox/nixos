# Backups

Each host has it's own [borgbackup](https://www.borgbackup.org/) repository on
the server, which is accessible over SSH via a dedicated key for he `borgbackup`
user.

## Repositories
To make adding and removing hosts simple, the repositorys to provision are
passed to the `borg-server` module as an attribute set following the form:

```nix
{
  myHostname1.authorizedKeys = [
    "ssh-ed25519 AAAAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXX borg@myHostname"
  ];

  myHostname2.authorizedKeys = [
    "ssh-ed25519 AAAAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXX borg@myHostname"
  ];
}
```

Repositorys are named according to the hostname and stored in
`/mnt/backup/borg-nix` as individual subdirectories.

## Monitoring

To verify that all backups have succeeded, there is an additional service for
each repository, that prints the information of the last snapshot in each
repository to a json file. These files are consumed by the `json-exporter` of
prometheus to allow adding alerting rules.

The `borg-server` module generates a systemd service unit with the following
configuration for each of the provided hosts.

```nix
systemd.services.monitor-borg-myHostname1 = {
  serviceConfig.Type = "oneshot";
  script = ''
    export BORG_PASSCOMMAND='cat /var/src/lollypos-secrets/borg-server/passphrases/myHostname1'
    ${pkgs.borgbackup}/bin/borg info /mnt/backup/borg-nix/myHostname1 --last=1 --json > /tmp/borg-myHostname1.json
  '';
};
```

The service is triggered daily by a systemd timer with the following
configuration

```nix
systemd.timers.monitor-borg-myHostname1 = {
  wantedBy = ["timers.target"];
  partOf = ["monitor-borg-myHostname1.service"];
  timerConfig.OnCalendar = "daily";
};
```
