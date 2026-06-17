---
title: "/etc/rc.local で80年代風にサービスを起動する"
emoji: "⚙️"
type: "tech"
topics: ["linux", "systemd", "boot", "init", "unix"]
published: true
---

I often use the `/etc/rc.local` *script* to quickly start services during boot. It is convenient, simple, and works well on Debian and other Linux distributions. It is essentially just an sh script (or whichever shell you prefer) that runs during boot.

Interestingly, *rc.local* has been considered obsolete since the release of *UNIX System III* in 1983!

Since then, several attempts have been made to retire this file. It has not been recommended for a long time in favor of more modern solutions for starting services during boot, but it still persists. If the `/etc/rc.local` file does not exist on your system, try creating it and giving it execute permission. There is a good chance systemd will recognize that you are fully *old school* and run *rc.local* normally during *boot*, even politely waiting for the network to come up before running it (tested on Debian and Ubuntu).

Why use *rc.local*? Simplicity. It is just a script. Not TOML, YAML, or any other exotic configuration format. Being a plain script, it lets you do any kind of hack you want.

Of course, by using it you give up more advanced features such as automatic restart and dependency management between services.

The fact that *rc.local* still exists, even though it has been considered obsolete for more than 40 years, is proof that simple is always better. As the saying goes: if it ain't broke, don't fix it.

Below is the default *systemd* configuration that runs *rc.local* during boot, on both Debian and Ubuntu:

```ini
#  SPDX-License-Identifier: LGPL-2.1-or-later
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

# This unit gets pulled automatically into multi-user.target by
# systemd-rc-local-generator if /etc/rc.local is executable.
[Unit]
Description=/etc/rc.local Compatibility
Documentation=man:systemd-rc-local-generator(8)
ConditionFileIsExecutable=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=infinity
RemainAfterExit=yes
GuessMainPID=no
```

In other words, if the `/etc/rc.local` file exists and is executable, *systemd* will run it automatically.

By default, this service only passes the "start" parameter to the `/etc/rc.local` *script*, but you can easily modify it to accept other parameters, such as "stop", making it even closer to the classic *SysV* style.
