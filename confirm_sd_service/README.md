# SD card confirm reading service.

for RaspberryPi.

## Abstract

This service is reading all sectors or files in SD card to confirming Flash memory.

Flash memory cells have very little electric charge. So the charge is leaked in/out slowly.
By performing the read operation periodically, we expect the SD card to correct its own errors.

## Getting started

I confirmed the operation with RaspiberryPi OS Lite (Release date: February 21st 2023).

### File copy

Copy each file to the path shown below.
```
cp confirm_sd.service /etc/systemd/system/
cp confirm_sd.timer /etc/systemd/system/
mkdir -p /usr/local/libexec
cp confirm_sd_read.sh /usr/local/libexec/
```

### Enable service (timer)
```
systemctl enable confirm_sd.timer
```

### and Reboot.
```
reboot
```

### Check this service is enabled.
```
systemctl list-timers
```


## Configuration

By default, the service runs after 15 minutes of startup.  
It will also run periodically, every month.  
This timing can be changed by editing the confirm_sd.timer file.


## License

Copyright (c) 2015-2023 Shimane IT Open-Innovation Center All right reserved.

This software is distributed under BSD license. see LICENSE file.
