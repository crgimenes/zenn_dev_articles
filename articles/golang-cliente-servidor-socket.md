---
title: "Goで永続的なソケットクライアントとサーバーを実装する"
emoji: "🔌"
type: "tech"
topics: ["go", "development"]
published: true
---

In the Go study group, a question came up about how to write a persistent client that reconnects to a socket server whenever the connection fails.

The main difficulty people seem to have is understanding the concept of a state machine. So we'll build a few examples of a persistent client, starting with a simple state machine, without goroutines or channels.

Before that, we'll create a small socket server for our client to connect to: the famous echo server.

## Socket Server

```go
package main

import (
    "bufio"
    "fmt"
    "io"
    "net"
)

func handler(conn net.Conn) {
    for {
        m, err := bufio.NewReader(conn).ReadString('\n')
        if err != nil {
            if err == io.EOF {
                fmt.Println("Connection closed")
                conn.Close()
                return
            }
            fmt.Println("Error reading from connection", err)
            return
        }
        _, err = conn.Write([]byte(m))
        if err != nil {
            fmt.Println("Error writing to connection")
            return
        }
        fmt.Printf("%v %q\n", conn.RemoteAddr(), m)
    }
}

func main() {
    fmt.Println("Listening on port 8080")

    ln, _ := net.Listen("tcp", ":8080")

    for {
        conn, _ := ln.Accept()
        fmt.Println("Connection accepted")
        go handler(conn)
    }
}
```

Our server has a simple job: listen on port 8080 for connections. When a connection arrives, it accepts it and calls the handler, which deals with the connection. Each handler runs in its own goroutine, allowing multiple simultaneous connections.

The handler reads data from the connection until it finds a newline (`\n`) and sends back to the client whatever it received. If an EOF occurs, the handler closes the connection and ends the goroutine.

The server just serves as a connection point for the client. Now let's see how to build a persistent client.

## Socket Client

```go
package main

import (
    "bufio"
    "fmt"
    "net"
    "os"
    "time"
)

func main() {

RECONNECT:
    for {
        fmt.Println("Connecting to server...")
        conn, err := net.Dial("tcp", ":8080")
        if err != nil {
            fmt.Println(err)
            time.Sleep(time.Second * 1)
            continue
        }

        fmt.Println("Connection accepted")
        for {
            var m string

            fmt.Print("> ")
            reader := bufio.NewReader(os.Stdin)
            m, err = reader.ReadString('\n')
            if err != nil {
                fmt.Println(err)
                continue RECONNECT
            }

            fmt.Printf("Sending: %q\n", m)
            _, err = conn.Write([]byte(m + "\n"))
            if err != nil {
                fmt.Println(err)
                continue RECONNECT
            }

            reader = bufio.NewReader(conn)
            m, err = reader.ReadString('\n')
            if err != nil {
                fmt.Println(err)
                continue RECONNECT
            }

            fmt.Printf("Received: %q\n", m)
        }
    }
}
```

This first client is simple, but persistent. It uses a single state machine, without goroutines or channels. Since it's a teaching example, there's some code repetition.

The client has two nested loops that act as a state machine. When the program starts, it's in the *disconnected* state.

It tries to connect to the server. If the connection fails, it waits one second and restarts the loop using `continue`.

### Connected Client

If the connection succeeds, the client enters the *connected* state and starts the main loop, switching to the *reading message from the terminal* state. In this state, it waits for the user to type a message and press enter.

Next, it moves to the *sending* state, where it sends the message to the server.

If everything goes well, it switches to the *reading message from the server* state, which reads the server's response and displays it on the screen.

### Persisting the Connection

If an error occurs in any of these states, the client logs the error and restarts the first loop, going back to the *disconnected* state. To do this, it uses `continue` with the `RECONNECT` label. Without the label, `continue` would restart only the inner loop.

This client is intentionally simple. Its state machine doesn't branch. It performs one task at a time: while reading from the terminal, it doesn't read from the server or try to reconnect, and so on.

## Source Code

Here is the source code for our server and client:

- [client](https://crg.eti.br/en/post/golang-cliente-servidor-socket/client/main.go)
- [server](https://crg.eti.br/en/post/golang-cliente-servidor-socket/server/main.go)

## Videos with Explanation

- [YouTube](https://www.youtube.com/watch?v=-VC3rx2ItLg)
- [Odysee](https://odysee.com/@crgimenes:7/socket_client_resiliente:1)

## Conclusion

I hope this tutorial cleared up any doubts about state machines and persistent clients. This version was deliberately simplified. Soon, I'll tackle this problem with more advanced features.
