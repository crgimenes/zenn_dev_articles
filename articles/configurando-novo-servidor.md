---
title: "新しいサーバーを立ち上げるときの初期セットアップ"
emoji: "🖥️"
type: "tech"
topics: ["terminal", "linux", "ssh", "development"]
published: true
---

Whenever I bring up a new machine I always run a few commands and set up some configuration. A lot of it is already handled by my [dotfiles](https://github.com/crgimenes/dotfiles), but there's always plenty of custom work left to do.

The first thing is to get SSH access and make sure the root password isn't the default one.

Next I give my user sudo access, in case it doesn't have it already.

```bash
usermod -aG sudo ${USER}
```

If it's a machine on the local network, I set it up to use [zero configuration network](https://crg.eti.br/pub/zero-configuration-network-no-debian/), a much more convenient way to reach the machine, especially on IPv6 networks. Otherwise, this is a good time to add the machine to a domain.

```bash
apt install avahi-daemon
```

The next step is to copy the SSH key to the new server so I no longer need to log in with a password, which also buys a bit more security.

```bash
ssh-copy-id \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    ${USER}@example.local
```

After that, it's a good idea to configure the *locale*. This avoids a bunch of problems with commands that need to know you intend to use UTF-8. I prefer `en_US.UTF-8`, and it may be necessary to set the variable directly in bashrc: `LANG=en_US.UTF-8`.

```bash
dpkg-reconfigure locales
```

To make terminal access a bit snappier and more responsive, I install [mosh-server](https://mosh.org). If the machine sits behind a firewall, you'll need to open UDP ports 60001 through 60999.

```bash
apt install mosh
```

Now's a good time to install tmux. Unlike most people, I don't use tmux to keep windows organized in the terminal. The main reason I use it is that, paired with mosh, you basically get an indestructible and very convenient session: you can close your laptop at work, travel back home, and when you open it again your terminal will be exactly as you left it, cursor in the same spot and everything.

```bash
apt install tmux
```

My `~/.tmux.conf` file is pretty simple, and a quick scp is enough to send a copy to the new machine.

```bash
scp ~/.tmux.conf newmachine.local:/home/${USER}/
```

If I'm going to *code* on the machine, I'll install *neovim* and spend some time making sure all the plugins are installed, and so on, but most of the time plain *vim* with default settings is enough.

```bash
apt install vim
```

Finally, I set up two aliases to make connecting easier, one using tmux and one without. I always name these aliases `mosh_` and let zsh fill in the rest.

```bash
alias mosh_newmachine="mosh \
    --server='/usr/bin/mosh-server' \
    newmachine.local \
    -- tmux new-session -A -s default"

alias mosh_newmachine_ntm="mosh \
    --server='/usr/bin/mosh-server' \
    newmachine.local"
```

## Enabling rc.local

Some people don't like the idea of enabling `rc.local` because it exists purely for backward compatibility with very old *UNIX* versions from the late 70s. But I find it extremely simple and practical. The setup needs to become far more permanent before I bother creating a proper service, and even then `rc.local` can still come in handy.

Obviously the script needs to be well written and use absolute paths.

```bash
touch /etc/rc.local
chmod 700 /etc/rc.local
systemctl enable rc-local.service
```

Example *rc.local* script:

```bash
#!/bin/bash
echo "rc.local"

# something to run at boot

exit 0
```

## Booting into console mode

I usually don't even install the X Window System. Most of my systems are operated over SSH, and even when I'm in front of the console, I prefer to operate servers without a graphical interface. But there are some situations where you want to run graphical software, and in those cases it's better not to load X automatically. Instead, I prefer to boot the system in *console mode* and use `startx` when needed.

To make the system boot into console mode by default, use the command below.

```bash
systemctl set-default multi-user.target
```

## Adjusting the console font

I find the default console font too small. To make it more readable, I prefer to change the font type and size, using the following command.

```bash
dpkg-reconfigure console-setup
```

Or edit the file `/etc/default/console-setup` as in the example below.

```bash
FONT="Lat7-Terminus32x16.psf.gz"
ACTIVE_CONSOLES="/dev/tty[1-6]"
CHARMAP="UTF-8"
CODESET="Lat15"
FONTFACE="guess"
FONTSIZE="14x28"
```

For more details on console settings, read the manual with `man 5 console-setup`.

## A cleaner console

Edit the file `/etc/sysctl.conf` and uncomment the line `kernel.printk = 3 4 1 3`. This stops the kernel from printing low-level messages directly to the console.

```bash
kernel.printk = 3 4 1 3
```

## Docker

If the machine is going to serve Docker containers, it's worth giving non-root users access to the Docker service.

```bash
sudo usermod -aG docker ${USER}
```

On the client side, download the static Docker binary from https://download.docker.com/. You only need the `docker` file; put it anywhere in your path.

Set the `DOCKER_HOST` environment variable as in the example:

```bash
export DOCKER_HOST=ssh://user@example.local
```

## GitHub

Basic git configuration.

```bash
git config --global user.name "User Name"
git config --global user.email user@example.com
git config --global pull.ff only
```

Always use SSH when accessing GitHub repositories.

```
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### Go with a private repo

For Go to fetch packages from private repositories, you need to set the `GOPRIVATE` environment variable, as in the example.

```bash
export GOPRIVATE=github.com/organization/repository
```

You can use a comma `,` to add multiple repositories, or just the organization name, without the repository, if you want to cover multiple repositories from the same organization.

## Terminal font

I usually switch the terminal font to `IBM 3270`. There's a great reimplementation of that font at [https://github.com/rbanffy/3270font](https://github.com/rbanffy/3270font). Honestly, I use this font for everything; it looks fantastic, especially when I'm running my PDP-11 on 2.11BSD. *I know the "correct" choice would be the DEC VT-102 terminal font.*
