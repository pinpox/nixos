# Kartoffel

Personal desktop computer running i3.

```
▸ nix-shell -p pkgs.inxi -p pkgs.lm_sensors --command "inxi -Fx"
System:    Host: kartoffel Kernel: 5.4.72 x86_64 bits: 64 compiler: gcc v: 9.3.0 Desktop: i3 4.18.2
           Distro: NixOS 21.03pre249162.1dc37370c48 (Okapi)
Machine:   Type: Desktop System: LENOVO product: 2929A1G v: ThinkCentre M82
           serial: <superuser/root required>
           Mobo: LENOVO model: MAHOBAY serial: <superuser/root required> UEFI: LENOVO v: 9SKT9CAUS
           date: 12/11/2018
CPU:       Info: Quad Core model: Intel Core i5-3550 bits: 64 type: MCP arch: Ivy Bridge rev: 9
           L2 cache: 6144 KiB
           flags: avx lm nx pae sse sse2 sse3 sse4_1 sse4_2 ssse3 vmx bogomips: 26340
           Speed: 1597 MHz min/max: 1600/3700 MHz Core speeds (MHz): 1: 1597 2: 1597 3: 1597 4: 1597
Graphics:  Message: No Device data found.
           Display: server: X.org 1.20.9 driver: N/A resolution: <xdpyinfo missing>
           Message: Unable to show advanced data. Required tool glxinfo missing.
Audio:     Device-1: HDA Intel PCH driver: HDA-Intel message: bus/chip ids unavailable
           Device-2: HDA NVidia driver: HDA-Intel message: bus/chip ids unavailable
           Device-3: Focusrite Scarlett 2i2 USB type: USB driver: snd-usb-audio bus ID: 4-1.5:3
           Device-4: C-Media USB Audio Device type: USB driver: hid-generic,snd-usb-audio,usbhid
           bus ID: 2-4:7
           Sound Server: ALSA v: k5.4.72
Network:   Message: No Device data found.
           Device-1: Realtek USB 10/100/1000 LAN type: USB driver: r8152 bus ID: 3-3.1.1:4
           IF: enp0s20u3u1u1 state: down mac: 18:65:71:e5:b1:e2
           IF-ID-1: br-524b250135d4 state: down mac: 02:42:ae:97:ea:59
           IF-ID-2: docker0 state: down mac: 02:42:79:03:a6:f2
           IF-ID-3: eno1 state: up speed: 1000 Mbps duplex: full mac: 00:16:41:3c:ea:80
           IF-ID-4: virbr0 state: down mac: 52:54:00:61:79:2b
           IF-ID-5: virbr0-nic state: down mac: 52:54:00:61:79:2b
           IF-ID-6: wg0 state: unknown speed: N/A duplex: N/A mac: N/A
Drives:    Local Storage: total: 954.81 GiB used: 64.31 GiB (6.7%)
           ID-1: /dev/sda vendor: Crucial model: CT525MX300SSD1 size: 489.05 GiB
           ID-2: /dev/sdb vendor: SanDisk model: SDSSDH3 500G size: 465.76 GiB
Partition: ID-1: / size: 472.00 GiB used: 64.21 GiB (13.6%) fs: ext4 dev: /dev/dm-2
           ID-2: /boot size: 499.0 MiB used: 94.8 MiB (19.0%) fs: vfat dev: /dev/sda1
Swap:      ID-1: swap-1 type: partition size: 8.00 GiB used: 0 KiB (0.0%) dev: /dev/dm-1
Sensors:   System Temperatures: cpu: 29.8 C mobo: 27.8 C gpu: nvidia temp: 39 C
           Fan Speeds (RPM): N/A gpu: nvidia fan: 0%
Info:      Processes: 169 Uptime: 3h 40m Memory: 7.71 GiB used: 1.40 GiB (18.2%) Init: systemd Compilers:
           gcc: 9.3.0 Packages: N/A Shell: Bash v: 4.4.23 inxi: 3.1.08

▸ lsblk -f
NAME          FSTYPE      FSVER    LABEL                   UUID                                   FSAVAIL FSUSE% MOUNTPOINT
sda
├─sda1        vfat        FAT32                            5D7C-69F9                               404.2M    19% /boot
└─sda2        crypto_LUKS 2                                608e0e77-eea4-4dc4-b88d-76cc63e4488b
  └─root      LVM2_member LVM2 001                         2Fo0GS-9HwJ-NlFP-TRIr-tEtM-BCXq-jP2jXv
    ├─vg-swap swap        1        swap                    0f369649-cdbc-4a34-82dc-9f442c445c53                  [SWAP]
    └─vg-root ext4        1.0      root                    8dcfb3f0-4dba-4c32-af96-84024706ff76    383.7G    14% /
sdb           udf         1.02     CCCOMA_X64FRE_EN-GB_DV9 478c00004d532055
├─sdb1        vfat        FAT32                            B8AF-223C
├─sdb2
├─sdb3        ntfs                                         5A62B45C62B43F17
└─sdb4        ntfs                                         72E2304FE23019B5

```
