---
title: "Goでシグナルを扱う"
emoji: "🚦"
type: "tech"
topics: ["go", "unix", "development"]
published: true
---

Handling signals is good practice. It lets you shut your program down gracefully, releasing resources and closing databases, instead of just terminating. Handling operating system signals with Golang is simple, because the system delivers the signal to a channel. All you have to do is listen to that channel.

First, we create a channel:

```golang
sc := make(chan os.Signal, 1)
```

Next, we say which signal we care about. In this case ^C, that is, [SIGINT](https://en.wikipedia.org/wiki/Unix_signal#SIGINT).

```golang
signal.Notify(sc, os.Interrupt)
```

You can register more than one signal. Just add more arguments, for example: `signal.Notify(sc, os.Interrupt, syscall.SIGTERM)`.

The signals I find most interesting to handle are:

- `os.Interrupt`: same as `syscall.SIGINT`, represents the ^C signal
- `syscall.SIGTERM`: termination signal, usually sent by the `kill` command
- `syscall.SIGWINCH`: window resize signal (when the terminal is resized)
- `syscall.SIGUSR1`: user signal 1 (you can create your own signals)
- `syscall.SIGUSR2`: user signal 2

Then you just wait for the channel to receive a signal.

```golang
<-sc
```

You need to handle the signals in a goroutine.

## Example

```golang
go func() {
    sc := make(chan os.Signal, 1)
    signal.Notify(
        sc,
        os.Interrupt,
        syscall.SIGTERM,
        syscall.SIGWINCH,
        syscall.SIGUSR1,
        syscall.SIGUSR2)
    for {
        s := <-sc
        switch s {
        case os.Interrupt:
            fmt.Printf("\r\nYou pressed ^C\r\n")
            os.Exit(0)
        case syscall.SIGTERM:
            fmt.Printf("\r\nYou sent SIGTERM\r\n")
            os.Exit(0)
        case syscall.SIGUSR1:
            fmt.Printf("\r\nYou sent SIGUSR1\r\n")
        case syscall.SIGUSR2:
            fmt.Printf("\r\nYou sent SIGUSR2\r\n")
        case syscall.SIGWINCH:
            fmt.Printf("\r\nThe window was resized\r\n")
        }
    }
}()

c := make(chan struct{})
<-c
```
[full source code](https://crg.eti.br/en/post/tratando-sinais-com-go/main.go)

`SIGUSR1` and `SIGUSR2` are user signals. You can define your own meaning for them, for example to request information or to change the program's behavior.

To send user signals, use the `kill` command with the `-USR1` or `-USR2` option.

```bash
kill -USR1 <pid>
```

The `SIGWINCH` signal is sent when the terminal window is resized. You can use it to capture the new dimensions and resize your program's window.

`SIGTERM` and `SIGINT` are termination signals. The first is sent by the `kill` command, and the second is sent when the user presses ^C. You can use them to shut the program down gracefully, closing connections and releasing resources.

Video with the explanation:

@[youtube](MURcTH0YSFA)
