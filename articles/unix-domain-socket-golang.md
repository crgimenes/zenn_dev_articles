---
title: "GoでUnixドメインソケットを使ったプロセス間通信"
emoji: "🔌"
type: "tech"
topics: ["go", "unix", "socket", "ipc"]
published: true
---

- *Unix Domain Sockets* or *[IPC](https://en.wikipedia.org/wiki/Inter-process_communication) Sockets*

*Unix Domain Sockets* are a practical and secure way to exchange information between processes. This form of *IPC* (Inter-process communication) uses a file as the address instead of an IP and a port, as network communication does.

Keep in mind that the server manages the file. If the file does not exist, the server creates it automatically. If the file already exists, you get an error such as "bind: address already in use", meaning the server cannot reuse the existing file. So it is good practice to shut the server down gracefully, closing and deleting the file before the server exits. Depending on the system, it may also be worth checking whether the file exists and deleting it before starting the server.

Convenient as it is, using a file as the address prevents exchanging information between different machines. The kernel handles the communication. The file is just a namespace. No byte is actually written to it, and it takes up zero disk space. All communication happens in RAM and is managed by the kernel.

## Server

The connection between client and server is similar to a TCP/IP connection. The server listens on the `namespace` given by the file and waits for connections, as if it were listening on a TCP port. When a connection arrives, we use the `Accept` function from the net package and hand it off to a `goroutine` with the connection handler.

```golang
package main

import (
    "fmt"
    "io"
    "net"
)

func main() {
    l, err := net.Listen("unix", "/tmp/echo.sock")
    if err != nil {
        panic(err)
    }

    for {
        f, err := l.Accept()
        if err != nil {
            panic(err)
        }

        go func(c io.ReadWriter) {
            for {
                buf := make([]byte, 512)
                n, err := c.Read(buf)
                if err != nil {
                    return
                }

                fmt.Printf("echo: %s\r\n", buf[:n])
                _, err = c.Write(buf[:n])
                if err != nil {
                    panic(err)
                }
            }
        }(f)
    }
}
```
[source code](https://crg.eti.br/en/post/unix-domain-socket-golang/server/main.go)

## Client

In the client example, we create two processing paths. One is the goroutine that reads everything arriving over the connection. The other is the main function, which sends data to the server in a loop. It does not have to work this way. Depending on how your system works, you can send a single message to the server and start a goroutine just to handle the timeout. The only thing to watch out for is that these functions block processing.

```golang
package main

import (
    "fmt"
    "io"
    "net"
    "time"
)

func main() {
    f, err := net.Dial("unix", "/tmp/echo.sock")
    if err != nil {
        panic(err)
    }
    defer f.Close()

    go func(r io.Reader) {
        buf := make([]byte, 1024)
        for {
            n, errf := r.Read(buf)
            if errf != nil {
                panic(err)
            }
            fmt.Printf("recebido: %s\r\n", buf[:n])
        }
    }(f)

    for {
        data := []byte("olá mundo")
        fmt.Printf("enviando: %s\r\n", data)
        _, err = f.Write([]byte("olá mundo"))
        if err != nil {
            panic(err)
        }

        time.Sleep(time.Duration(400) * time.Millisecond)
    }
}
```
[source code](https://crg.eti.br/en/post/unix-domain-socket-golang/client/main.go)

## Server using netcat

For testing, we can use [netcat](https://en.wikipedia.org/wiki/Netcat).

```bash
nc -lU /tmp/echo.sock && rm /tmp/echo.sock
```

## Client using netcat

```bash
nc -U /tmp/echo.sock
```

## Conclusion

*Unix Domain Sockets* are quite interesting: communication happens in RAM without taking up disk space, there is no need to configure an IP and a port, the communication is not exposed to the network, and file permissions apply, which makes the process more secure. The only downside is that communication is limited to processes on the same machine.
