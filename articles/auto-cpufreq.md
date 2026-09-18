---
title: "auto-cpufreqでCPU周波数を動的に調整する"
emoji: "⚡"
type: "tech"
topics: ["linux", "cpu", "raspberrypi"]
published: true
---

[auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq) optimizes CPU frequency and reacts quite fast. It's great for stretching battery life on a Linux laptop.

In my case, I use it to keep my small home server at a milder temperature, and in practice I haven't noticed any real impact. There's a bit of latency when the machine is "cold" and I suddenly start some heavy process, like opening an SSH+mosh+zsh session.

## Installation

```bash
git clone https://github.com/AdnanHodzic/auto-cpufreq.git
cd auto-cpufreq
sudo ./auto-cpufreq-installer
```

Track CPU core frequency and temperature with the following command

```bash
sudo auto-cpufreq --monitor
```

Since it runs as a service, the usual systemctl commands work

```bash
systemctl status auto-cpufreq
```

## Raspberry Pi

It's a shame auto-cpufreq only supports x86 processors. It would be very useful for the Raspberry Pi.

For the Raspberry, I'm currently [downclocking by adjusting config.txt](https://www.raspberrypi.org/documentation/configuration/config-txt/overclocking.md), mainly because of temperature and because I don't need much processing power.
