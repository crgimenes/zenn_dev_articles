---
title: "スマホのGPSをRaspberry Piで使う"
emoji: "🛰️"
type: "tech"
topics: ["raspberrypi", "gps", "unix", "gpsd", "wardriving"]
published: true
---


I need the *Raspberry Pi* I carry in my backpack to have access to GPS coordinates, but the USB GPS units and other models available for the *Raspberry* are too unreliable and expensive.

The solution is to use the phone's GPS and share the data with the rest of the gear. This has several advantages: the phone's GPS is excellent, it has usually already locked onto a few satellites, and on top of that I already have it on me, so I don't have to buy anything extra.

On the phone side, you need an app that broadcasts the GPS coordinates, such as [GPS2IP](https://itunes.apple.com/us/app/gps-2-ip/id408625926?mt=8) for iOS.

Configure the app to send the data to the *Raspberry*, and don't forget to set the phone so it doesn't go to sleep. These settings vary depending on the app you choose, but they are usually easy to set up.

## Raspberry Pi

Install gpsd:

```bash
apt install gpsd
```

If you want to run a manual test, stop the gpsd and gpsd.socket services and start the gpsd server manually.

```bash
systemctl stop gpsd
systemctl stop gpsd.socket

gpsd -N udp://raspberryIP:port # same ip and port as the app
```

You can test whether the *Raspberry* is receiving the coordinates with the `cgps` command.

## Permanent configuration

To make the settings more permanent, edit the */etc/defaults/gpsd* file and change the *DEVICES* parameter as in the example below.

```bash
DEVICES="udp://raspberryIP:port"
```

Now you just need to restart the machine, or simply start the services again.


```bash
systemctl start gpsd
systemctl start gpsd.socket
```

## Videos with an explanation

- [YouTube](https://youtu.be/0RckctvnmfI)
- [Odysee](https://odysee.com/@crgimenes:7/usando-gps-do-celular-na-raspberry-pi:d)

## Conclusion

Sharing the phone's GPS coordinates with the "backpack server" was simpler than I expected, and it was certainly more fun and cheaper than buying a GPS just for the *Raspberry*.

One important detail is that the same thing can be done with other phone features as well, for example, sharing the 4G connection. And of course, it doesn't have to be a *Raspberry Pi*; any machine will be able to consume the resources.

Another detail worth keeping an eye on is the phone's battery usage, because with the GPS running all the time the consumption will surely go up.
