---
title: "mitigations=offでLinuxを高速化する（セキュリティとのトレードオフ）"
emoji: "⚡"
type: "tech"
topics: ["linux"]
published: true
---

First, of course, don't hold me responsible for what you do to your system — the responsibility is entirely yours.

There are several processing strategies that, despite producing a substantial performance gain, ended up introducing security flaws. What I did was take two machines from my cluster and configure the *Linux kernel* not to disable those features.

In my case, since I use Debian, I edited the file `/etc/default/grub` and added `mitigations=off` at the end of the `GRUB_CMDLINE_LINUX_DEFAULT` variable.

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet mitigations=off"
```

Then I updated grub with the `update-grub` command and rebooted the system.

```
update-grub
```

The performance gain seemed substantial, but I still need to run longer tests. The result can vary considerably depending on the processor you're using and the processes being executed.

In my case, the machines are mostly used to run *VMs* (*qemu*) and have eighth- and ninth-generation *Intel i5* processors. If my processors had *hyper threading*, I should get even better results, and if I were using *AMD*, the results would probably be much worse.

## The Security Problem

Needless to say, disabling security patches is not a good idea unless you know exactly what you're doing. In my case, these machines aren't used directly by anyone, nor are they exposed to the internet — they're servers that stay protected and run very specific processes.

This change is not recommended, especially on a user machine.

## Measure the Performance

Another important point is that engineering without numbers is just opinion. Before making the change, measure your system's performance — particularly the *load average* — and compare it with the numbers after the change. Then decide whether the gain is worth it.

```bash
> $ uptime
 17:38:44 up  1:48,  1 user,  load average: 0.55, 0.59, 0.62
```

`mitigations=off` is a "meta-parameter" that actually disables several *kernel* parameters, and new parameters may be added in newer *kernel* versions, so you need to stay alert to make sure you're not exposing your system to a new security flaw.
