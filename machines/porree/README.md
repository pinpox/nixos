# Porree

Personal server for [pablo.tools](pablo.tools) hosted on
[netcup](https://netcup.de)

## Sysetem Information

```
root@porree> nix-shell -p pkgs.inxi -p pkgs.lm_sensors --command "inxi -Fx"
System:    Host: porree Kernel: 5.4.78 x86_64 bits: 64 compiler: gcc v: 9.3.0 Console: tty 0
           Distro: NixOS 21.03pre253635.2247d824fe0 (Okapi)
Machine:   Type: Kvm System: netcup product: KVM Server v: VPS 200 G8 serial: N/A
           Mobo: N/A model: N/A serial: N/A BIOS: netcup v: VPS 200 G8 date: 10/16/2020
CPU:       Info: Single Core model: QEMU Virtual version 2.5+ bits: 64 type: MCP arch: P6 II Mendocino
           rev: 3 L2 cache: 16.0 MiB
           flags: lm nx pae sse sse2 sse3 sse4_1 sse4_2 ssse3 bogomips: 4589
           Speed: 2295 MHz min/max: N/A Core speed (MHz): 1: 2295
Graphics:  Message: No Device data found.
           Display: server: No display server data found. Headless machine? tty: 108x79
           Message: Unable to show advanced data. Required tool glxinfo missing.
Audio:     Message: No Device data found.
Network:   Message: No Device data found.
           IF-ID-1: ens3 state: up speed: -1 duplex: unknown mac: 86:36:85:0f:f6:fe
Drives:    Local Storage: total: 20.00 GiB used: 11.88 GiB (59.4%)
           ID-1: /dev/sda vendor: QEMU model: HARDDISK size: 20.00 GiB
Partition: ID-1: / size: 19.62 GiB used: 11.88 GiB (60.5%) fs: ext4 dev: /dev/sda1
Swap:      Alert: No Swap data was found.
Sensors:   Message: No sensors data was found. Is sensors configured?
Info:      Processes: 71 Uptime: 4h 34m Memory: 1.95 GiB used: 332.4 MiB (16.7%) Init: systemd
           Compilers: gcc: 9.3.0 Packages: N/A Shell: Bash v: 4.4.23 inxi: 3.1.09
```

```
root@porree> lsblk -f                                                            /etc/nixos/machines/porree
NAME   FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda
└─sda1 ext4   1.0   nixos e5913895-7f56-44ce-8975-f3da7eaac2f8    6.7G    61% /
sr0
```

## Services

The following services are provided by this server. Nginx is used as
reverse-proxy to manage TLS using Let's Encrypt (acme).

### Personal Homepage (pablo.tools)

Static files hosted in `/var/www/pablo-tools`. Updates are deployed from another
machine with this command:

```bash
rsync -avz --delete public/ pinpox@nix.own:/var/www/pablo-tools/
```

### Bitwarden_rs (pass.pablo.tools)

Bitwarden server written in Rust. Data and environment file is hosted in
`/var/lib/bitwarden_rs/`

The envfile `/var/lib/bitwarden_rs/envfile` provides secrets not included in the
public system configuration.

```
YUBICO_CLIENT_ID=XXX
YUBICO_SECRET_KEY=XXX
ADMIN_TOKEN=XXX
```

Database files and keys are saved in `/var/lib/bitwarden_rs` aswell and owned by
`bitwarden_rs:bitwarden_rs`.
