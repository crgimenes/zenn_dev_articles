---
title: "Goのソケットクライアント／サーバーでシグナルを扱う"
emoji: "🛑"
type: "tech"
topics: ["go", "socket", "tcp", "signal"]
published: true
---

Continuing our series on client/server programming, we will add a new channel to the [previous example](https://crg.eti.br/en/post/golang-cliente-servidor-socket-ping-pong/). This channel handles signals sent by the operating system.

The operating system sends signals to programs to manage processes. For example, when you press *Ctrl+C*, the OS sends the SIGINT signal, telling the program that the user wants to interrupt it.

By default, the program just closes. But we can intercept the signal and act accordingly. Here we will simply terminate the program. In real systems, this is where you save information before exiting, stop other processes, close connections and files, and so on. This is known as *graceful shutdown*.

## Server

On the server, we create a channel and tell the system to send signals through it. We also spin up a goroutine to watch the channel.

```go
sigs := make(chan os.Signal, 1)
signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

go func() {
    <-sigs
    fmt.Println("\nShutdown server...")
    os.Exit(0)
}()
```

## Client

On the client, the approach is different. We do not need a goroutine. Since we are already using a *select* to handle channels, we just add the new channel as another case. It gets handled like any of the others.

```go
sigs := make(chan os.Signal, 1)
signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

for {
    select {
    case <-sigs:
        fmt.Println("\nDisconnecting...")
        conn.Close()
        os.Exit(0)
        ...
```

## Source code

Check out the source code for the server and client:

- [Client](https://crg.eti.br/en/post/golang-cliente-servidor-socket-signals/client/main.go)
- [Server](https://crg.eti.br/en/post/golang-cliente-servidor-socket-signals/server/main.go)

## Video walkthrough

- [YouTube](https://youtu.be/-N0fcSSM_90)
- [Odysee](https://odysee.com/@crgimenes:7/sinais:4)

## Conclusion

Adding signal handling was a small change, but an essential one. When a program shuts down, you want it to be in a consistent state. If it writes to a database, for instance, it is worth waiting for open transactions to finish before exiting.
