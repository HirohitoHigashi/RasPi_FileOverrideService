# File override system for Raspberry Pi OS

## What is this?

This system assumes an overlay file system environment and is designed to overwrite the OS system files to boot.

Support Raspberry Pi OS based on Debian 10 buster.


## Files.

```
├── README.md
├── boot
│   └── my
│       ├── file_override.sh
│       └── overlays
│           └── etc
│               └── rc.local
└── etc
    ├── rc.local
    └── systemd
        └── system
            └── file_override.service
```


## How to use.

1. Install and basic setup Raspberry Pi OS.
2. Use the raspi-config command to enable the Overlay File System.
3. Copy the provided files to /boot and /etc to the target.
4. Activate the service with the following command line.
```
systemctl enable file_override
```
5. and reboot!


## Override files.

Just put the files under the /boot/my/overlays directory.
