---
title: "Goでソケットクライアント・サーバーを実装する（goroutineとチャネル）"
emoji: "🔌"
type: "tech"
topics: ["go", "development"]
published: true
---

Continuing the [example about a persistent socket client in Golang](https://crg.eti.br/en/post/golang-cliente-servidor-socket/), I made a few changes to the source code to show how to improve our code and make it asynchronous. To do that, we'll use goroutines and channels.

## Goroutines and Channels

Goroutines and channels are advanced features of the Go language. Goroutines are lightweight threads managed by the language runtime itself, and channels allow communication between goroutines.

In our case, we'll use channels for communication between the goroutines in our program.

These two features are a bit advanced, so I first showed how to build our small socket client without them.

In fact, it's good practice to solve the problem in the simplest way possible and only add goroutines and channels if they're really needed. They're easy to use, but they come at a cost: the program becomes harder to debug.

## Analyzing the source code

### Reading from standard input

One improvement I made was to split the code into small functions, which makes it easier to read.

First, the function responsible for reading user input.

```go
func readStdin() {
    for {
        reader := bufio.NewReader(os.Stdin)
        m, err := reader.ReadString('\n')
        if err != nil {
            panic(err)
        }
        input <- m
    }
}
```

This function enters an infinite loop reading user input. When the user presses *enter*, the function sends the *string* to the *input* channel. If an error occurs while reading *stdin*, the program terminates with a *panic*.

### Reading from the network

The function that reads from the network connection is very similar to the one that reads user input. The only differences are the source of the read, which channel the write goes to, and that, in case of an error, we send the error to the *errorChan* channel instead of terminating the program with a *panic*.

```go
func readConn(conn net.Conn) {
    for {
        reader := bufio.NewReader(conn)
        m, err := reader.ReadString('\n')
        if err != nil {
            errorChan <- err
            return
        }
        output <- m
    }
}
```

### Managing the connection

Finally, we have a function to manage the connection. It loops trying to connect to the server and, once the connection is established, returns the connection to be used by the other parts of the system.

It's practically the same routine we used in the previous program, but now split into a function.

```go
func connect() net.Conn {
    var (
        conn net.Conn
        err  error
    )
    for {
        fmt.Println("Connecting to server...")
        conn, err = net.Dial("tcp", ":8080")
        if err == nil {
            break
        }
        fmt.Println(err)
        time.Sleep(time.Second * 1)
    }
    fmt.Println("Connection accepted")
    return conn
}
```

### Managing the channels

In the *main* function, the remaining task is to start the goroutines and manage the channels. For that, we use the *select* keyword, which is similar to *switch case*. However, *select* waits on the return of multiple channels.

```go
func main() {

    go readStdin()

RECONNECT:
    for {
        conn := connect()

        go readConn(conn)

        for {
            select {
            case m := <-output:
                fmt.Printf("Received: %q\n", m)

            case m := <-input:
                fmt.Printf("Sending: %q\n", m)
                _, err := conn.Write([]byte(m + "\n"))
                if err != nil {
                    fmt.Println(err)
                    conn.Close()
                    continue RECONNECT
                }
            case err := <-errorChan:
                fmt.Println("Error:", err)
                conn.Close()
                continue RECONNECT
            }
        }
    }
}
```

Basically, we loop waiting for messages from several channels and handle whatever arrives on each channel with the appropriate routine.

## Source code

Here is the source code for our server and client.

- [Client](https://crg.eti.br/en/post/golang-cliente-servidor-socket-com-canais-e-goroutines/client/main.go)
- [Server](https://crg.eti.br/en/post/golang-cliente-servidor-socket-com-canais-e-goroutines/server/main.go)

## Videos with explanation

- [YouTube](https://youtu.be/Qeun7ZFzw5s)
- [Odysee](https://odysee.com/@crgimenes:7/socket_client_resiliente-canais-goroutines:f)

## Conclusion

Now, split into functions and using goroutines and channels, our client is much more responsive. It doesn't do just one task at a time; it can receive information from the network or from the user and transmit, all asynchronously.

In the next version, the most obvious improvement will be to add a ping/keep-alive routine to make sure the connection is working, even when the program is neither receiving nor transmitting anything.
