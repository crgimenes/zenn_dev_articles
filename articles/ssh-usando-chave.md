---
title: "SSH鍵認証でサーバーに安全にアクセスする"
emoji: "🔑"
type: "tech"
topics: ["ssh", "unix", "networking"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=f-4R_PNEFT4).

Accessing servers over SSH with a public/private key pair is safer and more convenient — safer above all — and it also makes automating tasks much easier.

## Creating the keys

First, generate the keys with the following command:

```bash
mkdir ~/.ssh
ssh-keygen
```

You only need to do this once on the client machine, and a key pair will be generated. You can choose the file name, which defaults to `id_rsa` for the private key and `id_rsa.pub` for the public key.

It's a good idea to create one key per server you plan to access, just as it's advisable to use a different password for each service. With keys, though, you control half of the pair — the private half — and that one needs to be kept well protected.

## Copying the public key to the server

You need to copy the key you just generated into the `~/.ssh/authorized_keys` file on the server. You can do that manually with the following commands.

```bash
cat ~/.ssh/id_rsa.pub |
ssh user@example.com 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

But it's easier to use the `ssh-copy-id` command, which does practically the same thing. Here's an example:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub user@example.com
```

With either command, the `.ssh` directory will be created in the user's home directory on the server, and that will be the last time you have to type a password to reach that terminal.

## Even more convenient

You could stop at the previous command — the server already accepts your SSH connections without asking for a password, because we're using a public/private key pair. But we can make things easier still.

Edit the `~/.ssh/config` file as shown below.

```
Host *
    ServerAliveInterval 240
    ConnectTimeout 0

Host example
    HostName example.com
    Port 22
    User user_name
    IdentityFile  ~/.ssh/id_rsa
    IdentitiesOnly yes
```

This configures SSH not to drop the connection due to inactivity, which helps a lot when you're coding and need to go back and forth between your terminal and other tools for long stretches. We're also setting the user name, the port, and an alias for the server, so instead of typing `ssh you@example.com` you just type `ssh example`. That small saving in keystrokes makes all the difference, and it also prevents mistakes.

## Security

This kind of setup is safer than using a password alone, as long as you take good care of your key pair.
