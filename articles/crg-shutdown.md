---
title: "APM 1.2 で MS-DOS をシャットダウンする小さなユーティリティを作った"
emoji: "🔌"
type: "tech"
topics: ["c", "assembly", "msdos", "nasm", "retro"]
published: true
---

A tiny 16-bit C utility that shuts down or reboots MS-DOS via APM 1.2.

I made it to use with DOS running in VirtualBox. The VM kept burning CPU because there was no clean way to tell the virtual machine to power off from inside the guest. No ceremony: the program is minuscule, talks to APM directly, and exits.

APM 1.2 (Advanced Power Management) is the power management interface found in older systems -- a predecessor to ACPI, exposed through BIOS interrupts. It works on any machine, real or virtual, with APM 1.2 capability.

The implementation combines a small C program with x86 Assembly routines (NASM), compiled with Turbo C for 16-bit. The result is three `.com` files -- `sd.com`, `quit.com`, and `reboot.com` -- each with a specific role.

```console
sd -r       # reboot
sd -h       # halt
reboot      # reboot
quit        # halt
```

The alternate-name wrapper exists just to read more naturally at the DOS prompt.

Binaries and source code are in the repository.
