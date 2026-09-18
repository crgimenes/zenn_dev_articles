---
title: "GoのソケットサーバーにPing/Pongによる死活監視を実装する"
emoji: "🏓"
type: "tech"
topics: ["go", "socket", "network", "goroutine"]
published: true
---

Continuing the [conversation about a resilient client and server](https://crg.eti.br/en/post/golang-cliente-servidor-socket-com-canais-e-goroutines/), it's time to improve the server and add the sending of *ping* or *keep alive* messages.

We also made improvements to the server. Now, just like the client, it uses goroutines and channels.

## Server

### Reading from the Connection

In this version, the server uses one goroutine to write and another to read the data from the client connection. When using goroutines and channels this way, it's essential to make sure the goroutines are properly terminated.

Otherwise, you can end up with a goroutine *leak*, that is, goroutines that aren't doing any work but keep taking up memory.

```go
func handleReadConn(conn net.Conn, msgReadCh chan string, errCh chan error) {
    for {
        if msgReadCh == nil {
            return
        }
        m, err := bufio.NewReader(conn).ReadString('\n')
        if err != nil {
            errCh <- err
            return
        }
        msgReadCh <- m
    }
}
```

### Writing to the Connection

I like the idea of having a goroutine responsible for sending data to the client, reading from a channel. Besides the modularity, this makes the operation asynchronous and allows a buffer to be used on the channel if needed.

```go
func handleWriteConn(conn net.Conn, msgWriteCh chan string, errCh chan error) {
    for {
        m, ok := <-msgWriteCh
        if !ok {
            return
        }
        _, err := conn.Write([]byte(m))
        if err != nil {
            errCh <- err
            return
        }
    }
}
```

### Controlling the Channels

A common pattern is to use an infinite loop with `select` to handle the channels. This is the heart of our server, needed to control the program's states, such as reading, receiving, and error handling.

In addition, the server now has the `pingInterval` and `maxPingInterval` variables, which control how often pings are sent and the maximum time before closing the connection.

```go
func handler(conn net.Conn) {
    pingInterval := time.Second * 5
    maxPingInterval := time.Second * 15
    msgReadCh := make(chan string)
    msgWriteCh := make(chan string)
    errCh := make(chan error)
    lastMsgTime := time.Now()

    defer func() {
        close(msgReadCh)
        close(msgWriteCh)
        close(errCh)
        conn.Close()
    }()

    go handleReadConn(conn, msgReadCh, errCh)
    go handleWriteConn(conn, msgWriteCh, errCh)

    for {
        select {
        case <-time.After(pingInterval):
            if time.Since(lastMsgTime) > pingInterval {
                fmt.Println("Enviando ping")
                msgWriteCh <- "ping\n"
            }
            if time.Since(lastMsgTime) > maxPingInterval {
                fmt.Println("Conexão inativa, encerrando")
                return
            }
        case msg := <-msgReadCh:
            lastMsgTime = time.Now()
            if msg == "pong\n" {
                fmt.Println("Pong recebido")
                continue
            }
            fmt.Printf("%v %q\n", conn.RemoteAddr(), msg)
            msgWriteCh <- msg
        case err := <-errCh:
            if err == io.EOF {
                fmt.Printf("%v Conexão encerrada\n", conn.RemoteAddr())
                return
            }
            fmt.Println("Erro ao ler da conexão", err)
            return
        }
    }
}
```

## Client

The client stayed practically the same; we only added the response to the *ping*.

```go
case m := <-output:
    if m == "ping\n" {
        fmt.Println("Ping recebido")
        fmt.Println("Enviando pong")
        conn.Write([]byte("pong\n"))
        continue
    }
```

## Source Code

Here are the source codes for our server and client.

- [Client](https://crg.eti.br/en/post/golang-cliente-servidor-socket-ping-pong/client/main.go)
- [Server](https://crg.eti.br/en/post/golang-cliente-servidor-socket-ping-pong/server/main.go)

### Videos with an Explanation

- [YouTube](https://youtu.be/YvyP6Bd9InY)
- [Odysee](https://odysee.com/@crgimenes:7/cliente-golang-ping-pong:2)

## Conclusion

With ping/pong, we make sure the connection is always alive. This detail avoids unnecessary costs with clients that keep the connection open without sending or receiving data. If an error occurs and a client stops responding, the server will close the connection and free up the resources.
