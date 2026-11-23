---
title: "Zeroconf でローカルネットワーク上のデバイスを名前で見つける"
emoji: "🔍"
type: "tech"
topics: ["networking", "iot", "debian", "zeroconf", "avahi"]
published: true
---

I frequently add new devices to my network for all sorts of purposes. They can be anything: an [SBC](https://en.wikipedia.org/wiki/Single-board_computer) for IoT projects, a virtual machine for testing software without touching the main systems, or a throwaway VM for quick experiments.

That creates a problem: how do I find the IP address to reach those resources? I could check the DHCP leases, assign static IPs, or come up with something else, but none of that is practical. I need something quick and easy that works both for me and for scripts that have to locate resources on the network, even when the IP has changed.

That's where the Zero Configuration Networking protocols come in. [Zero Configuration Networking, or Zeroconf](https://en.wikipedia.org/wiki/Zero-configuration_networking), is a set of protocols that automatically finds resources on the local network by name.

macOS, the iPhone, the Raspberry Pi, and even my network printer come with Zeroconf ready to go. On Debian-based devices, installing the necessary protocols is very simple. Just run:

```bash
apt install avahi-daemon
```

From then on you can reach the new host by name with the *.local* suffix, for example *debian.local*. This also works on other Debian-based Linux distributions, such as Ubuntu.

You can go further with more advanced configuration and service registration, but just being able to resolve names without any hassle is already great.
