---
title: "シリアルポートにアクセスするいくつかの方法"
emoji: "🔌"
type: "tech"
topics: ["go", "serial", "arduino", "development"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=4_TqPdyEQVM).

To me, one of the most interesting things is that the developers deliberately left out some features that screen has, such as telnet and serial port support. They did it because they believe in the [UNIX](https://en.wikipedia.org/wiki/Unix) philosophy of doing one thing and doing it well. In my opinion, they are absolutely right.

## A few ways to access the serial port

No matter which method you pick to open the serial port, remember that it is meant to be accessed by only one program at a time. For another program to use the same port, the first one has to close it. This happens a lot when you forget an [Arduino](https://www.arduino.cc) serial terminal session open.

### Through Arduino

The simplest option of all is Arduino's own serial terminal, although I find the Arduino IDE too basic.

### Through a serial terminal emulator

A serial emulator is a good choice if you need to guarantee VT102 support. My favorite is [Serial](https://www.decisivetactics.com/products/serial). The price is a bit steep, so it is only worth it if you use this kind of interface a lot.

### Using screen

Using screen to open a serial terminal is fairly common, mostly because screen is omnipresent across UNIX systems. The important thing is to remember to close the terminal properly so you don't leave the port "stuck". To do that, use the sequence *control + a* followed by *k* and *y*.

```bash
screen /dev/tty.usbmodemFA131
```

### Minicom

Minicom carries a touch of nostalgia for me — it was my main way of reaching a [BBS](https://en.wikipedia.org/wiki/Bulletin_board_system). What makes minicom interesting is how complete it is, including the old [zmodem](https://en.wikipedia.org/wiki/ZMODEM) and [xmodem](https://en.wikipedia.org/wiki/XMODEM) protocols, which are quite handy for downloading files over serial.

```bash
minicom -o console --color=on --attrib=on --device /dev/tty.usbmodemFA131 --baudrate 115200 -7
```

### Writing your own program

Any decent programming language can access the serial port without trouble. In the example below I used [Golang](https://golang.org), which is my favorite language.

```golang
package main

import (
    "fmt"
    "log"
    "os"
    "os/signal"

    "github.com/crgimenes/goconfig"
    "github.com/tarm/serial"
)

type config struct {
    Port string
    Baud int `cfgDefault:"115200"`
}

func main() {

    cfg := &config{}

    err := goconfig.Parse(cfg)
    if err != nil {
        log.Fatal(err)
    }

    if cfg.Port == "" {
        fmt.Println("Porta não definida.")
    }

    c := &serial.Config{Name: cfg.Port, Baud: cfg.Baud}
    s, err := serial.OpenPort(c)
    if err != nil {
        log.Fatal(err)
    }

    go func() {
        sc := make(chan os.Signal, 1)
        signal.Notify(sc, os.Interrupt)
        // espera pelo sinal
        <-sc

        fmt.Printf("\r\nliberando recursos...\r\n")
        err = s.Close()
        if err != nil {
            log.Fatal(err)
        }
        fmt.Printf("have a nice day!\r\n")
        os.Exit(0)
    }()

    for {
        buf := make([]byte, 128)
        n, err := s.Read(buf)
        if err != nil {
            log.Fatal(err)
        }
        fmt.Print(string(buf[:n]))
    }
}
```

### More Go examples

A few more Golang examples are in the [Go study group](https://github.com/crgimenes/grupo-estudos-golang) repository.
