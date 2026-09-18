---
title: "GoでTCPソケットチャットを実装する（goroutineとチャネル）"
emoji: "💬"
type: "tech"
topics: ["go", "development"]
published: true
---

This is the fourth version of our socket client and server. In this version, I made some interesting improvements. We now have a complete chat system with useful commands and a few optimizations.

The goal of this version is to refine the system. I removed one of the write channels to send data directly, increasing efficiency. I also dropped the automatic reconnection to keep the code cleaner, since I added several new features.

## Server

Let's go through the changes on the server.

The *handler* that reads data from the client connection now uses a fixed-size *buffer*. This avoids waiting for an enter key, making reads more efficient.

```go
func handleReadConn(conn net.Conn, msgReadCh chan string, errCh chan error) {
    for {
        if msgReadCh == nil || conn == nil {
            return
        }
        buf := make([]byte, 1024)
        n, err := conn.Read(buf)
        if err != nil {
            errCh <- err
            return
        }
        m := string(buf[:n])
        msgReadCh <- m
    }
}
```

To send messages from the server to the clients, we replaced the use of channels in a *goroutine* with a single function. This simplifies sending, since reading data is kept separate, allowing concurrent reads and writes.

To avoid code duplication, the send-error handling lives in the *send* function, which returns a *boolean* indicating whether the send succeeded.

```go
func send(conn net.Conn, msg string) bool {
    _, err := conn.Write([]byte(msg))
    if err != nil {
        if err == io.EOF {
            fmt.Printf("%v Connection closed\n", conn.RemoteAddr())
            return false
        }
        fmt.Printf("%v Error: %v\n", conn.RemoteAddr(), err)
        return false
    }
    return true
}
```

I also made several changes to the connection *handler*. It now interprets basic commands inspired by the [IRC](https://en.wikipedia.org/wiki/Internet_Relay_Chat) protocol. For example, `/nick` changes the user's nickname and `/who` lists the connected users.

## Client

On the client, the function that reads data from the connection also uses a fixed-size *buffer*. This makes reads faster, just like on the server.

```go
func readConn(conn net.Conn) {
    for {
        buf := make([]byte, 1024)
        n, err := conn.Read(buf)
        if err != nil {
            errorChan <- err
            return
        }
        m := string(buf[:n])
        output <- m
    }
}
```

As on the server, the client uses a *send* function to send data. If an error occurs, we log it and close the connection.

```go
func send(conn net.Conn, m string) {
    if conn == nil {
        return
    }
    _, err := conn.Write([]byte(m))
    if err != nil {
        fmt.Println(err)
        conn.Close()
        conn = nil
    }
}
```

On the client, we have important commands such as `/connect`, which establishes a connection to the server, and `/help`, which shows the available commands. If the client is connected, the `/help` command also calls the server's `/help`, producing a single help list.

## Source Code

Here is the source code for our server and client.

- [client](https://crg.eti.br/en/post/golang-cliente-servidor-socket-chat/client/main.go)
- [server](https://crg.eti.br/en/post/golang-cliente-servidor-socket-chat/server/main.go)

## Videos with Explanation

- [YouTube](https://youtu.be/VWhUXamJyyk)
- [Odysee](https://odysee.com/@crgimenes:7/socket-chat:e)

## Conclusion

With these changes, we added a lot of functionality. We now have a usable chat system that is faster and more reliable. The commands between client and server illustrate good communication and a simple protocol. The same features could be implemented with more sophisticated protocols, such as [gRPC](https://grpc.io) or [JSON](https://www.json.org/json-en.html).
