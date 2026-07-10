---
title: "curl でアプリケーションをデプロイする"
emoji: "🚀"
type: "tech"
topics: ["curl", "bash", "deploy", "linux", "development"]
published: true
---

Distributing binaries is surprisingly hard for small teams today. If you just put an application up for download on a website, search engines will immediately flag your site as suspicious content. Browsers throw a scary warning at the user, and there is no way to get rid of it — not even by signing the binary. The warning only goes away once enough users have downloaded your binary without reporting problems.

Letting users download the binary from an already-known site — even GitHub — is not ideal either, especially for closed-source applications.

And packaging the binary for the many package-management formats across the many Linux distributions is simply too much work for a small team.

One alternative is to use `curl` together with a bash script, like the example below.

```bash
curl -fsSL https://example.com | bash
```

The `-fsSL` flags silence the output, follow redirects, and use SSL:

- `-f`: Fail silently on HTTP errors.
- `-s`: Silence the progress bar.
- `-S`: When combined with `-s`, still show HTTP errors (but not the progress bar).
- `-L`: Follow location redirects.

This approach is far from perfect, though. It carries several security implications, and many users — advanced ones in particular — will turn up their noses at it, and rightly so.

Even with well-intentioned developers, there is a real chance that a not-so-perfect bash script will wreck a system that was working just fine.

It is always a good idea to inspect what the install script does before running it.

```bash
curl -fsSL https://example.com | less
```

For the developer, this not only makes deployment much simpler, it also lets you write a script that checks whether the target machine has the required dependencies and tells the user what still needs to be installed.

The install script can also detect the architecture and operating system, so the user does not have to figure out which build to install.

There is always a chance of failure, though, and it is very frustrating for a user when a script fails halfway through. So here are a few tips to get the best results.

- Keep your install script small and easy to read, and add relevant comments.

- If you need temporary files, always use the `$TMPDIR` variable so you don't scatter files all over the system.

- If the user has to do any manual configuration — adjusting `PATH`, for example — put that in a clear message at the end of the script's execution.

- The binary you distribute should have as few dependencies as possible, ideally being fully static so it depends on nothing at all, not even libc. That makes a successful install and a trouble-free run far more likely.

- Configuration should live in the proper, expected places, such as `.config/appname` or `/etc/appname`, and be well documented.

- Ideally the install should not require superuser privileges to work — but then you have to ask the user where to place the binary and remind them to adjust their `PATH`. If you would rather have a superuser handle the install, you can drop the binary into `/usr/local/bin`, which should already be on the `PATH`. On one hand this spares the user from changing the system; on the other, they are placing a great deal of trust in your work.

- At the end of the install, remember to also explain how to uninstall your program.

Here is a very basic install script example that already detects the operating system and architecture.

```bash
#!/bin/bash

# Determine OS, architecture, and download URL
OS=$(uname)
ARCH=$(uname -m)
BASE_URL="https://example.com"
BIN_DIR="/usr/local/bin"
BIN_NAME="appname"

# Prepare the download URL
DOWNLOAD_URL="$BASE_URL/$OS/$ARCH/$BIN_NAME"

# Download and install
echo "Downloading $DOWNLOAD_URL to $BIN_DIR/$BIN_NAME"
curl -sSL $DOWNLOAD_URL -o $BIN_DIR/$BIN_NAME
if [ $? -ne 0 ]; then
    echo "Failed to install $BIN_NAME"
    exit 1
fi

chmod +x $BIN_DIR/$BIN_NAME
echo "Installed $BIN_NAME to $BIN_DIR/$BIN_NAME"

```

The takeaway is that this is not the ideal way to distribute software, but it is without a doubt one of the least troublesome — especially if your users have some technical background.
