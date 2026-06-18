---
title: "sftpdav: SSH経由でWebDAVを使いリモートディレクトリにアクセスする"
emoji: "🔌"
type: "tech"
topics: ["go", "webdav", "ssh", "sftp"]
published: true
---

Recently, I faced a challenge when trying to access files on a machine that only allows SSH connections. Opening additional ports or installing third-party extensions wasn’t feasible due to security and compatibility issues, especially on macOS.

That’s how the idea for **sftpdav** came about: a program that combines an SFTP client with a WebDAV server, allowing you to access a remote directory via SSH and mount it locally as a WebDAV share.

In practice, I’m using rsync to keep files synchronized between the local machine and the remote server. **sftpdav** is an interesting solution, though its performance isn’t great. Still, it was very rewarding to develop this solution and learn more about WebDAV and SSH.

You can find the **sftpdav** source code on GitHub: [sftpdav](https://github.com/crgimenes/sftpdav).

## Requirements

This need arose because:

- **Restricted Environment:** The server only allows SSH connections.
- **Security:** I can’t expose other ports on the server.
- **Compatibility:** `sshfs` doesn’t have native support on macOS, and I don’t want to install additional software.
- **File Lock:** The WebDAV server must support file locking, which I need for my use case (NFS also does, but it’s not as simple to configure).
- **user-space:** The solution should run entirely in user-space, without requiring admin privileges.

With **sftpdav**, you can leverage the robustness of SSH while offering the flexibility of WebDAV, which can be mounted on both Linux and macOS using simple user-space commands.

## How sftpdav Works

The program follows these steps:

1. **Read SSH Configuration:** Uses the `~/.ssh/config` file to get information like user, hostname, port, and identity file.
2. **SFTP Connection:** Establishes an SSH connection and creates an SFTP client for accessing the remote directory.
3. **Local WebDAV Server:** Starts a local WebDAV server with Go’s standard library, exposing the remote directory via SFTP so it can be mounted locally.
4. **Mount the Share:** With the WebDAV server running, you can mount the share using native system commands.

## Practical Examples

### Running sftpdav

To start the WebDAV server with SFTP access, run:

```bash
./sftpdav -port 8811 -host sshserver
```

Supported parameters:

- **-host:** Hostname as set in `~/.ssh/config`.
- **-port:** Local port for the WebDAV server (default: `8811`).
- **-remoteDir:** Remote directory to expose (default: `"."`).

### Mounting the Share

#### On Linux

Use the `mount` command with the `davfs` type:

```bash
sudo mount -t davfs http://localhost:8811 /mnt/sftp
```

#### On macOS

Use the `mount_webdav` command:

```bash
sudo mount_webdav http://localhost:8811 /mnt/sftp
```

#### To Unmount

On both systems, run:

```bash
sudo umount /mnt/sftp
```

### Cleaning Extended Attributes (macOS)

Since WebDAV doesn’t support extended attributes on macOS, files beginning with `._` may be created. To remove them, run:

```bash
dot_clean /path/to/directory
```

## The Original Version

The original version was simpler, consisting of just a few lines of code to create a WebDAV server. However, it needed to be run on the remote server:

```go
package main

import (
    "flag"
    "log"
    "net/http"
    "time"

    "golang.org/x/net/webdav"
)

func main() {
    localPortFlag := flag.String("port", "8811", "Local port for WebDAV server")
    dirFlag := flag.String("dir", "./", "Directory to share")
    flag.Parse()

    handler := &webdav.Handler{
        Prefix:     "/",
        FileSystem: webdav.Dir(*dirFlag),
        LockSystem: webdav.NewMemLS(),
    }

    s := &http.Server{
        Handler:        handler,
        Addr:           ":" + *localPortFlag,
        ReadTimeout:    15 * time.Second,
        WriteTimeout:   15 * time.Second,
        MaxHeaderBytes: 1 << 20,
    }

    if err := s.ListenAndServe(); err != nil {
        log.Fatal(err)
    }
}
```

Then, an SSH tunnel was created to access the remote server and locally mount the WebDAV share.

## Creating an SSH Tunnel

```bash
ssh -L 8811:localhost:8811 sshserver
```

In this example, your local machine’s port `8811` is forwarded to the remote server’s port `8811`, allowing local access to the WebDAV service. This simple approach worked well and is faster than the current version.

## Final Considerations

**sftpdav** is an experimental but working solution. Even though it has some latency, it achieves the goal of providing remote access via WebDAV using only the SSH port, maintaining a secure and straightforward environment.

This project demonstrated how different protocols can be combined to overcome limitations and build interesting, secure solutions.

If you have questions or suggestions, feel free to get in touch or open an *issue*.
