---
title: "NATSとGoで作る超高速メッセージングシステム"
emoji: "⚡"
type: "tech"
topics: ["go", "nats", "messaging"]
published: true
---

Watch the video for this article [here](https://www.youtube.com/watch?v=NBi0r7QOJSs).

## Messaging with NATS

If you need several systems talking to each other with speed and simplicity, [NATS](https://nats.io) is a great help. One of its most interesting traits is its incredible speed, and its simple protocol is easy to implement, so NATS shows up everywhere from IoT — there are client libraries even for Arduino — to communication between much larger services. It is also widely used in mobile applications for the same reason: a simple, fast protocol. It is a very interesting alternative to [MQTT](https://mqtt.org), and it is implemented in Go. :D

## NATS client example

```golang
package main

import (
    "fmt"

    "github.com/nats-io/nats"
)

func main() {
    // Connect to a server
    nc, err := nats.Connect(nats.DefaultURL)
    if err != nil {
        fmt.Println(err)
        return
    }

    // Simple Publisher
    err = nc.Publish("teste", []byte("Hello World"))
    if err != nil {
        fmt.Println(err)
        return
    }

    // Simple Async Subscriber
    _, err = nc.Subscribe("teste", func(m *nats.Msg) {
        fmt.Printf("Received a message: %s\n", string(m.Data))
    })
    if err != nil {
        fmt.Println(err)
        return
    }

    halt()
}

func halt() {
    select {}
}
```

## Today's source code

- [Server](https://github.com/nats-io/gnatsd)
- [Client](https://github.com/nats-io/go-nats)
- [NATS website](https://nats.io)

- [Our study group repository](https://github.com/crgimenes/grupo-estudos-golang)

We meet every Thursday at 10:00 PM. To join, [enter the Golang channel on Slack](https://invite.slack.golangbridge.org) and look for #brazil
