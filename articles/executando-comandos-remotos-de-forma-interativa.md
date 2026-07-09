---
title: "SSHでリモートコマンドをインタラクティブに実行する"
emoji: "🖥️"
type: "tech"
topics: ["go", "ssh", "terminal", "tmux", "zsh"]
published: true
---

I often need to run a command on a remote server without starting a full interactive session. I want the program to keep all the characteristics of a local process while running on the remote server.

At first, I just used the `ssh` command, specifying the server and the command to run:

```bash
ssh server command
```

This method doesn't work well for programs that require a pseudo terminal, like *Neovim*. To fix that, I tried the `-t` option to force pseudo terminal allocation. With it, programs like `ls` display colors, but the user environment isn't loaded. In that case, I need to pass the `--color` option to `ls`. Even so, programs like *Neovim* fail because the *shell* doesn't behave as interactive and ANSI codes aren't processed correctly.

```bash
ssh -t server command
```

To get a fully working *shell* that loads its configuration, I tell the *shell* to run as interactive. In zsh, that's the `-i` option. I also use the `-c` option to run the desired command:

```bash
ssh -t server "zsh -ic 'command'"
```

This way, I run complex commands from my local machine without opening an interactive remote session, which improves convenience and security. This method is useful in scripts that need to manipulate the server, since it doesn't leave the session open.

The only drawback is that the command runs in a new *shell*, without keeping environment variables and other settings after it finishes. I can attach to a *tmux* or *screen* session, but that makes it hard to identify where the command starts and ends, preventing output capture.

In any case, here is the command to create a *tmux* session, or attach to an existing one, and then run the command:

```bash
ssh -t server "tmux new-session -d -s persistent || true; \
tmux send-keys -t persistent \"zsh -ic 'command'\" Enter; \
tmux attach -t persistent"
```

To get a remote *shell* with all the settings and environment variables while keeping state between sessions, we would need a new *shell*. But that's a project for another day.

Video with a detailed explanation:

@[youtube](ncgeZ2EIx6Q)
